# Cloudflare R2 buckets for the colewiz.dev platform.
#
# - tofu_state: Backend for OpenTofu state itself (encrypted)
# - velero:     Kubernetes backup target (Velero + Kopia uploader)
# - cnpg:       PostgreSQL WAL archive (CloudNativePG continuous archiving)

resource "cloudflare_r2_bucket" "tofu_state" {
  account_id = var.cloudflare_account_id
  name       = "colewiz-tofu-state"
  location   = "ENAM"
}

resource "cloudflare_r2_bucket" "velero" {
  account_id = var.cloudflare_account_id
  name       = "colewiz-velero-backups"
  location   = "ENAM"
}

resource "cloudflare_r2_bucket" "cnpg" {
  account_id = var.cloudflare_account_id
  name       = "colewiz-postgres-wal"
  location   = "ENAM"
}

output "r2_buckets" {
  description = "All R2 bucket names created by this module"
  value = {
    tofu_state = cloudflare_r2_bucket.tofu_state.name
    velero     = cloudflare_r2_bucket.velero.name
    cnpg       = cloudflare_r2_bucket.cnpg.name
  }
}
