resource "openstack_images_image_v2" "atomic" {
  name   = "Atomic Host 7"
  image_source_url = "http://cloud.centos.org/centos/7/atomic/images/CentOS-Atomic-Host-7-GenericCloud.qcow2"
  container_format = "bare"
  disk_format = "qcow2"
  visibility = "public"
}
