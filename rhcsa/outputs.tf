output "nodes" {
  description = "Come raggiungere le VM"
  value = {
    for name, cfg in var.nodes : name => {
      ip      = cfg.ip
      ssh     = "ssh ${var.lab_user}@${cfg.ip}"
      console = "virsh console rhcsa-${name}"
    }
  }
}
