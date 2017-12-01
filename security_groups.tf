resource "openstack_networking_secgroup_v2" "openshift" {
  name = "Local OpenShift Access"
  description = "Allow local access to OpenShift VMs"
}

resource "openstack_networking_secgroup_rule_v2" "openshift_1" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  port_range_min = 1
  port_range_max = 255
  remote_group_id = "${openstack_networking_secgroup_v2.openshift.id}"
  security_group_id = "${openstack_networking_secgroup_v2.openshift.id}"
}

resource "openstack_networking_secgroup_rule_v2" "openshift_2" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  remote_group_id = "${openstack_networking_secgroup_v2.openshift.id}"
  security_group_id = "${openstack_networking_secgroup_v2.openshift.id}"
}
