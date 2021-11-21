#!/bin/bash


readonly DEVICE=/dev/vda
readonly PART=${DEVICE}1


dd if=/dev/zero of=${DEVICE} bs=1M count=1

parted -s ${DEVICE} mklabel msdos
parted -s ${DEVICE} mkpart primary 1 100%
parted -s ${DEVICE} set 1 lvm on
parted -s ${DEVICE} set 1 boot on
partprobe ${DEVICE}
sleep 2

pvcreate $PART
vgcreate k3os $PART
lvcreate -n root -l 100%FREE k3os

mkfs.ext4 -F -L K3OS_STATE /dev/k3os/root

n