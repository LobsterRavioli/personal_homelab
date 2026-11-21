# Personal Homelab

My homelab. I use it to practice for certifications, try new stacks and self-host a few services.

```
.
├── README.md
└── labs/
    ├── cks/      # kubeadm cluster for CKS practice
    └── rhcsa/    # Rocky Linux VMs for RHCSA practice
```

## Topology

### Home network

```mermaid
flowchart TB
    internet((Internet)) --- modem["TIM modem<br/>192.168.1.1<br/>gateway · DNS · DHCP"]
    modem --- switch["Netgear GS305<br/>unmanaged switch"]
    switch --- k1["kube-01<br/>ThinkPad T480<br/>192.168.1.205"]
    switch --- k2["kube-02<br/>ThinkCentre M910q<br/>192.168.1.201"]
    switch --- k3["kube-03<br/>ThinkCentre M910q<br/>192.168.1.204"]
    laptop["laptop"] -. ssh .- modem
```

- Network `192.168.1.0/24`, gateway and DNS `192.168.1.1`.
- The modem hands out DHCP addresses from `.2` upwards; the nodes use static addresses from `.201`.
- Nodes are wired to the switch; the switch has no IP.

### Nodes

| Host | Hardware | CPU threads | RAM | IP | Role |
|------|----------|-------------|-----|----|------|
| kube-01 | ThinkPad T480 | 8 | 16 GB | 192.168.1.205 | control plane, libvirt host for the labs |
| kube-02 | ThinkCentre M910q | 4 | 16 GB | 192.168.1.201 | worker |
| kube-03 | ThinkCentre M910q | 4 | 16 GB | 192.168.1.204 | worker |

All three run Debian 13 with a static address in `/etc/network/interfaces`. kube-01 has the lid switch set to `ignore` so it does not suspend when closed.

### Kubernetes cluster

```mermaid
flowchart LR
    subgraph k8s["Kubernetes cluster"]
        cp["kube-01<br/>control plane"]
        w1["kube-02<br/>worker"]
        w2["kube-03<br/>worker"]
    end
    cp --- w1
    cp --- w2
```

### Labs on kube-01

The labs run as KVM VMs on kube-01, each on its own libvirt NAT network. They can reach the internet but not the home LAN, and the LAN cannot reach them: connect from kube-01.

```mermaid
flowchart TB
    lan["Home LAN<br/>192.168.1.0/24"] --- host
    subgraph host["kube-01 · KVM/libvirt"]
        subgraph cks["NAT 'cks' · 192.168.60.0/24"]
            cp["controlplane<br/>.10"]
            w1["worker1<br/>.11"]
            w2["worker2<br/>.12"]
        end
        subgraph rhcsa["NAT 'rhcsa' · 192.168.70.0/24"]
            s1["server1<br/>.11"]
            s2["server2<br/>.12"]
        end
    end
```

### Address plan

| Range | Used by |
|-------|---------|
| 192.168.1.0/24 | Home LAN |
| 192.168.1.2 – .200 | DHCP (modem) |
| 192.168.1.201 – .254 | Static: nodes |
| 10.42.0.0/16 · 10.43.0.0/16 | Pods · services of the home cluster |
| 192.168.60.0/24 | CKS lab VMs |
| 192.168.70.0/24 | RHCSA lab VMs |
| 10.244.0.0/16 · 10.96.0.0/12 | Pods · services inside the CKS lab |

## Labs

| Lab | For | Details |
|-----|-----|---------|
| [labs/cks](labs/cks) | CKS | 3-node kubeadm cluster with Cilium |
| [labs/rhcsa](labs/rhcsa) | RHCSA | 2 Rocky Linux VMs with spare disks |
