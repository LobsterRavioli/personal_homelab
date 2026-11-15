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

locals {
  ssh_lines = join("\n", [
    for name, n in var.nodes : format("     %-13s ssh %s@%s", name, var.lab_user, n.ip)
  ])

  cluster_status = var.auto_bootstrap ? "il cluster viene creato da solo (~5 min dopo l'apply)" : "auto_bootstrap=false: nodi pronti, kubeadm init/join li fai tu"
}

# Rileggilo quando vuoi con:  terraform output -raw connect
output "connect" {
  description = "Guida rapida per collegarsi al cluster"
  value       = <<-EOT

    =============== Lab CKS: come collegarti ===============
    Stato: ${local.cluster_status}

    1) Entra in kube-01 (le VM stanno sulla rete interna ${var.network_cidr}):
         ssh kube-01

    2) SSH ai nodi (chiave ~/.ssh/id_ed25519 di kube-01, sudo senza password):
    ${local.ssh_lines}

       Console seriale, se la rete della VM non risponde:
         virsh -c qemu:///system console cks-controlplane
         login: ${var.lab_user} / password: variabile lab_password (default "student")
         per uscire: Ctrl+]

    3) Usa il cluster dal control plane:
         ssh ${var.lab_user}@${local.controlplane_ip}
         cloud-init status --wait    # aspetta la fine del bootstrap
         k get nodes -o wide         # alias k=kubectl già pronto
         cilium status

    4) Oppure usa kubectl direttamente da kube-01
       (file separato: il kubeconfig di k3s non viene toccato):
         mkdir -p ~/.kube
         scp ${var.lab_user}@${local.controlplane_ip}:.kube/config ~/.kube/cks.yaml
         export KUBECONFIG=~/.kube/cks.yaml
         kubectl get nodes
       Per tornare a k3s:  unset KUBECONFIG

    5) Gestione del lab (da ~/personal_homelab/cks):
         terraform output -raw connect          # rivedi questa guida
         terraform apply -var auto_bootstrap=false   # nodi puliti, cluster a mano
         terraform destroy                      # spegni tutto e libera la RAM
    ========================================================
  EOT
}
