
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
