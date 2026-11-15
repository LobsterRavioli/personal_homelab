output "nodes" {
  description = "Come raggiungere le VM"
  value = {
    for name, cfg in var.nodes : name => {
      role    = cfg.role
      ip      = cfg.ip
      ssh     = "ssh ${var.lab_user}@${cfg.ip}"
      console = "virsh console cks-${name}"
    }
  }
}
