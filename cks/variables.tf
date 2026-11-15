variable "base_image" {
  description = "Cloud image Ubuntu 24.04 (qcow2) già scaricata"
  type        = string
  default     = "~/images/noble-server-cloudimg-amd64.img"
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

variable "k8s_minor" {
  description = "Minor version di Kubernetes (repo pkgs.k8s.io). Allineala alla versione attuale dell'esame CKS."
  type        = string
  default     = "v1.35"
}

variable "storage_pool" {
  description = "Storage pool di libvirt dove finiscono i dischi"
  type        = string
  default     = "default"
}

variable "network_cidr" {
  description = "Subnet delle VM (diversa da LAN, k3s 10.42/10.43, pod 10.244, service 10.96 e lab RHCSA)"
  type        = string
  default     = "192.168.60.0/24"
}

variable "domain" {
  description = "Dominio DNS interno del lab"
  type        = string
  default     = "cks.lab"
}

variable "nodes" {
  description = "Le VM del cluster. role = controlplane | worker"
  type = map(object({
    role    = string
    ip      = string
    memory  = number # MiB
    vcpu    = number
    disk_gb = number
  }))
  default = {
    controlplane = { role = "controlplane", ip = "192.168.60.10", memory = 3072, vcpu = 2, disk_gb = 30 }
    worker1      = { role = "worker", ip = "192.168.60.11", memory = 2048, vcpu = 2, disk_gb = 30 }
    worker2      = { role = "worker", ip = "192.168.60.12", memory = 2048, vcpu = 2, disk_gb = 30 }
  }
}
