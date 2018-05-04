data "template_file" "master_config" {
  template = "${file("files/init.tpl")}"
  count = "${var.openshift_masters}"

  vars {
    hostname = "${format("master%02d", count.index + 1)}"
    fqdn     = "${format("master%02d", count.index + 1)}.${var.domain_name}"
    root_size = "40G"
  }
}

resource "openstack_blockstorage_volume_v2" "master" {
  region      = "RegionOne"
  name        = "${format("master%02d", count.index + 1)}"
  image_id    = "${data.openstack_images_image_v2.atomic.id}"
  description = "OpenShift Master volume"
  size        = 50
  count       = "${var.openshift_masters}"
  timeouts {
    create = "60m"
    delete = "2h"
  }
}

#resource "openstack_blockstorage_volume_v2" "master_data" {
#  region      = "RegionOne"
#  name        = "${format("master%02d_data", count.index + 1)}"
#  description = "OpenShift Master data"
#  size        = 50
#  count       = "${var.openshift_masters}"
#}

#resource "openstack_compute_volume_attach_v2" "master_data" {
#  instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
#  volume_id = "${element(openstack_blockstorage_volume_v2.master_data.*.id, count.index)}"
#  count       = "${var.openshift_masters}"
#}

resource "openstack_compute_instance_v2" "master" {
  name        = "${format("master%02d", count.index + 1)}.${var.domain_name}"
  flavor_name = "${var.master_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  user_data = "${element(data.template_file.master_config.*.rendered, count.index)}"
  count = "${var.openshift_masters}"

  block_device {
    uuid                  = "${element(openstack_blockstorage_volume_v2.master.*.id, count.index)}"
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

#  provisioner "file" {
#    source      = "files/attach_data_vol.sh"
#    destination = "/tmp/attach_data_vol.sh"
#  }

  provisioner "remote-exec" {
    inline = [
	"sudo chmod a+x /tmp/install_consul.sh",
	"sudo /tmp/install_consul.sh"
    ]
  }
}

#resource "null_resource" "master" {
#  triggers {
#    instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
#    vol_attachment = "${element(openstack_compute_volume_attach_v2.master_data.*.id, count.index)}"
#  }
#  count = "${var.openshift_masters}"
#
#  connection {
#    host = "${element(openstack_compute_instance_v2.master.*.access_ip_v4, count.index)}"
#    user = "centos"
#    private_key = "${file(var.private_key_file)}"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#	"sudo lsblk",
#	"sudo chmod a+x /tmp/attach_data_vol.sh",
#	"sudo /tmp/attach_data_vol.sh"
#    ]
#  }
#}
