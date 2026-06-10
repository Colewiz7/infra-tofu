# DNS records for colewiz.dev
# Public app hostnames route through the Cloudflare Tunnel (proxied CNAMEs).
# Game-server / direct-streaming hostnames use A records to the home IP.

locals {
  # Active tunnel: "colewiz-k8" (in-cluster cloudflared).
  # The previous "rit-server" tunnel (d7ee8051-...) was decommissioned;
  # records were recreated in the dashboard pointing at this tunnel,
  # so tofu state had to be re-imported. Verify the current tunnel ID:
  #   curl -H "Authorization: Bearer $CF_API_TOKEN" \
  #     "https://api.cloudflare.com/client/v4/accounts/$ACCT/cfd_tunnel" | jq
  tunnel_target = "1a1b02bd-09da-4d2b-a3e7-0c6bdb154a7e.cfargotunnel.com"

  # Subdomain → human-friendly description.
  # Bare names only; full hostname is constructed from var.primary_domain.
  # NOTE: `jellyfin` is intentionally absent — it uses an A record to the
  # home IP (see home_a_records below), and CF doesn't allow A + CNAME
  # at the same name.
  tunnel_subdomains = {
    ai        = "Open WebUI (Cole's Server)"
    amp       = "AMP game server manager"
    argocd    = "Argo CD UI"
    auth      = "Authentik SSO"
    bazarr    = "Bazarr subtitles"
    beszel    = "Beszel fleet monitoring"
    comfyui   = "ComfyUI image generation (planned)"
    files     = "Filebrowser Quantum"
    glance    = "Glance dashboard (planned)"
    grafana   = "Grafana dashboards"
    home      = "Homepage dashboard"
    immich    = "Immich photo/video backup"
    kai       = "Kai's Garden web"
    "kai-api" = "Kai's Garden sync API"
    lore      = "BookStack — analog horror lore (planned)"
    prowlarr  = "Prowlarr indexer manager"
    radarr    = "Radarr movie manager"
    recipe    = "Mealie recipes"
    request   = "Jellyseerr media requests"
    scripts   = "HedgeDoc — analog horror scripts (planned)"
    sonarr    = "Sonarr TV manager"
    torrent   = "qBittorrent WebUI"
  }

  # A records pointing at the home public IP (NOT tunnel-routed).
  # Used for game servers and Jellyfin (which prefers direct UDP/TCP
  # over tunnel for streaming throughput).
  home_a_records = {
    jellyfin = "Jellyfin media server (direct, not tunnel)"
    mc       = "Minecraft server"
    vs       = "Vintage Story server"
  }
  home_public_ip = "74.77.244.136"
}

# One CNAME per subdomain, all routing through the tunnel
resource "cloudflare_dns_record" "tunnel" {
  for_each = local.tunnel_subdomains

  zone_id = var.cloudflare_zone_id
  name    = "${each.key}.${var.primary_domain}"
  type    = "CNAME"
  content = local.tunnel_target
  proxied = true
  ttl     = 1 # 1 = "auto" when proxied
  comment = each.value
}

# Apex record (colewiz.dev itself) routed through the tunnel.
# Cloudflare flattens CNAMEs at the apex when proxied, so a CNAME here
# is valid even though apex CNAMEs are forbidden by RFC 1034.
resource "cloudflare_dns_record" "apex" {
  zone_id = var.cloudflare_zone_id
  name    = var.primary_domain
  type    = "CNAME"
  content = local.tunnel_target
  proxied = true
  ttl     = 1
  comment = "Apex domain — colewiz.dev website"
}

# A records to home public IP (game servers + Jellyfin direct).
# Not proxied: tunnel can't carry game UDP / Jellyfin direct streaming.
resource "cloudflare_dns_record" "home_a" {
  for_each = local.home_a_records

  zone_id = var.cloudflare_zone_id
  name    = "${each.key}.${var.primary_domain}"
  type    = "A"
  content = local.home_public_ip
  proxied = false
  ttl     = 300
  comment = each.value
}

# Outputs: easy reference for downstream modules / docs

output "tunnel_hostnames" {
  description = "All public hostnames routed via Cloudflare Tunnel"
  value = concat(
    [var.primary_domain],
    [for k, _ in local.tunnel_subdomains : "${k}.${var.primary_domain}"],
  )
}

output "home_a_hostnames" {
  description = "Hostnames routed directly to the home public IP (no tunnel)"
  value       = [for k, _ in local.home_a_records : "${k}.${var.primary_domain}"]
}
