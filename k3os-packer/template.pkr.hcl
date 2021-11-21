variable "description" {
  type    = string
  default = "k3OS with disabled k3s on startup"
}

variable "password" {
  type    = string
  default = "rancher"
}

variable "iso_version" {
  type    = string
  default = "${env("ISO_VERSION")}"
}

variable "iso_checksum" {
  type    = string
  default = "${env("ISO_CHECKSUM")}"
}

variable "qemu_ssh_private_key" {
  type    = string
  default = "tmp/id_rsa"
}

locals {
  iso_url = "https://github.com/rancher/k3os/releases/download/${var.iso_version}/k3os-amd64.iso"
  vagrant_box_version = regex("\\d+.\\d+.\\d+", var.iso_version)
  boot_command_default = [
    "rancher", "<enter>",
    "export K3OS_INSTALL_POWER_OFF=true", "<enter>",
    "sudo -E k3os install", "<enter>",
    "1", "<enter>", "y", "<enter>",
    "http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.yml", "<enter>", "y", "<enter>"
  ]
  boot_command_lvm = [
    "rancher", "<enter>",
    "export K3OS_INSTALL_POWER_OFF=true", "<enter>",
    "export INTERACTIVE=true", "<enter>",
    "export K3OS_INSTALL_NO_FORMAT=true", "<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/create-disk-layout.sh | sudo bash", "<enter>",
    "<wait5m>",
    "sudo -E k3os install", "<enter>",
    "1", "<enter>", "y", "<enter>",
    "http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.yml", "<enter>", "y", "<enter>"
  ]
}

variable "vagrant_cloud_token" {
  type    = string
  default = "${env("VAGRANT_CLOUD_TOKEN")}"
}



source "hcloud" "main" {
  image       = "ubuntu-20.04"
  location    = "hel1"
  server_type = "cx11"
  snapshot_labels = {
    name    = "k3OS"
    version = "${var.iso_version}"
  }
  snapshot_name = "k3os-${var.iso_version}-amd64"
  ssh_username  = "root"
}

source "virtualbox-iso" "vagrant" {
  communicator         = "none"
  guest_additions_mode = "disable"
  guest_os_type        = "Linux_64"
  iso_url              = local.iso_url
  iso_checksum         = "sha256:${var.iso_checksum}"
  headless             = "true"
  vrdp_bind_address    = "0.0.0.0"
  boot_command         = local.boot_command_default
  boot_wait            = "40s"
  disk_size            = "8000"
  export_opts          = ["--manifest", "--vsys", "0", "--description", "${var.description}", "--version", "${local.vagrant_box_version}"]
  format               = "ova"
  http_directory       = "vagrant-virtualbox"
  disable_shutdown     = "true"
  virtualbox_version_file = ""
}

source "qemu" "libvirt" {
  communicator         = "none"
  iso_url              = local.iso_url
  iso_checksum         = "sha256:${var.iso_checksum}"
  qemu_binary          = "/usr/libexec/qemu-kvm"
  headless             = "true"
  vnc_bind_address     = "0.0.0.0"
  boot_command         = local.boot_command_default
  boot_wait            = "50s"
  disk_size            = "20000"
  # Should change to raw later
  format               = "qcow2"
  http_directory       = "libvirt-qemu"
  shutdown_timeout     = "30m"
}



build {
  # Do not build Hetzner right now
  #sources = ["source.hcloud.main", "source.virtualbox-iso.vagrant", "source.qemu.libvirt"]

  sources = ["source.virtualbox-iso.vagrant", "source.qemu.libvirt"]


  provisioner "file" {
    only        = [ "hcloud.main" ]
    destination = "/tmp/config.yaml"
    source      = "hetzner/config.yaml"
  }

  provisioner "shell" {
    only        = [ "hcloud.main" ]
    inline = [ "wget https://raw.githubusercontent.com/rancher/k3os/master/install.sh" ]
  }

  provisioner "shell" {
    only        = [ "hcloud.main" ]
    inline = ["sudo apt-get update -y", "sudo apt-get install -y dosfstools parted", "sudo bash -x install.sh --takeover --poweroff --debug --tty ttyS0 --config /tmp/config.yaml --no-format $(findmnt / -o SOURCE -n) \"${local.iso_url}\""]
  }

  provisioner "shell" {
    only        = [ "hcloud.main" ]
    inline      = ["set -x; sudo systemd-run --on-active=3 --timer-property=AccuracySec=100ms sudo systemctl reboot --force --force; sync; echo Rebooting"]
    pause_after = "3m"
  }



  post-processors {
    post-processor "vagrant" {
      only                = [ "virtualbox-iso.vagrant" ]
      output              = "k3os-local.box"
    }
    post-processor "vagrant-cloud" {
      name                = "vagrant-cloud"
      only                = [ "virtualbox-iso.vagrant" ]
      access_token        = "${var.vagrant_cloud_token}"
      box_tag             = "spigell/k3os"
      no_release          = true
      version             = "${local.vagrant_box_version}"
      version_description = "Based on version ${var.iso_version}"
    }
  }
}
