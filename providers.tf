terraform {
  required_version = ">= 1.9"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Remote state in Cloudflare R2 (S3-compatible)
  backend "s3" {
    bucket    = "colewiz-tofu-state"
    key       = "homelab/terraform.tfstate"
    region    = "auto"
    endpoints = { s3 = "https://a3fc8b7925c5c38c05d3dc652d780635.r2.cloudflarestorage.com" }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }

  # OpenTofu native state and plan encryption (the differentiator vs Terraform)
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "encrypted" {
      keys = key_provider.pbkdf2.passphrase
    }

    state {
      method = method.aes_gcm.encrypted
    }

    plan {
      method = method.aes_gcm.encrypted
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_token
  owner = "Colewiz7"
}
