#!/usr/bin/env bash
#

function error () {
	echo $*
	exit -1
}

# First check that the data volume is attached
[[ $(lsblk | grep -c vdb) -eq 1 ]] || error "Data volume does not appear to be attached to $(hostname)"

# Does the volume group exist on the data volume
if [ $(lsblk | grep -c vdb1) -eq 0 ]; then
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
