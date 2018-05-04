#!/usr/bin/env bash
#

function error () {
	echo $*
	exit -1
}

create_partition_parted(){
  local dev="$1"
  parted $dev --script mklabel msdos mkpart primary 0% 100% set 1 lvm on
}

# First check that the data volume is attached
[[ $(lsblk | grep -c vdb) -eq 1 ]] || error "Data volume does not appear to be attached to $(hostname)"

# Does the volume group exist on the data volume
if [ $(lsblk | grep -c vdb1) -eq 0 ]; then

	create_partition_parted /dev/vdb
	pvcreate /dev/vdb1
	vgcreate data /dev/vdb1
	lvcreate -y -l 90% -n var data
	mkfs -t xfs /dev/data/var

	cat > /etc/sysconfig/docker-storage-setup <<-EOF
DEVS=/dev/vdb
VG=docker-vg
EOF

	systemctl stop docker
	rm -rf /var/lib/docker/*
	lvremove -y docker-pool
	docker-storage-setup
	systemctl start docker
	systemctl status docker.service
	vgdisplay
	fdisk -l
	lsblk
fi
