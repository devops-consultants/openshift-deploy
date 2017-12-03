data "template_file" "node_config" {
  template = "${file("files/init.tpl")}"
  count = "${var.openshift_nodes}"

  vars {
    hostname = "${format("node%02d", count.index + 1)}"
    fqdn     = "${format("node%02d", count.index + 1)}.${var.domain_name}"
  }
}

resource "openstack_compute_instance_v2" "node" {
  name        = "${format("node%02d", count.index + 1)}.${var.domain_name}"
  image_id  = "${openstack_images_image_v2.atomic.id}"
  flavor_name = "${var.node_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  user_data = "${element(data.template_file.node_config.*.rendered, count.index)}"
  count = "${var.openshift_nodes}"
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
    content = "${data.template_file.setup_consul.rendered}"
    destination = "/tmp/install_consul.sh"
  }

  provisioner "remote-exec" {
    inline = [
	"sudo chmod a+x /tmp/install_consul.sh",
	"sudo /tmp/install_consul.sh"
    ]
  }
}

