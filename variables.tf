variable "OS_USERNAME" {}
variable "OS_TENANT_NAME" {}
variable "OS_PASSWORD" {}
variable "OS_AUTH_URL" {}

variable "public_key_file" { default = "~/.ssh/id_rsa.pub" }
variable "private_key_file" { default = "~/.ssh/id_rsa" }

variable "IMAGE_NAME" { default = "CentOS 7" }
variable "master_type" { default = "m1.medium" }
variable "node_type" { default = "m1.large" }

variable "openshift_masters" { default = "1" }
variable "openshift_nodes" { default = "2" }

variable "local_ssh_sec_group" {}
variable "network_name" { default = "OpenShift" }
variable "domain_name" { default = "example.com" }

variable "consul_download_url" { default = "https://releases.hashicorp.com/consul/1.0.1/consul_1.0.1_linux_amd64.zip" }
variable "consul_join_ip" {}
variable "consul_datacenter" {}
variable "consul_encrypt_key" {}