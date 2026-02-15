#!/bin/bash
# Cloudflare Tunnel Helper Script
# Usage: cf-tunnel.sh <command> [args]

set -e

TOKEN_FILE="${HOME}/.openclaw/secrets/cloudflare-token"
CF_API="https://api.cloudflare.com/client/v4"

# Load token
if [ -f "$TOKEN_FILE" ]; then
    CF_TOKEN=$(cat "$TOKEN_FILE")
else
    echo "Error: Token file not found at $TOKEN_FILE"
    exit 1
fi

cmd_verify() {
    curl -s -X GET "$CF_API/user/tokens/verify" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json"
}

cmd_accounts() {
    curl -s -X GET "$CF_API/accounts" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json"
}

cmd_zones() {
    curl -s -X GET "$CF_API/zones" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json"
}

cmd_zone_status() {
    local zone_id=$1
    if [ -z "$zone_id" ]; then
        echo "Usage: cf-tunnel.sh zone-status <zone_id>"
        exit 1
    fi
    curl -s -X GET "$CF_API/zones/$zone_id" \
        -H "Authorization: Bearer $CF_TOKEN" | grep -o '"status":"[^"]*"'
}

cmd_tunnels() {
    local account_id=$1
    if [ -z "$account_id" ]; then
        echo "Usage: cf-tunnel.sh tunnels <account_id>"
        exit 1
    fi
    curl -s -X GET "$CF_API/accounts/$account_id/cfd_tunnel" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json"
}

cmd_add_zone() {
    local domain=$1
    local account_id=$2
    if [ -z "$domain" ] || [ -z "$account_id" ]; then
        echo "Usage: cf-tunnel.sh add-zone <domain> <account_id>"
        exit 1
    fi
    curl -s -X POST "$CF_API/zones" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"name\":\"$domain\",\"account\":{\"id\":\"$account_id\"},\"type\":\"full\"}"
}

cmd_create_tunnel() {
    local name=$1
    local account_id=$2
    if [ -z "$name" ] || [ -z "$account_id" ]; then
        echo "Usage: cf-tunnel.sh create-tunnel <name> <account_id>"
        exit 1
    fi
    local secret=$(openssl rand -base64 32)
    curl -s -X POST "$CF_API/accounts/$account_id/cfd_tunnel" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"name\":\"$name\",\"tunnel_secret\":\"$secret\"}"
}

cmd_add_dns() {
    local zone_id=$1
    local hostname=$2
    local tunnel_id=$3
    if [ -z "$zone_id" ] || [ -z "$hostname" ] || [ -z "$tunnel_id" ]; then
        echo "Usage: cf-tunnel.sh add-dns <zone_id> <hostname> <tunnel_id>"
        exit 1
    fi
    curl -s -X POST "$CF_API/zones/$zone_id/dns_records" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"CNAME\",\"name\":\"$hostname\",\"content\":\"$tunnel_id.cfargotunnel.com\",\"proxied\":true}"
}

cmd_help() {
    echo "Cloudflare Tunnel Helper"
    echo ""
    echo "Commands:"
    echo "  verify                           - Verify API token"
    echo "  accounts                         - List accounts"
    echo "  zones                            - List zones"
    echo "  zone-status <zone_id>            - Check zone status"
    echo "  tunnels <account_id>             - List tunnels"
    echo "  add-zone <domain> <account_id>   - Add domain to Cloudflare"
    echo "  create-tunnel <name> <account_id> - Create new tunnel"
    echo "  add-dns <zone_id> <host> <tunnel_id> - Add DNS record for tunnel"
}

case "$1" in
    verify) cmd_verify ;;
    accounts) cmd_accounts ;;
    zones) cmd_zones ;;
    zone-status) cmd_zone_status "$2" ;;
    tunnels) cmd_tunnels "$2" ;;
    add-zone) cmd_add_zone "$2" "$3" ;;
    create-tunnel) cmd_create_tunnel "$2" "$3" ;;
    add-dns) cmd_add_dns "$2" "$3" "$4" ;;
    *) cmd_help ;;
esac
