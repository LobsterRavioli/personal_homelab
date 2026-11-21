# Personal Homelab

Homelab for certification practice and self-hosting.

## Topology

```mermaid
flowchart TB
    modem["Modem<br/>192.168.1.1"] --- switch["Switch"]
    switch --- k1["kube-01<br/>192.168.1.205"]
    switch --- k2["kube-02<br/>192.168.1.201"]
    switch --- k3["kube-03<br/>192.168.1.204"]
```

| Host | Hardware | CPU | RAM | Role |
|------|----------|-----|-----|------|
| kube-01 | ThinkPad T480 | 8 threads | 16 GB | control plane |
| kube-02 | ThinkCentre M910q | 4 threads | 16 GB | worker |
| kube-03 | ThinkCentre M910q | 4 threads | 16 GB | worker |

All nodes run Debian 13 with static IPs on `192.168.1.0/24`.

## Index

- [CKS lab](labs/cks/README.md)
- [RHCSA lab](labs/rhcsa/README.md)
