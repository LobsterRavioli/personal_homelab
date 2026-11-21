# RHCSA lab

Two Rocky Linux VMs for RHCSA (EX200) practice. Terraform creates them on kube-01 through the `dmacvicar/libvirt` provider (pinned to 0.8.3).

Provisioning is minimal on purpose: a user, an SSH key and a root password. Networking, repos, firewall, services and storage are the exercise.

## What it builds

| VM | FQDN | IP | vCPU | RAM | Extra disks |
|----|------|----|------|-----|-------------|
| server1 | server1.lab.example.com | 192.168.70.11 | 1 | 1.5 GB | vdb 5G, vdc 5G, vdd 2G |
| server2 | server2.lab.example.com | 192.168.70.12 | 1 | 1 GB | vdb 5G |

- Rocky Linux 9, 20 GB system disk (`vda`)
- Extra disks are empty: use them for partitions, LVM, Stratis, swap
- NAT network `rhcsa`, `192.168.70.0/24`, domain `lab.example.com`: the VMs reach the internet and resolve each other by name, the home LAN cannot reach them
- User `student` with SSH key and passwordless sudo; root password for the console
- cloud-init disables itself after the first boot, so your changes to hostname, network and users stay

## Requirements on the host

- KVM/QEMU and libvirt, user in the `libvirt` and `kvm` groups
- `genisoimage` (the provider uses it to build the cloud-init ISO)
- Terraform >= 1.5
- libvirt storage pool `default`
- `~/.ssh/id_ed25519.pub`
- [Rocky-9-GenericCloud-Base.latest.x86_64.qcow2](https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2) in `~/images`

## Usage

```bash
terraform init
terraform apply
terraform output -raw connect    # how to reach the VMs
terraform destroy                # free the RAM when done
```

Reset a single VM to a clean state:

```bash
terraform apply -replace='libvirt_domain.node["server1"]' -replace='libvirt_volume.root["server1"]'
```

## Access

From kube-01:

| What | How |
|------|-----|
| SSH | `ssh student@192.168.70.11`, then `sudo -i` |
| Serial console | `virsh -c qemu:///system console rhcsa-server1`, login `root`, exit with `Ctrl+]` |
| Graphical console (GRUB, root password reset) | `virsh -c qemu:///system vncdisplay rhcsa-server1`, then from your PC `ssh -L 5900:127.0.0.1:5900 kube-01` and a VNC client on `localhost:5900` |
| Hard reset | `virsh -c qemu:///system reset rhcsa-server1` |

VNC only listens on `127.0.0.1` of kube-01, so it needs the SSH tunnel. `virt-manager -c qemu+ssh://kube-01/system` works too.

## Variables

| Name | Default | |
|------|---------|---|
| `base_image` | Rocky 9 cloud image | Match the RHEL major version of the current EX200 |
| `root_password` | `redhat` | Lab-only; override in `terraform.tfvars` (gitignored) |
| `nodes` | 2 VMs above | Add VMs or change `extra_disks` here |
