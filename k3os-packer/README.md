
### Hetzner
```
HCLOUD_TOKEN=<TOKEN> packer build -only=hcloud.* ./template.pkr.hcl 
```

### Vagrant
#### With cloud
```
VAGRANT_CLOUD_TOKEN=<TOKEN> packer build -only=virtualbox-iso.vagrant ./template.pkr.hcl
```
#### Without cloud
```
packer build -only=virtualbox-iso.vagrant -except=vagrant-cloud ./template.pkr.hcl
```

### QEMU
```
ISO_CHECKSUM=bc138f8d15a38bccaba56fcf6b4e4aae6e0f30beb5b2535091b39a8dba245763  ISO_VERSION=v0.20.11-k3s2r1 /usr/bin/packer build -timestamp-ui -force -only=qemu.libvirt ./template.pkr.hcl
```
