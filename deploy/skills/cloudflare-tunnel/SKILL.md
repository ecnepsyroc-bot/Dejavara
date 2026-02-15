---
name: cloudflare-tunnel
description: Set up and manage Cloudflare tunnels for exposing local services to the internet. Use when needing to: (1) Add a domain to Cloudflare, (2) Create tunnels for services behind NAT/firewalls, (3) Configure DNS records for tunnels, (4) Connect services across different networks (home/office/shop).
---

# Cloudflare Tunnel Management

## Prerequisites

- Cloudflare API token with permissions:
  - Account > Account Settings > Read
  - Account > Cloudflare Tunnel > Edit
  - Zone > Zone > Edit
  - Zone > DNS > Edit
- Token stored at `~/.openclaw/secrets/cloudflare-token`

## Quick Reference

```bash
# Read token
CF_TOKEN=$(cat ~/.openclaw/secrets/cloudflare-token)

# Verify token
curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CF_TOKEN"

# Get account ID
curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer $CF_TOKEN"
```

## Workflow: Add Domain to Cloudflare

1. **Add zone:**
```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"name":"example.com","account":{"id":"ACCOUNT_ID"},"type":"full"}'
```

2. **Get nameservers from response** (e.g., `kate.ns.cloudflare.com`, `bob.ns.cloudflare.com`)

3. **User updates nameservers** at domain registrar (Squarespace, Google Domains, etc.)

4. **Check zone status:**
```bash
curl -s "https://api.cloudflare.com/client/v4/zones/ZONE_ID" \
  -H "Authorization: Bearer $CF_TOKEN" | grep -o '"status":"[^"]*"'
```
Status goes from `pending` → `active` when nameservers propagate (5-30 min typically).

## Workflow: Create Tunnel

1. **Create tunnel:**
```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"name":"my-tunnel","tunnel_secret":"'$(openssl rand -base64 32)'"}'
```

Save from response:
- `id` (tunnel ID)
- `credentials_file.TunnelSecret`
- `token` (for cloudflared)

2. **Create DNS CNAME pointing to tunnel:**
```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "gateway",
    "content": "TUNNEL_ID.cfargotunnel.com",
    "proxied": true
  }'
```

3. **Install cloudflared on host:**
```bash
# Linux arm64 (Raspberry Pi)
curl -L -o /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
chmod +x /tmp/cloudflared

# Other architectures: cloudflared-linux-amd64, cloudflared-darwin-amd64, etc.
```

4. **Create config file:**
```yaml
# /path/to/config.yml
tunnel: TUNNEL_ID
credentials-file: /path/to/creds.json

ingress:
  - hostname: gateway.example.com
    service: http://localhost:8080
  - service: http_status:404
```

5. **Create credentials file:**
```json
{
  "AccountTag": "ACCOUNT_ID",
  "TunnelID": "TUNNEL_ID",
  "TunnelSecret": "BASE64_SECRET"
}
```

6. **Run tunnel:**
```bash
/tmp/cloudflared tunnel --config /path/to/config.yml run
```

## Common Issues

### Nameserver propagation
- Can take 5 min to 48 hours
- Check with: `dig +short NS example.com`
- Zone status remains `pending` until propagated

### Tunnel shows "down"
- cloudflared not running
- Check: `curl -s "https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/cfd_tunnel" -H "Authorization: Bearer $CF_TOKEN"`

### Domain registered through Google Workspace
- Domain managed by Squarespace Domains (Google sold to Squarespace)
- Login at domains.squarespace.com with Google Workspace email
- Not the main squarespace.com account

## Stored Credentials

| Item | Location |
|------|----------|
| API Token | `~/.openclaw/secrets/cloudflare-token` |
| Tunnel Token | `~/.openclaw/secrets/tunnel-token` |
| Tunnel Config | `/tmp/cloudflared-config.yml` |
| Tunnel Creds | `/tmp/tunnel-creds.json` |

## See Also

- [references/api-examples.md](references/api-examples.md) - Full API response examples
- Cloudflare API docs: https://developers.cloudflare.com/api/
