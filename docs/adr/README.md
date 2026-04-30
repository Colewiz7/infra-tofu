# Architecture Decision Records

This directory holds the ADRs for the colewiz.dev platform. Each ADR captures a single architectural choice, the context that drove it, the consequences, and what was rejected.

ADRs are immutable once accepted. If a decision is later reversed, a new ADR supersedes it; the old one stays in the history with status "Superseded by ADR-NNN."

## Index

| # | Title | Status |
|---|-------|--------|
| 001 | [Proxmox VE Hypervisor Over Bare-Metal Linux](./001-proxmox-vs-bare-metal.md) | Accepted |
| 002 | [GPU Workloads In LXC With Bind-Mounted Devices](./002-gpu-lxc-bind-mount.md) | Accepted |
| 003 | [Argo CD Over Flux For GitOps Reconciliation](./003-argo-cd-over-flux.md) | Accepted |
| 004 | [Cilium With kube-proxy Replacement](./004-cilium-kube-proxy-replacement.md) | Accepted |
| 005 | [OpenTofu Over Terraform](./005-opentofu-over-terraform.md) | Accepted |
| 006 | [SOPS+Age For Bootstrap, OpenBao For Runtime](./006-sops-age-not-vault-bootstrap.md) | Accepted |
| 007 | [No Service Mesh On Single-Node Cluster](./007-no-service-mesh-yet.md) | Accepted |

## Format

Each ADR follows the [classic Michael Nygard format](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md):

- **Status**: Proposed | Accepted | Superseded
- **Context**: What's the situation
- **Decision**: What I chose
- **Consequences**: What follows
- **Alternatives considered**: What I rejected and why
- **References**: Where to read more
