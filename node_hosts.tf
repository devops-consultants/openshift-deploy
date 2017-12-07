data "template_file" "node_config" {
  template = "${file("files/init.tpl")}"
  count = "${var.openshift_nodes}"

  vars {
    hostname = "${format("node%02d", count.index + 1)}"
    fqdn     = "${format("node%02d", count.index + 1)}.${var.domain_name}"
  }
}

resource "openstack_blockstorage_volume_v2" "node" {
  region      = "RegionOne"
  name        = "${format("node%02d", count.index + 1)}"
  image_id    = "${openstack_images_image_v2.atomic.id}"
  description = "OpenShift Node Volume"
  size        = 10
  count       = "${var.openshift_nodes}"
}

resource "openstack_blockstorage_volume_v2" "node_data" {
  region      = "RegionOne"
  name        = "${format("node%02d_data", count.index + 1)}"
  description = "OpenShift Node data"
  size        = 20
  count       = "${var.openshift_nodes}"
}

resource "openstack_compute_instance_v2" "node" {
  name        = "${format("node%02d", count.index + 1)}.${var.domain_name}"
  flavor_name = "${var.node_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  user_data = "${element(data.template_file.node_config.*.rendered, count.index)}"
  count = "${var.openshift_nodes}"

  block_device {
    uuid                  = "${element(openstack_blockstorage_volume_v2.node.*.id, count.index)}"
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }

  network {
    name = "${var.network_name}"
  }

  security_groups = [
	"${var.local_ssh_sec_group}",
	"${var.local_consul_sec_group}",
	"${openstack_networking_secgroup_v2.openshift.name}"
  ]

  connection {
    user = "centos"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm-ostree install unzip",
      "sudo systemctl reboot"
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.setup_consul.rendered}"
    destination = "/tmp/install_consul.sh"
  }

  provisioner "file" {
    source      = "files/attach_data_vol.sh"
    destination = "/tmp/attach_data_vol.sh"
  }

  provisioner "remote-exec" {
    inline = [
	"sudo chmod a+x /tmp/install_consul.sh",
	"sudo /tmp/install_consul.sh"
    ]
  }
}

resource "openstack_compute_volume_attach_v2" "node_data" {
  instance_id = "${element(openstack_compute_instance_v2.node.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.node_data.*.id, count.index)}"
  count       = "${var.openshift_nodes}"
}

resource "null_resource" "node" {
  triggers {
    instance_id = "${element(openstack_compute_instance_v2.node.*.id, count.index)}"
    vol_attachment = "${element(openstack_compute_volume_attach_v2.node_data.*.id, count.index)}"
  }
  count = "${var.openshift_nodes}"

  connection {
    host = "${element(openstack_compute_instance_v2.node.*.access_ip_v4, count.index)}"
    user = "centos"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo lsblk",
      "sudo chmod a+x /tmp/attach_data_vol.sh",
      "sudo /tmp/attach_data_vol.sh"
    ]
  }
}
