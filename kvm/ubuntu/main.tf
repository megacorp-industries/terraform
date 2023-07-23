terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "random_string" "generator" {
  length  = 4
  special = false
  lower   = false
}

resource "libvirt_volume" "ubuntu_volume" {
  name   = "${var.identity}-${random_string.generator.id}"
  # source = "https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-generator-cloudimg-amd64.img"
  source = "${var.imgPath}"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "${var.identity}-init-${random_string.generator.id}"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

resource "libvirt_domain" "ubuntu_domain" {
  name   = "${var.identity}-${random_string.generator.id}"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.cloud_init.id

  disk {
    volume_id = libvirt_volume.ubuntu_volume.id
  }

  network_interface {
    bridge = "br0"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
