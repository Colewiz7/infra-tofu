# Bootstrapping colewiz.dev From Zero

> How to bring this platform up from a fresh laptop or a fresh server.

## Audience

Future-me, six months from now, after a laptop swap or a hardware migration.

## Prerequisites

- Bitwarden access (contains all secrets and the age key backup)
- A working laptop (any Linux/macOS distribution; CachyOS in my case)
- The age private key from Bitwarden, restored to `~/.config/sops/age/keys.txt`
- An SSH key on the laptop, public half added to GitHub
- The hardware target running Proxmox VE 9.x (separate runbook)

## Phase 1: Laptop Tooling

```fish
# Arch-based (CachyOS)
sudo pacman -S --needed git github-cli base-devel curl wget unzip jq age kubectl helm k9s
paru -S opentofu sops argocd cloudflared go-yq

# Authenticate GitHub
gh auth login

# Restore age key from Bitwarden
mkdir -p ~/.config/sops/age
# (paste private key contents)
chmod 600 ~/.config/sops/age/keys.txt
```

## Phase 2: Clone Repos

```fish
mkdir -p ~/code/colewiz
cd ~/code/colewiz
git clone git@github.com:Colewiz7/infra-tofu.git
git clone git@github.com:Colewiz7/homelab-gitops.git
```

## Phase 3: Decrypt Secrets

```fish
cd ~/code/colewiz/infra-tofu
sops --decrypt terraform.tfvars.encrypted > terraform.tfvars
```

## Phase 4: Set Environment Variables

Pull these from Bitwarden one by one:

```fish
set -x TF_VAR_state_passphrase "from-bitwarden"
set -x AWS_ACCESS_KEY_ID       "from-bitwarden-r2"
set -x AWS_SECRET_ACCESS_KEY   "from-bitwarden-r2"
```

The Cloudflare API token, account ID, and zone ID come from `terraform.tfvars` and don't need to be exported.

## Phase 5: Validate The Stack Is Reachable

```fish
tofu init        # pulls providers, connects to R2 backend
tofu plan        # should print: No changes
```

If plan succeeds and prints "No changes," you have full IaC control over the platform.

## Phase 6: Server-Side Bootstrap

See `docs/runbooks/server-bootstrap.md` (TODO, written when Proxmox is flashed).

In summary:

1. Flash Proxmox VE 9.x ISO to USB
2. Install with two-disk layout (SSD = LVM-thin, HDD = ZFS pool `tank`)
3. Install NVIDIA 580 legacy driver, `apt-mark hold` the packages
4. Create the `tofu@pve` API user, copy the token to `terraform.tfvars`
5. From the laptop: `tofu apply` to provision VMs and LXCs
6. SSH into k3s VM, install k3s with Cilium-ready flags
7. From the laptop: `argocd app create` for the bootstrap App, which reconciles everything else from `homelab-gitops`

## Recovery Time From Zero

- Laptop replacement: ~30 minutes (tooling install + repo clone + var setup)
- Server replacement (with hardware on hand): ~2 hours (Proxmox install + k3s + Argo CD bootstrap; actual workload reconciliation is automatic from there)
- Total stack recovery from total host loss: <1 day end-to-end

## Things That Are Not In Git And Must Be Restored Manually

- Age private key
- R2 access keys
- OpenTofu state passphrase
- Proxmox root password
- Authentik admin password
