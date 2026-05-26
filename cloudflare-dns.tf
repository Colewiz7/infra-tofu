# DNS records for colewiz.dev
# All public hostnames route through the Cloudflare Tunnel.
# Add a hostname by appending to the `tunnel_subdomains` list.

locals {
  # Tunnel CNAME content
  tunnel_target = "d7ee8051-29da-48d8-9259-d04ad4785134.cfargotunnel.com"

  # Subdomain → human-friendly description
  # Bare names only; full hostname is constructed from var.primary_domain
  tunnel_subdomains = {
    amp      = "AMP game server manager"
    auth     = "Authentik SSO"
    comfyui  = "ComfyUI image generation"
    files    = "Filebrowser Quantum"
    glance   = "Glance dashboard"
    home     = "Homepage"
    jellyfin = "Jellyfin media server"
    lore     = "BookStack (analog horror lore)"
    recipe   = "Mealie recipes"
    request  = "Jellyseerr media requests"
    scripts  = "HedgeDoc (analog horror scripts)"
    torrent  = "qBittorrent WebUI"
  }
}

# One CNAME per subdomain, all routing through the tunnel
resource "cloudflare_dns_record" "tunnel" {
  for_each = local.tunnel_subdomains

  zone_id = var.cloudflare_zone_id
  name    = "${each.key}.${var.primary_domain}"
  type    = "CNAME"
  content = local.tunnel_target
  proxied = true
  ttl     = 1  # 1 = "auto" when proxied
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
  comment = "Apex domain — test website (index-1 at /, index-2 at /alt)"
}

# Output: easy reference for downstream modules / other tools
output "tunnel_hostnames" {
  description = "All public hostnames managed by tofu, routed via Cloudflare Tunnel"
  value = concat(
    [var.primary_domain],
    [for k, _ in local.tunnel_subdomains : "${k}.${var.primary_domain}"],
  )
}
