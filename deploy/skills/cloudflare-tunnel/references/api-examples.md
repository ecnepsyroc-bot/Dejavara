# Cloudflare API Response Examples

## Token Verification Response
```json
{
  "result": {
    "id": "ede5ebbc28b34f24382e3ffd88b24aad",
    "status": "active"
  },
  "success": true,
  "errors": [],
  "messages": [{
    "code": 10000,
    "message": "This API Token is valid and active"
  }]
}
```

## Account List Response
```json
{
  "result": [{
    "id": "d3ce6659272944957081d5455ce4ab99",
    "name": "user@example.com's Account",
    "type": "standard"
  }],
  "success": true
}
```

## Zone Creation Response
```json
{
  "result": {
    "id": "36fbc1195fd808b929086c899b55b630",
    "name": "example.com",
    "status": "pending",
    "name_servers": [
      "katelyn.ns.cloudflare.com",
      "rohin.ns.cloudflare.com"
    ],
    "original_name_servers": [
      "ns-cloud-d1.googledomains.com",
      "ns-cloud-d2.googledomains.com"
    ],
    "original_registrar": "squarespace domains ii llc"
  },
  "success": true
}
```

## Tunnel Creation Response
```json
{
  "result": {
    "id": "ffd4e119-fecc-460e-91ee-bb5a38a010bf",
    "name": "my-tunnel",
    "status": "inactive",
    "credentials_file": {
      "AccountTag": "d3ce6659272944957081d5455ce4ab99",
      "TunnelID": "ffd4e119-fecc-460e-91ee-bb5a38a010bf",
      "TunnelSecret": "BASE64_ENCODED_SECRET"
    },
    "token": "eyJhI..."
  },
  "success": true
}
```

## Tunnel List Response
```json
{
  "result": [{
    "id": "ffd4e119-fecc-460e-91ee-bb5a38a010bf",
    "name": "my-tunnel",
    "status": "healthy",
    "connections": [{
      "colo_name": "SEA",
      "is_pending_reconnect": false
    }]
  }],
  "success": true
}
```

## DNS Record Creation Response
```json
{
  "result": {
    "id": "047d5f1d05e34262cfec28e32e53995c",
    "name": "gateway.example.com",
    "type": "CNAME",
    "content": "ffd4e119-fecc-460e-91ee-bb5a38a010bf.cfargotunnel.com",
    "proxied": true,
    "ttl": 1
  },
  "success": true
}
```

## Zone Status Values
- `pending` - Waiting for nameserver verification
- `active` - Domain is active on Cloudflare
- `moved` - Domain moved to another account
- `deleted` - Domain deleted

## Tunnel Status Values
- `inactive` - Tunnel created but no connections
- `healthy` - Tunnel connected and working
- `down` - Tunnel has no active connections
- `degraded` - Some connections failing
