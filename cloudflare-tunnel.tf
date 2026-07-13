# Tunnel ingress routes (which hostname → which backend).
# This is the source of truth — tofu owns these now. To add a new
# public app: append an entry to `tunnel_ingress` here AND to
# `tunnel_subdomains` in cloudflare-dns.tf, then plan + apply.
#
# DO NOT edit routes in the Cloudflare dashboard — tofu will revert.
#
# Verify the active tunnel ID after any tunnel rebuild:
#   curl -H "Authorization: Bearer $CF_API_TOKEN" \
#     "https://api.cloudflare.com/client/v4/accounts/$ACCT/cfd_tunnel" | jq

locals {
  # Active tunnel: "colewiz-k8" (cloudflared in k3s).
  tunnel_id = "1a1b02bd-09da-4d2b-a3e7-0c6bdb154a7e"

  # hostname → backend service URL. Simple cases only — hostnames whose
  # origin needs TLS/header overrides go in tunnel_origin_overrides below.
  tunnel_ingress = {
    "ai.colewiz.dev"       = "http://open-webui.ai.svc.cluster.local:80"
    "amp.colewiz.dev"      = "http://10.10.10.201:8080"
    "argocd.colewiz.dev"   = "https://argo-cd-argocd-server.argocd.svc.cluster.local:443"
    "auth.colewiz.dev"     = "http://authentik-server.authentik.svc.cluster.local:80"
    "cloud.colewiz.dev"    = "http://nextcloud.nextcloud.svc.cluster.local:80"
    "bazarr.colewiz.dev"   = "http://bazarr.media.svc.cluster.local:6767"
    "beszel.colewiz.dev"   = "http://beszel.beszel.svc.cluster.local:8090"
    "colewiz.dev"          = "http://website.website.svc.cluster.local:80"
    "files.colewiz.dev"    = "http://filebrowser.filebrowser.svc.cluster.local:80"
    "grafana.colewiz.dev"  = "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80"
    "home.colewiz.dev"     = "http://homepage.homepage.svc.cluster.local:80"
    "immich.colewiz.dev"   = "http://immich-server.immich.svc.cluster.local:2283"
    "kai.colewiz.dev"      = "http://kais-garden-web.kais-garden.svc.cluster.local:80"
    "kai-api.colewiz.dev"  = "http://kais-garden-api.kais-garden.svc.cluster.local:80"
    "ntfy.colewiz.dev"     = "http://ntfy.ntfy.svc.cluster.local:80"
    "prowlarr.colewiz.dev" = "http://prowlarr.media.svc.cluster.local:9696"
    "radarr.colewiz.dev"   = "http://radarr.media.svc.cluster.local:7878"
    "recipe.colewiz.dev"   = "http://mealie.mealie.svc.cluster.local:80"
    "request.colewiz.dev"  = "http://jellyseerr.media.svc.cluster.local:5055"
    "sonarr.colewiz.dev"   = "http://sonarr.media.svc.cluster.local:8989"
    "torrent.colewiz.dev"  = "http://qbittorrent.downloads.svc.cluster.local:8080"
  }

  # Per-hostname origin_request overrides. Add an entry here when an
  # HTTPS origin needs TLS settings, a custom Host header, etc.
  tunnel_origin_overrides = {
    # argocd-server's ClusterIP TLS cert is self-signed and uses the
    # in-cluster service name as CN; tunnel must skip verification and
    # send the right SNI to avoid 502s.
    "argocd.colewiz.dev" = {
      no_tls_verify      = true
      origin_server_name = "argo-cd-argocd-server.argocd.svc.cluster.local"
    }
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab" {
  account_id = var.cloudflare_account_id
  tunnel_id  = local.tunnel_id

  config = {
    ingress = concat(
      [
        for hostname, service in local.tunnel_ingress : merge(
          {
            hostname = hostname
            service  = service
          },
          contains(keys(local.tunnel_origin_overrides), hostname) ? {
            origin_request = local.tunnel_origin_overrides[hostname]
          } : {}
        )
      ],
      # Catch-all REQUIRED at end of ingress list. Returns 404 for any
      # hostname not matched above.
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
