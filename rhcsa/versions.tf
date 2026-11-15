terraform {
  required_version = ">= 1.5"

  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      # Versione fissata: dalla 0.9 lo schema è cambiato molto
      # e quasi tutta la documentazione online è per la 0.8.x
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  # L'istanza di sistema di libvirt (quella con reti e storage pool veri)
  uri = "qemu:///system"
}
