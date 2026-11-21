locals {
  gib = 1024 * 1024 * 1024

  controlplane_ip = one([for n in var.nodes : n.ip if n.role == "controlplane"])

  # Formato richiesto da kubeadm: [a-z0-9]{6}.[a-z0-9]{16}
  kubeadm_token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

# --- Token kubeadm ------------------------------------------------------------
# Generato da Terraform così control plane e worker lo conoscono in anticipo.
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

# --- Rete -------------------------------------------------------------------
resource "libvirt_network" "lab" {
  name      = "cks"
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
resource "libvirt_volume" "base" {
  name   = "cks-ubuntu-base.qcow2"
  pool   = var.storage_pool
  source = pathexpand(var.base_image)
  format = "qcow2"
}

resource "libvirt_volume" "root" {
  for_each = var.nodes

  name           = "cks-${each.key}-root.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.base.id
  size           = each.value.disk_gb * local.gib
}

# --- cloud-init ---------------------------------------------------------------
# Stesso template per tutti i nodi; cambia solo ciò che dipende da nome/ruolo/IP.
resource "libvirt_cloudinit_disk" "seed" {
  for_each = var.nodes

  name = "cks-${each.key}-seed.iso"
  pool = var.storage_pool

  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    lab_user       = var.lab_user
    lab_password   = var.lab_password
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key)))
    k8s_minor      = var.k8s_minor
    role           = each.value.role
    node_ip        = each.value.ip
    nodes          = var.nodes
    domain         = var.domain
    auto_bootstrap = var.auto_bootstrap
    pod_cidr       = var.pod_cidr
    kubeadm_token  = local.kubeadm_token
    cp_ip          = local.controlplane_ip
  })

  meta_data = yamlencode({
    "instance-id"    = "cks-${each.key}"
    "local-hostname" = each.key
  })
}

# --- VM -----------------------------------------------------------------------
resource "libvirt_domain" "node" {
  for_each = var.nodes

  name      = "cks-${each.key}"
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
    addresses      = [each.value.ip]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.root[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
