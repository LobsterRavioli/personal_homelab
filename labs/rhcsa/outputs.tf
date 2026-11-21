output "nodes" {
  description = "Come raggiungere le VM"
  value = {
    for name, cfg in var.nodes : name => {
      ip      = cfg.ip
      fqdn    = "${name}.${var.domain}"
      ssh     = "ssh ${var.lab_user}@${cfg.ip}"
      console = "virsh -c qemu:///system console rhcsa-${name}"
    }
  }
}

locals {
  ssh_lines = join("\n", [
    for name, n in var.nodes : format("     %-9s ssh %s@%s   (%s.%s)", name, var.lab_user, n.ip, name, var.domain)
  ])

  disk_lines = join("\n", [
    for name, n in var.nodes : format("     %-9s %s", name, length(n.extra_disks) == 0 ? "nessun disco extra" : join(", ", [
      for idx, size in n.extra_disks : "vd${substr("bcdefghij", idx, 1)} ${size}G"
    ]))
  ])

  first_node = keys(var.nodes)[0]
}

# Rileggilo quando vuoi con:  terraform output -raw connect
output "connect" {
  description = "Guida rapida per collegarsi al lab RHCSA"
  value       = <<-EOT

    =============== Lab RHCSA: come collegarti ===============

    1) Entra in kube-01 (le VM stanno sulla rete interna ${var.network_cidr}):
         ssh kube-01

    2) SSH alle VM (chiave ~/.ssh/id_ed25519 di kube-01, sudo senza password):
    ${local.ssh_lines}
       Da root:  sudo -i

    3) Console seriale (se hai rotto la rete o sshd):
         virsh -c qemu:///system console rhcsa-${local.first_node}
         login: root / password: variabile root_password (default "redhat")
         per uscire: Ctrl+]

    4) Schermo VNC, serve per GRUB (es. reset della password di root con rd.break):
         virsh -c qemu:///system vncdisplay rhcsa-${local.first_node}   # es. 127.0.0.1:0 -> porta 5900
       Dal PC, con un tunnel SSH:
         ssh -L 5900:127.0.0.1:5900 kube-01
         poi un client VNC su localhost:5900
       Oppure virt-manager dal PC:  virt-manager -c qemu+ssh://kube-01/system
       Riavvio "a freddo" da kube-01:  virsh -c qemu:///system reset rhcsa-${local.first_node}

    5) Dischi vuoti per LVM / Stratis / swap / partizioni:
    ${local.disk_lines}

    Nota: cloud-init è disattivato dopo il primo boot, quindi hostname,
    rete e utenti che modifichi restano come li lasci.

    6) Gestione del lab (da ~/personal_homelab/labs/rhcsa):
         terraform output -raw connect     # rivedi questa guida
         terraform apply                   # (ri)crea il lab
         terraform destroy                 # spegni tutto e libera la RAM
       Ricominciare da zero una sola VM:
         terraform apply -replace='libvirt_domain.node["${local.first_node}"]' -replace='libvirt_volume.root["${local.first_node}"]'
    ==========================================================
  EOT
}
