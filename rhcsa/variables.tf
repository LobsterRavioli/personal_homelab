variable "base_image" {
  description = "Cloud image Rocky Linux (qcow2) già scaricata. Allinea la major version a quella dell'esame EX200."
  type        = string
  default     = "~/images/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
}

variable "ssh_public_key" {
  description = "Chiave pubblica SSH da autorizzare nelle VM"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "lab_user" {
  description = "Utente creato da cloud-init (sudo senza password, accesso con chiave)"
  type        = string
  default     = "student"
}

variable "root_password" {
  description = "Password di root (per la console: ti servirà per esercitarti a resettarla)"
  type        = string
  default     = "redhat"
  sensitive   = true
}

variable "storage_pool" {
  description = "Storage pool di libvirt dove finiscono i dischi"
  type        = string
  default     = "default"
}

variable "network_cidr" {
  description = "Subnet del lab (non deve sovrapporsi a LAN, k3s o al lab CKS)"
  type        = string
  default     = "192.168.70.0/24"
}

variable "domain" {
  description = "Dominio DNS interno del lab"
  type        = string
  default     = "lab.example.com"
}

variable "nodes" {
  description = "Le VM del lab. extra_disks = dimensioni in GiB dei dischi vuoti (vdb, vdc, ...)"
  type = map(object({
    ip          = string
    memory      = number # MiB
    vcpu        = number
    extra_disks = list(number)
  }))
  default = {
    server1 = { ip = "192.168.70.11", memory = 1536, vcpu = 1, extra_disks = [5, 5, 2] }
    server2 = { ip = "192.168.70.12", memory = 1024, vcpu = 1, extra_disks = [5] }
  }
}
