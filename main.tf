terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system" 
}

resource "libvirt_pool" "win22-pool" {
  name = "win22-pool"
  type = "dir"
  path = "/opt/win22-pool"
}
resource "libvirt_volume" "win22-volume" {
  name   = "win22-volume"
  source = "../packer/win22-core/WindowsServer2022Core"
  pool   = libvirt_pool.win22-pool.name
  format = "qcow2"
}

resource "libvirt_domain" "win22-domain" {
  name      = "win22"
  memory    = "4096"
  vcpu      = 2
  autostart = true
  network_interface {
    bridge = "br0"
    mac    = "52:54:00:F2:40:AB"
  }
  disk {
    volume_id = libvirt_volume.win22-volume.id
  }
}
