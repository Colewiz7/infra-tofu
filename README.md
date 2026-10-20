# infra-tofu

OpenTofu for the infrastructure around the colewiz.dev homelab: Cloudflare DNS, the tunnel and R2 buckets, and the GitHub settings of the repos that run it. The cluster itself is declared in [homelab-gitops](https://github.com/Colewiz7/homelab-gitops).

## What it manages

| file | resources |
|---|---|
| `cloudflare-dns.tf` | one proxied CNAME per app hostname through the tunnel, the apex record, and A records for game-server hostnames |
| `cloudflare-tunnel.tf` | the tunnel's ingress map: hostname to in-cluster service, with per-origin overrides |
| `cloudflare-r2.tf` | R2 buckets for OpenTofu state, Velero backups and the Postgres WAL archive |
| `github-repos.tf` | repo settings, topics, merge rules and vulnerability alerts for the managed repos |
| `providers.tf` | provider pins, the R2 state backend and state encryption |
| `imports.tf` | `import` blocks for resources that existed before they were declared |
| `vm-k3s-01.tf` | notes only. The k3s VM was rebuilt by hand with GPU passthrough and is not in state |

The public hostnames all share one pattern: DNS points at the tunnel, the tunnel ingress map points at a Kubernetes service, and nothing listens on an inbound port at home. Adding an app is one entry in the ingress map and one DNS name.

## State and secrets

State lives in a Cloudflare R2 bucket through the S3 backend and is encrypted client-side with OpenTofu's native AES-GCM encryption. The passphrase comes from `TF_VAR_state_passphrase`, so neither the state nor a plan is readable without it.

Variables such as API tokens live in `terraform.tfvars.encrypted`, which is encrypted with SOPS and age before it is committed.

## Run it

```sh
sops -d terraform.tfvars.encrypted > terraform.tfvars   # needs the age key
export TF_VAR_state_passphrase=...
tofu init
tofu plan
tofu apply
```

`terraform.tfvars` is gitignored. Providers are `cloudflare` 5.x, `integrations/github` 6.x and `bpg/proxmox`, on OpenTofu 1.9 or newer.

## Docs

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) the layers of the platform, from hardware to workloads.
- [`docs/BOOTSTRAP.md`](docs/BOOTSTRAP.md) bringing everything up again from a fresh laptop.
- [`docs/adr/`](docs/adr/) seven architecture decision records, each with the tradeoff and what would make me change my mind. Examples: Argo CD over Flux, Cilium replacing kube-proxy, OpenTofu over Terraform, and no service mesh on a single node.
