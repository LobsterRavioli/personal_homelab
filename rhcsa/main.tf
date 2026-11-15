locals {
  gib = 1024 * 1024 * 1024

  # Trasforma { server1 = { extra_disks = [5, 5, 2] }, ... } in una mappa piatta:
  # { "server1-data1" = { node = "server1", size = 5 }, "server1-data2" = ..., "server2-data1" = ... }
  # così possiamo creare un volume per ogni disco extra con un solo for_each.
  extra_disks = merge([
    for node, cfg in var.nodes : {
      for idx, size in cfg.extra_disks :
      "${node}-data${idx + 1}" => { node = node, size = size }
    }
  ]...)
}

# --- Rete -------------------------------------------------------------------
# Rete NAT dedicata al lab: le VM escono su internet ma sono isolate da LAN e k3s.
# dnsmasq di libvirt fa da DHCP + DNS: server1.lab.example.com risolve da solo.
resource "libvirt_network" "lab" {
  name      = "rhcsa"
  mode      = "nat"
  domain    = var.domain
  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true
  }
}

# --- Dischi -----------------------------------------------------------------
# Immagine base: caricata UNA volta nel pool, poi usata in sola lettura.
resource "libvirt_volume" "base" {
  name   = "rhcsa-rocky-base.qcow2"
  pool   = var.storage_pool
  source = pathexpand(var.base_image)
  format = "qcow2"
}

# Disco di sistema di ogni VM: overlay copy-on-write sopra l'immagine base.
resource "libvirt_volume" "root" {
  for_each = var.nodes

  name           = "rhcsa-${each.key}-root.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.base.id
  size           = 20 * local.gib
}

# Dischi extra VUOTI: per LVM, Stratis, swap, partizionamento...
resource "libvirt_volume" "data" {
  for_each = local.extra_disks

  name   = "rhcsa-${each.key}.qcow2"
  pool   = var.storage_pool
  format = "qcow2"
  size   = each.value.size * local.gib
}

# --- cloud-init ---------------------------------------------------------------
# Il "seed": una piccola ISO con user-data/meta-data che cloud-init legge al primo boot.
resource "libvirt_cloudinit_disk" "seed" {
  for_each = var.nodes

  name = "rhcsa-${each.key}-seed.iso"
  pool = var.storage_pool

  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    lab_user       = var.lab_user
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key)))
    root_password  = var.root_password
  })

  meta_data = yamlencode({
    "instance-id"    = "rhcsa-${each.key}"
    "local-hostname" = each.key
  })
}

# --- VM -----------------------------------------------------------------------
resource "libvirt_domain" "node" {
  for_each = var.nodes

  name      = "rhcsa-${each.key}"
  memory    = each.value.memory
  vcpu      = each.value.vcpu
  autostart = false

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.seed[each.key].id

  network_interface {
    network_id     = libvirt_network.lab.id
    hostname       = each.key
    addresses      = [each.value.ip] # lease DHCP fisso
    wait_for_lease = true
  }

  # vda: disco di sistema
  disk {
    volume_id = libvirt_volume.root[each.key].id
  }

  # vdb, vdc, ...: dischi extra (blocco "disk" generato per ognuno)
  dynamic "disk" {
    for_each = [for key, d in local.extra_disks : key if d.node == each.key]
    content {
      volume_id = libvirt_volume.data[disk.value].id
    }
  }

  # Console seriale -> `virsh console rhcsa-server1`
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  # Schermo VNC solo su localhost -> virt-manager via SSH (per GRUB / reset password root)
  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }
}
