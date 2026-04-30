# GitHub repository governance via OpenTofu.
# Source of truth for repo settings, branch protection, and security.

locals {
  managed_repos = {
    "infra-tofu" = {
      description     = "OpenTofu IaC for colewiz.dev (Cloudflare, Proxmox, GitHub)"
      visibility      = "public"
      has_issues      = true
      has_wiki        = false
      has_projects    = false
      topics          = ["opentofu", "iac", "homelab", "cloudflare", "devops"]
    }
    "homelab-gitops" = {
      description     = "GitOps source of truth for colewiz.dev k3s cluster"
      visibility      = "public"
      has_issues      = true
      has_wiki        = false
      has_projects    = false
      topics          = ["kubernetes", "k3s", "argocd", "gitops", "homelab"]
    }
  }
}

# Repository settings (existing repos imported, not recreated)
resource "github_repository" "managed" {
  for_each = local.managed_repos

  name         = each.key
  description  = each.value.description
  visibility   = each.value.visibility
  has_issues   = each.value.has_issues
  has_wiki     = each.value.has_wiki
  has_projects = each.value.has_projects
  topics       = each.value.topics

  # Sensible defaults
  has_downloads          = false
  delete_branch_on_merge = true
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = true
  allow_auto_merge       = false
  vulnerability_alerts   = true

  # Don't force tofu to recreate the repo on import
  lifecycle {
    ignore_changes = [
      auto_init,
      gitignore_template,
      license_template,
      template,
    ]
  }
}

# Branch protection on main for both repos
resource "github_branch_protection" "main" {
  for_each = local.managed_repos

  repository_id = github_repository.managed[each.key].node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0  # Solo project; bump to 1 if you add collaborators
    dismiss_stale_reviews            = true
    require_code_owner_reviews       = false
  }

  required_status_checks {
    strict   = true
    contexts = []  # Will populate when CI lands
  }

  enforce_admins                  = false  # You can bypass; flip to true once stable
  require_signed_commits          = false  # Flip to true after setting up commit signing
  require_conversation_resolution = true
  allows_force_pushes             = false
  allows_deletions                = false
}

output "repo_urls" {
  description = "URLs of managed repos"
  value       = { for k, _ in local.managed_repos : k => "https://github.com/Colewiz7/${k}" }
}
