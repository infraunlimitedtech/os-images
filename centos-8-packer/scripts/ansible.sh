#!/bin/bash -eux

# Install Ansible.
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
dnf -y install ansible
