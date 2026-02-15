# Feature Millwork Infrastructure

## Network Equipment Inventory

### Current Equipment
| Device | Model | Location | Status |
|--------|-------|----------|--------|
| Telus Gateway | Actiontec T2200M | Network closet | Active - DHCP server (problem) |
| WiFi Router | Netgear AC1200 R6120 | Network closet | Active - Office WiFi |
| Main Switch | TRENDnet TEG-S24Dg | Network closet | Active - 24-port backbone |
| PoE Switch | TP-Link TL-SG1005P | Network closet | Active - Shop WiFi APs |
| Patch Panel | ~24 port passive | Wall mount | Passive - Cable org |
| Old NAS | D-Link DNS-323 | Network closet | Unused - obsolete |

### Known Issue: LAN Dies When Internet Dies
**Root Cause:** Actiontec T2200M handles DHCP. When WAN link drops, DHCP stops working and devices can't communicate.

**Solution:** Add dedicated router (TP-Link ER605) as DHCP server. T2200M becomes bridge-only.

## Target Network Topology

```
[TELUS WAN]
     │
[Actiontec T2200M] ← Bridge mode only
     │
[TP-Link ER605] ← NEW: DHCP + DNS + Firewall
     │
[Patch Panel]
     │
[TRENDnet TEG-S24Dg] ← 24-port backbone
     │
     ├── [Shop Floor devices, CNC, printers]
     ├── [TP-Link TL-SG1005P PoE] → Shop WiFi APs
     └── [Netgear R6120] → Office WiFi (AP mode)
```

## IP Address Plan

| Device | IP | Notes |
|--------|----|-------|
| ER605 Gateway | 192.168.1.1 | DHCP server |
| T2200M (bridged) | 192.168.1.254 | Modem only |
| Steve's PC | DHCP reservation | Current file server |
| Future Cambium server | 192.168.1.10 | Static |
| DHCP Range | 192.168.1.100-200 | Dynamic clients |

## Migration Steps (Zero Disruption)

1. **Before swap:** Screenshot T2200M DHCP config at 192.168.1.254
2. **Configure ER605 offline:** Same subnet, DHCP range, gateway IP as T2200M
3. **Swap:**
   - Unplug T2200M LAN cable from TRENDnet
   - Plug into ER605 LAN port
   - Plug ER605 WAN into T2200M
4. **Rollback:** If issues, unplug ER605, reconnect T2200M directly (30 seconds)

## Server Infrastructure

### Current State
- **File Server:** Steve's desktop (not ideal - offline when Steve leaves)
- **Cambium:** Hosted on Railway (PostgreSQL + Node.js)
- **D-Link DNS-323:** Obsolete - 64MB RAM, can't run Cambium

### Future State
- Mini PC (Beelink/MinisForum ~$200-300 CAD) for on-prem Cambium
- Railway remains production for now (reliable, no shop network dependency)

## Shop Details
- ~26 person millwork shop
- Equipment: CNC machines, printers, computers throughout
- WiFi coverage via PoE access points on shop floor
- Office WiFi via Netgear R6120
