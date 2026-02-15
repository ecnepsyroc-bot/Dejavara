# Network Audit Report — Feature Millwork Inc.

**Initial Audit:** 2026-02-09
**ER605 Cutover:** 2026-02-10
**Machine:** Dejavara (Windows, Lenovo P16)
**Location:** Coquitlam, BC

---

## Device Credentials (FILL IN BY HAND — DELETE AFTER PRINTING)

| Device | Admin URL | Username | Password |
|---|---|---|---|
| ER605 VPN Gateway | http://192.168.0.1 | ______________ | ______________ |
| TP-Link TL-SG105E Switch | http://192.168.0.2 | ______________ | ______________ |
| Netgear R6120 WiFi | http://10.253.15.125 | ______________ | ______________ |
| Telus T2200M Modem | http://192.168.1.254 (?) | ______________ | ______________ |
| Telus WEB6000Q WiFi AP | http://192.168.0.105 | ______________ | ______________ |
| Teltonika Router | http://23.16.85.92 | ______________ | ______________ |
| FileServe NAS | http://192.168.0.32 | ______________ | ______________ |
| Canon Downstairs | http://192.168.0.98 | Dept ID: ______ | PIN: _________ |
| Canon Upstairs | http://192.168.0.99 | Dept ID: ______ | PIN: _________ |
| Ricoh Plotter | http://192.168.0.150 | ______________ | ______________ |

⚠️ **SECURITY: Delete this section from any digital copies. Keep only one printed copy in a secure location.**

---

## Current Network Status (Post-Cutover)

The TP-Link ER605 VPN Gateway is live as the shop's LAN gateway and DHCP server. The LAN operates independently of the internet connection — verified by kill test (WAN cable unplugged, LAN devices remained reachable).

### ER605 Configuration

| Setting | Value |
|---|---|
| LAN IP | 192.168.0.1 |
| Subnet Mask | 255.255.255.0 |
| DHCP Pool | 192.168.0.50 – 192.168.0.199 |
| Lease Time | 1440 minutes (24 hours) |
| Primary DNS | 1.1.1.1 (Cloudflare) |
| Secondary DNS | 8.8.8.8 (Google) |
| DNS Suffix | lan |
| WAN | Connected to Telus T2200M LAN port |

### DHCP Reservations

| ID | MAC | IP | Description | Notes |
|---|---|---|---|---|
| 1 | 00-11-D8-41-2A-B1 | 192.168.0.30 | Morbidelli Router (CNC) | Windows XP, N: → \\\\FILESERVE\\Data |
| 2 | 94-C6-91-BE-D5-24 | 192.168.0.31 | Beam Saw (CNC) | Hostname: SELCOSK4, N: → \\\\FILESERVE\\Data |
| 3 | 5C-D9-98-0B-00-FA | 192.168.0.32 | FileServe NAS | D-Link DNS-series, SMB/LPD |
| 4 | 00-50-BA-C8-C7-4B | 192.168.0.44 | D-Link NAS | NetBIOS only, older unit |
| 5 | 9C-32-CE-00-AE-2E | 192.168.0.98 | Canon Downstairs | iR-ADV C3525 III |
| 6 | 9C-32-CE-01-F9-3B | 192.168.0.99 | Canon Upstairs | iR-ADV C3525 III |
| 7 | 00-E0-4C-68-01-29 | 192.168.0.100 | Dejavara | Cory's Lenovo P16 |
| 8 | 10-78-5B-0F-F4-80 | 192.168.0.105 | Telus WEB6000Q | WiFi AP (WiFiPlus0453) |
| 9 | 2C-98-11-7B-B9-29 | 192.168.0.118 | Brother HL-L2465DW | Laser printer |
| 10 | 14-59-C0-B9-A3-F9 | 192.168.0.126 | R6120 | Netgear WiFi router (WAN side) |
| 11 | 00-26-73-33-71-97 | 192.168.0.150 | Ricoh Plotter | MPW7140EN-KO, wide-format |

### IP Address Scheme

| Range | Purpose |
|---|---|
| 192.168.0.1 | ER605 gateway |
| 192.168.0.2 | TP-Link TL-SG105E managed switch (phone system) |
| 192.168.0.3 – .29 | Reserved (future static devices) |
| 192.168.0.30 – .31 | CNC machines (DHCP reservations) |
| 192.168.0.32 – .49 | NAS and infrastructure (reservations) |
| 192.168.0.50 – .199 | DHCP pool (desktops, laptops, phones, other) |
| 192.168.0.200 – .254 | Reserved (manual static assignments) |

---

## Physical Topology (Current)

```
INTERNET (Telus Fibre)
    │
[Telus T2200M] Modem (bridge mode, 23.16.85.x passthrough)
    │
    ├── WAN → [TP-Link ER605] VPN Gateway (192.168.0.1)
    │              │
    │              ├── LAN Port 4 → [TRENDnet TEG-S24Dg] 24-port backbone switch
    │              │                    │
    │              │                    ├── [TP-Link TL-SG105E] desk switch (.2) — phone system
    │              │                    ├── [TP-Link TL-SG1005P] PoE switch → shop floor WiFi APs
    │              │                    ├── [Telus WEB6000Q] WiFi AP (.105) — SSID: WiFiPlus0453
    │              │                    ├── Canon Downstairs (.98)
    │              │                    ├── Canon Upstairs (.99)
    │              │                    ├── Ricoh Plotter (.150)
    │              │                    ├── FileServe NAS (.32)
    │              │                    ├── D-Link NAS (.44)
    │              │                    ├── Morbidelli CNC (.30)
    │              │                    ├── Beam Saw CNC (.31)
    │              │                    ├── Brother Printer (.118)
    │              │                    ├── Desktops (DHCP .50–.199)
    │              │                    └── 11x Polycom phones (DHCP, various in .101–.119)
    │              │
    │              └── LAN Port 5 → [Netgear R6120] WiFi router (.126 WAN side)
    │                                    └── WiFi clients on 10.253.15.x (Feature / Feature-5G)
    │
    └── LAN → [Teltonika] Cellular router (23.16.85.92)
                   └── IP Camera (.146), other devices

ER605 Port Assignment:
    Port 1 (WAN)  → T2200M
    Port 4 (LAN)  → TRENDnet switch
    Port 5 (LAN)  → Netgear R6120 WiFi router
    Ports 2-3 (WAN/LAN) → Unused (default WAN mode)
```

---

## DHCP Client List (2026-02-10, 28 clients)

### Desktops & Laptops

| Client Name | MAC | IP | Notes |
|---|---|---|---|
| Dejavara | 00-E0-4C-68-01-29 | 192.168.0.100 | Cory's Lenovo P16 |
| Sean | 24-4B-FE-4A-2E-D5 | 192.168.0.123 | Sean's desktop |
| Cory-s | 74-46-A0-C1-1A-49 | 192.168.0.122 | Cory's second machine? |
| DESKTOP-CDEUJDR | 04-42-1A-06-B0-21 | 192.168.0.121 | Unknown desktop |
| LOU | 00-01-2E-82-CA-C9 | 192.168.0.120 | Lou's desktop |
| Server | C8-7F-54-CF-8E-BB | 192.168.0.116 | PC named "Server" |
| Amanda-11227 | 88-B9-45-6E-D6-FE | 192.168.0.115 | Amanda's desktop |
| cambium | 24-4B-FE-4A-2E-B8 | 192.168.0.108 | Cambium dev machine |

### CNC Machines

| Client Name | MAC | IP | Lease | Notes |
|---|---|---|---|---|
| scm-b9b17d8a927 | 00-11-D8-41-2A-B1 | 192.168.0.30 | Permanent | Morbidelli Author 600K |
| SELCOSK4 | 94-C6-91-BE-D5-24 | 192.168.0.31 | Permanent | Beam Saw |

### Phones (Polycom VoIP — 11 units)

| Client Name | MAC | IP |
|---|---|---|
| Polycom64167fe07a2f | 64-16-7F-E0-7A-2F | 192.168.0.119 |
| Polycom64167fe07a2e | 64-16-7F-E0-7A-2E | 192.168.0.117 |
| Polycom64167fe076d6 | 64-16-7F-E0-76-D6 | 192.168.0.114 |
| Polycom64167fe03268 | 64-16-7F-E0-32-68 | 192.168.0.112 |
| Polycom64167fe07709 | 64-16-7F-E0-77-09 | 192.168.0.111 |
| Polycom64167fe07a25 | 64-16-7F-E0-7A-25 | 192.168.0.110 |
| Polycom64167fe07740 | 64-16-7F-E0-77-40 | 192.168.0.106 |
| Polycom64167fe07432 | 64-16-7F-E0-74-32 | 192.168.0.104 |
| Polycom64167fe076d2 | 64-16-7F-E0-76-D2 | 192.168.0.103 |
| Polycom64167fe07430 | 64-16-7F-E0-74-30 | 192.168.0.102 |
| Polycom64167fe07a27 | 64-16-7F-E0-7A-27 | 192.168.0.101 |

### Network Infrastructure

| Client Name | MAC | IP | Notes |
|---|---|---|---|
| R6120 | 14-59-C0-B9-A3-F9 | 192.168.0.126 | Netgear WiFi router (WAN side) |
| WiFiPlus | 10-78-5B-0F-F4-80 | 192.168.0.105 | Telus WEB6000Q WiFi AP |

### Printers

| Client Name | MAC | IP | Notes |
|---|---|---|---|
| BRW2C98117BB929 | 2C-98-11-7B-B9-29 | 192.168.0.118 | Brother HL-L2465DW — now found! |

### Mobile / Other

| Client Name | MAC | IP | Notes |
|---|---|---|---|
| pinossnewIPad2 | 50-F2-65-61-8E-27 | 192.168.0.125 | Pino's iPad |
| iPhone | E6-89-07-43-69-86 | 192.168.0.124 | Unknown iPhone |
| Os-iPhone | E0-BD-A0-55-A7-54 | 192.168.0.109 | Unknown iPhone |
| ea1-000FFF95A250 | 00-0F-FF-95-A2-50 | 192.168.0.113 | Unknown device |

---

## CNC Machine Details

### Morbidelli Author 600K (Router)

| Field | Value |
|---|---|
| Hostname | scm-b9b17d8a927 |
| OS | Windows XP (Version 5.1.2600) |
| Software | Xilog3MMI-RoutoLink |
| NIC | Marvell Yukon 88E8001/8003/8010 PCI Gigabit Ethernet |
| MAC | 00-11-D8-41-2A-B1 |
| IP Mode | DHCP → Reserved at 192.168.0.30 |
| Network Drive | N: → \\\\FILESERVE\\Data |
| Monitor | BenQ |
| File Type | PGM |

### Beam Saw (SELCOSK4)

| Field | Value |
|---|---|
| Hostname | SELCOSK4 |
| User | xp600 |
| NIC | Realtek PCIe GbE Family Controller #2 |
| MAC | 94-C6-91-BE-D5-24 |
| IP Mode | DHCP → Reserved at 192.168.0.31 |
| Network Drive | N: → \\\\FILESERVE\\Data |

Both CNC machines pull cut programs from FileServe NAS at 192.168.0.32 via mapped N: drive.

---

## WiFi Networks

### WiFiPlus0453 (Telus WEB6000Q) — ON SHOP SUBNET ✅

| Field | Value |
|---|---|
| Device | Telus WEB6000Q |
| Firmware | 1.1.02.32 |
| IP | 192.168.0.105 (DHCP from ER605) |
| MAC | 10-78-5B-0F-F4-80 |
| 2.4GHz SSID | WiFiPlus0453-2.4G |
| 5GHz SSID | WiFiPlus0453-5G |
| Security | WPA2 |
| Uptime | 50+ days |
| Can print? | ✅ Yes — same subnet as printers |

### Feature / Feature-5G (Netgear R6120) — ISOLATED SUBNET ❌

| Field | Value |
|---|---|
| Device | Netgear R6120 |
| WAN MAC | 14-59-C0-B9-A3-F9 |
| WAN IP | 192.168.0.126 (DHCP from ER605) |
| LAN Subnet | 10.253.15.0/24 |
| LAN Gateway | 10.253.15.125 |
| Admin URL | http://10.253.15.125 (WiFi side only) |
| Internet? | ✅ Working (through ER605) |
| Can print? | ❌ No — different subnet from printers |
| TODO | Switch to AP mode to unify onto 192.168.0.x |

---

## Link-Local Devices — Fully Identified (Pre vs Post Cutover)

| Pre-Cutover APIPA IP | MAC | Post-Cutover Identity | DHCP IP |
|---|---|---|---|
| 169.254.45.142 | 00-01-2E-82-CA-C9 | LOU (desktop) | 192.168.0.120 |
| 169.254.62.130 | 04-42-1A-06-B0-21 | DESKTOP-CDEUJDR | 192.168.0.121 |
| 169.254.63.174 | 00-11-D8-41-2A-B1 | Morbidelli CNC | 192.168.0.30 |
| 169.254.71.237 | C8-7F-54-CF-8E-BB | Server | 192.168.0.116 |
| 169.254.71.245 | 94-C6-91-BE-D5-24 | Beam Saw (SELCOSK4) | 192.168.0.31 |
| 169.254.137.17 | 2C-98-11-7B-B9-29 | Brother Printer | 192.168.0.118 |
| 169.254.151.26 | 24-4B-FE-4A-2E-D5 | Sean (desktop) | 192.168.0.123 |
| 169.254.163.92 | 74-46-A0-C1-1A-49 | Cory-s | 192.168.0.122 |
| 169.254.189.197 | 24-4B-FE-4A-2E-B8 | cambium | 192.168.0.108 |

All 9 link-local devices now have proper DHCP leases. ✅

---

## Verification Tests (2026-02-10)

### DHCP Test (ER605 standalone)
- Dejavara received 192.168.0.100 from ER605 ✅
- Gateway: 192.168.0.1, DNS suffix: lan ✅

### Connectivity Test (post-cutover, from TRENDnet)
| Target | Result | Latency |
|---|---|---|
| 192.168.0.98 (Canon Down) | ✅ | 1ms |
| 192.168.0.99 (Canon Up) | ✅ | 1ms |
| 192.168.0.150 (Ricoh) | ✅ | 1ms |
| 192.168.0.2 (TP-Link switch) | ✅ | 3ms |
| 8.8.8.8 (Internet) | ✅ | 14ms |

### Kill Test — LAN Independence
- WAN cable unplugged from ER605
- Ping to 192.168.0.98: ✅ (0ms, 0% loss)
- **LAN operates independently of internet** ✅

---

## Security Observations

1. **Ricoh FTP/Telnet open** — .150 has FTP and Telnet open with guest web access
2. **IP Camera HTTP only** — 23.16.85.146 unencrypted management UI
3. **FileServe NAS GoAhead-Webs** — .32 has historical CVEs
4. **CNC machines on Windows XP** — EOL since 2014, no patches
5. **Proxy ARP on 23.16.85.0/24** — Teltonika masks device MACs
6. **Feature WiFi double-NAT** — Netgear behind ER605, potential issues
7. **TP-Link switch default password** — admin/admin after reset

---

## Outstanding Tasks

- [ ] Switch Netgear R6120 to AP mode (fix printing from Feature WiFi)
- [x] Add DHCP reservation for Brother printer (2C-98-11-7B-B9-29 → .118)
- [x] Add DHCP reservation for Dejavara (00-E0-4C-68-01-29 → .100)
- [x] Add DHCP reservation for R6120 (14-59-C0-B9-A3-F9 → .126)
- [x] Add DHCP reservation for WEB6000Q (10-78-5B-0F-F4-80 → .105)
- [ ] Locate Telus WEB6000Q physically (on TRENDnet switch somewhere)
- [ ] Identify ea1-000FFF95A250 (.113) and DESKTOP-CDEUJDR (.121)
- [ ] Add DHCP reservations for key desktops
- [ ] Change TP-Link switch admin password
- [ ] Assess Ricoh FTP/Telnet — disable if not needed
- [ ] Find remaining printers: Pino's, accounting's, Pitney Bowes
- [ ] Document Polycom phone system (11 phones, hosted PBX?)
- [ ] Switch accountant to WiFiPlus0453 for printing (interim fix)
- [ ] Reconfigure ER605 ports 2-3 to LAN if needed

---

## Equipment Inventory

| Device | Model | Role | IP | Location |
|---|---|---|---|---|
| Modem | Telus T2200M | Fibre modem / bridge | — | Server closet |
| Router | TP-Link ER605 | LAN gateway / DHCP | 192.168.0.1 | Server closet |
| Backbone Switch | TRENDnet TEG-S24Dg | 24-port gigabit | — | Server closet |
| Desk Switch | TP-Link TL-SG105E | 5-port (phone system) | 192.168.0.2 | Desk area |
| PoE Switch | TP-Link TL-SG1005P | WiFi AP power | — | Server closet |
| WiFi AP | Telus WEB6000Q | WiFi (WiFiPlus0453) | 192.168.0.105 | Unknown |
| WiFi Router | Netgear R6120 | WiFi (Feature) | .126 WAN | Server closet |
| Cellular Router | Teltonika RUT/RUTX | Backup internet | 23.16.85.92 | Server closet |
| NAS | D-Link "FileServe" | CNC + office files | 192.168.0.32 | Server closet |
| NAS | D-Link (old) | Unknown | 192.168.0.44 | Server closet |
| Printer | Canon iR-ADV C3525 III | MFP downstairs | 192.168.0.98 | Downstairs |
| Printer | Canon iR-ADV C3525 III | MFP upstairs | 192.168.0.99 | Upstairs |
| Plotter | Ricoh MPW7140EN-KO | Wide-format 36" | 192.168.0.150 | Downstairs |
| Printer | Brother HL-L2465DW | Laser | 192.168.0.118 | Unknown |
| CNC | Morbidelli Author 600K | Router | 192.168.0.30 | Shop floor |
| CNC | Beam Saw (SELCOSK4) | Panel saw | 192.168.0.31 | Shop floor |
| Phones | Polycom x11 | VoIP | .101–.119 | Throughout |