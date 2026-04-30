# colewiz infra-tofu

OpenTofu IaC for the colewiz.dev homelab platform.

## Modules
- `01-proxmox/` — Hypervisor storage, network, API users
- `02-vms/` — KVM VMs (k3s nodes, DR target)
- `03-lxc/` — LXC containers (Ollama, AMP, NFS)
- `04-cloudflare/` — DNS, Tunnel, R2 buckets, Zero Trust
- `05-github/` — Repo settings, branch protection

## State
State stored in Cloudflare R2 with native OpenTofu encryption.

## Secrets
`terraform.tfvars` is encrypted with SOPS+age before commit.

