# colewiz.dev Platform Architecture

> Three-tier homelab platform for self-hosted services and engineering portfolio. Designed to look, operate, and recover like a real production platform on a budget of one server, one student, and a Cloudflare account.

## North Star

Every layer of this platform exists to demonstrate a real-world pattern, not a hobbyist shortcut. When a choice is between "easier" and "more representative of how teams actually work," I pick the latter and document the reasoning in an ADR.

## High-Level Topology

```
┌──────────────────────────────────────────────────────────┐
│ User (browser)                                           │
└─────────────────────────┬────────────────────────────────┘
                          │ HTTPS
                          ▼
┌──────────────────────────────────────────────────────────┐
│ Cloudflare Edge (proxied)                                │
│  • TLS termination                                       │
│  • WAF + DDoS                                            │
│  • Tunnel egress (no inbound ports on origin)            │
└─────────────────────────┬────────────────────────────────┘
                          │ outbound-only tunnel
                          ▼
┌──────────────────────────────────────────────────────────┐
│ Proxmox VE 9.x  (bare metal: GTX 2070 Super, 6c/33GB)    │
│  ┌──────────────────────┐  ┌──────────────────────────┐  │
│  │ VM 100: k3s-01       │  │ LXC 200: ollama          │  │
│  │  • Cilium eBPF CNI   │  │  • GPU bind-mounted      │  │
│  │  • Traefik Gateway   │  │  • LLM serving           │  │
│  │  • Authentik SSO     │  └──────────────────────────┘  │
│  │  • Argo CD           │  ┌──────────────────────────┐  │
│  │  • CloudNativePG     │  │ LXC 201: amp             │  │
│  │  • kube-prometheus   │  │  • Game server manager   │  │
│  │  • App workloads     │  └──────────────────────────┘  │
│  └──────────────────────┘  ┌──────────────────────────┐  │
│                            │ VM 102: dr-target        │  │
│                            │  • Stopped; DR drills    │  │
│                            └──────────────────────────┘  │
│  ZFS pool /tank: app data, media, backups                │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│ Cloudflare R2 (offsite, encrypted, $0 egress)            │
│  • colewiz-tofu-state    OpenTofu state                  │
│  • colewiz-velero-backups  K8s resource + PV backups     │
│  • colewiz-postgres-wal    CNPG continuous WAL archive   │
└──────────────────────────────────────────────────────────┘
```

## Layers Of The Stack

**Layer 0 — Hardware**: a single bare-metal box with two disks (SSD for OS/VM root, HDD for ZFS data pool) and a Turing-generation NVIDIA RTX 2070 Super (8GB VRAM). The GPU runs on current mainline NVIDIA drivers, no legacy branch pinning required.

**Layer 1 — Hypervisor**: Proxmox VE 9.x runs on the box. KVM VMs host workloads that benefit from snapshot-able block devices (k3s, DR target). LXC containers host workloads that conflict with the Kubernetes model (Ollama needing direct GPU access, AMP spawning privileged child processes).

**Layer 2 — Kubernetes**: a single-node k3s cluster running inside one VM. Cilium replaces Flannel, kube-proxy, kube-router, and ServiceLB with a single eBPF dataplane. Traefik v3 with the Gateway API serves as ingress, with Authentik forward-auth on every internal hostname.

**Layer 3 — Workloads**: every application is a Helm release or Kustomize overlay reconciled by Argo CD. The Git monorepo is the source of truth; the cluster is the read replica.

## Source-Of-Truth Boundaries

| Concern | Source of truth | Tool |
|---|---|---|
| Cloudflare DNS, Tunnel, R2 buckets | `infra-tofu` repo | OpenTofu |
| GitHub repo settings, branch protection | `infra-tofu` repo | OpenTofu |
| Proxmox VMs and LXCs | `infra-tofu` repo | OpenTofu (bpg/proxmox) |
| Kubernetes workloads | `homelab-gitops` repo | Argo CD |
| Application source code | per-app repo (e.g., `dishwatcher`) | GitHub Actions → GHCR |
| Secrets at rest | `infra-tofu` repo (encrypted) | SOPS + age |
| Secrets at runtime | OpenBao | External Secrets Operator |

The split between `infra-tofu` and `homelab-gitops` is intentional: tofu provisions the *infrastructure that hosts Kubernetes*; Argo CD provisions *workloads inside Kubernetes*. The two never overlap.

## Resilience And Recovery

- **State durability**: OpenTofu state lives in encrypted Cloudflare R2, not on the laptop. Any machine with the age key and R2 credentials can take over.
- **Cluster recovery**: Velero backs up Kubernetes resources and PVs to R2 nightly. Proxmox snapshots provide a separate recovery path for whole-VM rollback.
- **Database recovery**: CloudNativePG continuously archives WAL to R2, providing 5-minute RPO point-in-time recovery for every Postgres database in the cluster.
- **Disaster recovery target**: VM 102 is a stopped Proxmox VM. During drills it's `qm start`'d in under a minute, then bootstrapped from the Velero backup. Validated monthly. Cost: $0 (free Cloudflare R2 egress).

## Security Stance

Defense-in-depth, seven layers per request:

1. **Cloudflare edge**: TLS, WAF, geo-block, no origin IP exposed
2. **Cloudflare Tunnel**: outbound-only; no listening ports on the home WAN
3. **CrowdSec + AppSec WAF**: local IPS + rule-based filtering
4. **Traefik Gateway API**: rate-limit, security headers, TLS internal
5. **Authentik forward-auth**: OIDC or proxy-mode auth on every internal hostname
6. **Cilium NetworkPolicy**: default-deny within the cluster
7. **Kyverno admission**: only Cosign-signed images from my GHCR path admitted

Secrets never live in Git in plaintext. The only encrypted artifact in Git is the SOPS-age bootstrap file holding OpenBao's unseal key; everything else flows through OpenBao at runtime.

## What This Platform Is Not

- **Not multi-cluster**. One cluster, one node. Adding a second node is a future exercise; the architecture is designed to absorb it without redesign.
- **Not multi-region**. Cloudflare R2 + Tunnel give global edge access for users; the actual compute is in Rochester, NY.
- **Not a service mesh**. Linkerd and Istio Ambient were evaluated. On a single node with WireGuard already encrypting future inter-node traffic and ingress-level authz at Authentik, a mesh adds blast radius without adding capability. Reconsidered if a second node ever joins.
- **Not chaos-engineered**. The discipline of monthly DR drills covers failure modes that matter for one node. Chaos Mesh comes when there's pod anti-affinity to verify.

## Decision Log

Every significant choice in this document has a corresponding ADR in [`docs/adr/`](./adr/). Read them in order to understand how the platform evolved.
