# Workstation Operations — DEJAVARA (Lenovo ThinkPad)

## Hardware

| Spec | Value |
|------|-------|
| CPU | Intel i9-13950HX (24 cores / 32 threads) |
| TDP | 55W base / 157W turbo |
| RAM | (check `wmic memorychip get capacity`) |
| Battery | 93,530 mWh design / LiPo / SMP 5B11H56391 |
| OS | Windows 11 Pro |
| Sleep type | Modern Standby (S0 Low Power Idle), NOT S3 |

## Power Configuration

### Active power plan: Balanced

GUID: `381b4222-f694-41f0-9685-ff5bb260df2e`

### Lid Close Actions (Fixed 2026-02-20)

| Setting | Value | Code |
|---------|-------|------|
| On battery (DC) | **Hibernate** | 2 |
| Plugged in (AC) | **Sleep** | 1 |

**Why:** Previously both were set to "Do Nothing" (code 0) to keep the machine
accessible. This caused the laptop to run at full power inside a closed backpack,
leading to dangerous overheating.

**Hibernate vs Sleep:** This machine uses Modern Standby (S0), not traditional S3
sleep. Modern Standby keeps the CPU in low-power idle with network connected —
background tasks, sync, and updates can still run and generate heat. Hibernate
writes RAM to disk and fully powers off, making it safe for transport.

### Changing lid close actions

Requires an elevated (admin) PowerShell prompt:

```powershell
# Lid close GUID path:
#   Subgroup: 4f971e89-eebd-4455-a8de-9e59040e7347 (Power buttons and lid)
#   Setting:  5ca83367-6e45-459f-a27b-476b1d01c936 (Lid close action)

# Values: 0=Do Nothing, 1=Sleep, 2=Hibernate, 3=Shut Down

# Set lid close on battery to Hibernate
powercfg /setdcvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 2

# Set lid close on AC to Sleep
powercfg /setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 1

# Apply changes
powercfg /setactive SCHEME_CURRENT
```

### Verifying current settings

```powershell
# Check registry directly (no admin needed)
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\381b4222-f694-41f0-9685-ff5bb260df2e\4f971e89-eebd-4455-a8de-9e59040e7347\5ca83367-6e45-459f-a27b-476b1d01c936"
# ACSettingIndex: 0x1 = Sleep, DCSettingIndex: 0x2 = Hibernate
```

### Battery health report

```powershell
powercfg /batteryreport /output battery-report.html
```

### Sleep/hibernate settings (current)

| Setting | AC (plugged in) | DC (battery) |
|---------|-----------------|--------------|
| Sleep after | Never | 5 minutes |
| Hibernate after | Never | 5 hours |
| Wake timers | Enabled | Disabled |

## Modern Standby Notes

This machine only supports S0 Low Power Idle (Modern Standby). Traditional S3
sleep is not available (disabled by firmware + Device Guard). Key implications:

- "Sleep" still keeps the CPU partially awake and network connected
- Background tasks, Windows Update, and sync services can wake the machine
- In an enclosed space (bag), even Modern Standby can generate enough heat to
  be concerning over long periods
- **For transport: always use Hibernate, not Sleep**
- Hybrid Sleep is not available (requires S3)

## Troubleshooting

### Laptop overheating in bag

1. Check lid close action: `reg query "HKLM\SYSTEM\...\5ca83367..."` (see above)
2. DC value should be `0x2` (Hibernate), not `0x0` (Do Nothing)
3. If reset by Windows Update or power plan change, re-apply with admin commands above

### Battery report shows unexpected drain

```powershell
# Generate detailed report
powercfg /batteryreport /duration 7
# Check sleep study (Modern Standby drain analysis)
powercfg /sleepstudy
```
