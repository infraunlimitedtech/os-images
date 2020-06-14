#!/usr/bin/env bash

set -x

target=$1
pwd
cat <<EOF >> $target
%post --log /root/vagrant-install.log

useradd vagrant -G wheel
echo vagrant:vagrant | chpasswd

echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

%end
EOF
