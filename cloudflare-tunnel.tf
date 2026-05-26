# Tunnel ingress routes (which hostname → which backend).
#
# Currently SCAFFOLD — the actual ingress rules live in the Cloudflare
# dashboard (Zero Trust → Networks → Tunnels → Public Hostnames) because
# the tunnel was set up with TUNNEL_TOKEN before tofu existed.
#
# To complete this refactor:
#
# 1. Dump the existing tunnel config:
#       export CF_API_TOKEN=$(grep cloudflare_api_token terraform.tfvars | cut -d'"' -f2)
#       export ACCOUNT_ID=$(grep cloudflare_account_id terraform.tfvars | cut -d'"' -f2)
#       TUNNEL_ID="d7ee8051-29da-48d8-9259-d04ad4785134"
#       curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
#         "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
#         | jq '.result.config.ingress'
#
# 2. Populate `local.tunnel_ingress` below with the dumped rules
#    (one map entry per hostname; the catch-all is added automatically).
#
# 3. `tofu plan` MUST show 0 changes — if it shows any drift, the local
#    list doesn't match the dashboard. Fix before applying.
#
# 4. `tofu apply` — this hands route ownership to tofu. From now on,
#    DO NOT edit routes in the CF dashboard; edit this file instead.
#
# After this lands, adding a new public hostname is one PR:
#   - Append to `tunnel_subdomains` in cloudflare-dns.tf  (creates DNS)
#   - Append to `tunnel_ingress`   in this file           (creates route)

locals {
  tunnel_id = "d7ee8051-29da-48d8-9259-d04ad4785134"

  # hostname → backend URL. Populated during migration (see header).
  # Examples of expected entries:
  #   "auth.colewiz.dev"    = "http://authentik-server.authentik.svc.cluster.local:80"
  #   "files.colewiz.dev"   = "http://filebrowser.filebrowser.svc.cluster.local:80"
  #   "amp.colewiz.dev"     = "http://10.10.10.201:8080"
  #   "colewiz.dev"         = "http://website.website.svc.cluster.local:80"
  tunnel_ingress = {
    # TODO populate from dashboard dump before first apply
  }
}

# Guardrail: this resource only materializes once local.tunnel_ingress is
# populated. Empty map = no resource = tofu touches nothing = dashboard
# config keeps working untouched. This prevents accidentally applying a
# scaffold-empty config that would 404 every hostname.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  count = length(local.tunnel_ingress) > 0 ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = local.tunnel_id

  config = {
    ingress = concat(
      [
        for hostname, service in local.tunnel_ingress : {
          hostname = hostname
          service  = service
        }
      ],
      # Catch-all REQUIRED at end of ingress list. Returns 404 for any
      # hostname not explicitly matched above.
      [
        {
          service = "http_status:404"
        }
      ],
    )
  }
}

output "tunnel_route_count" {
  description = "Number of tunnel ingress rules managed by tofu (excludes catch-all)"
  value       = length(local.tunnel_ingress)
}
