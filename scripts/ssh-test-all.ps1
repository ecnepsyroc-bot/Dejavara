# SSH Connection Tester
# Tests all configured SSH hosts and reports status

param(
    [switch]$Verbose
)

$hosts = @(
    @{Name="cambium-server"; Timeout=3; Description="Shop server (LAN)"},
    @{Name="cambium-server-tunnel"; Timeout=10; Description="Shop server (Cloudflare)"},
    @{Name="phteah-pi"; Timeout=3; Description="Home Pi"}
)

Write-Host "`n🔐 SSH Connection Status" -ForegroundColor Cyan
Write-Host "─" * 50

foreach ($h in $hosts) {
    Write-Host -NoNewline "  $($h.Name) "
    Write-Host -NoNewline "($($h.Description)): " -ForegroundColor DarkGray

    if ($Verbose) {
        $result = ssh -v -o ConnectTimeout=$($h.Timeout) -o BatchMode=yes -o StrictHostKeyChecking=accept-new $h.Name "hostname" 2>&1
    } else {
        $result = ssh -o ConnectTimeout=$($h.Timeout) -o BatchMode=yes -o StrictHostKeyChecking=accept-new $h.Name "hostname" 2>&1
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $result" -ForegroundColor Green
    } else {
        $errorMsg = if ($result -match "timed out") { "Timeout" }
                   elseif ($result -match "refused") { "Refused" }
                   elseif ($result -match "Permission denied") { "Auth failed" }
                   else { "Failed" }
        Write-Host "❌ $errorMsg" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "     $result" -ForegroundColor DarkRed
        }
    }
}

Write-Host ""