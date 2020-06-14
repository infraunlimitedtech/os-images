# Create iso
sudo bash ./mk_iso.sh create --var-file ./centos-8-iso/vars.conf ./centos-8-tmp_dir

# Packer
md5sum ./test.iso
packer build -var 'headless=false' -var 'iso_url=file:///home/spigell/projects/infra/os-images/output/centos-81-infra-200613.iso' -var 'iso_checksum=332937bf8ba3595cd1f33cff89b723ed' ./template.json


vagrant up
vagrant destroy --force
