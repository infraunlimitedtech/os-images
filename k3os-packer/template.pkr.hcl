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
  default = "v0.20.7-k3s1r0"
}

variable "iso_checksum" {
  type    = string
  default = "85a560585bc5520a793365d70e6ce984f3fb2ce5a43b31f0f7833dc347487e69"
}

locals {
  iso_url = "https://github.com/rancher/k3os/releases/download/${var.iso_version}/k3os-amd64.iso"
}

variable "vagrant_box_version" {
  type    = string
  default = "0.20.7"
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
  boot_command         = ["rancher", "<enter>", "sudo k3os install", "<enter>", "1", "<enter>", "y", "<enter>", "http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant-virtualbox/config.yml", "<enter>", "y", "<enter>"]
  boot_wait            = "40s"
  disk_size            = "8000"
  export_opts          = ["--manifest", "--vsys", "0", "--description", "${var.description}", "--version", "${var.vagrant_box_version}"]
  format               = "ova"
  guest_os_type        = "Linux_64"
  http_directory       = "."
  iso_checksum         = "sha256:${var.iso_checksum}"
  iso_url              = "${local.iso_url}"
  post_shutdown_delay  = "10s"
  shutdown_command     = "sudo poweroff"
  ssh_keypair_name     = ""
  ssh_private_key_file = "vagrant-virtualbox/id_rsa"
  ssh_timeout          = "1000s"
  ssh_username         = "rancher"
}



build {
  sources = ["source.hcloud.main", "source.virtualbox-iso.vagrant"]


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
      only        = [ "virtualbox-iso.vagrant" ]
      output = "k3os-vagrant.box"
    }
    post-processor "vagrant-cloud" {
      name = "vagrant-cloud"
      only        = [ "virtualbox-iso.vagrant" ]
      access_token        = "${var.vagrant_cloud_token}"
      box_tag             = "spigell/k3os"
      no_release          = true
      version             = "${var.vagrant_box_version}"
      version_description = "Based on version ${var.iso_version}"
    }
  }
}
