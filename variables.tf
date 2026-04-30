variable "cloudflare_api_token" {
  description = "Cloudflare API token with Account/Zone perms for tofu"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for colewiz.dev"
  type        = string
}

variable "github_token" {
  description = "GitHub fine-grained PAT for repo management"
  type        = string
  sensitive   = true
}

variable "state_passphrase" {
  description = "Passphrase for OpenTofu native state encryption (set via TF_VAR_state_passphrase env)"
  type        = string
  sensitive   = true
}
