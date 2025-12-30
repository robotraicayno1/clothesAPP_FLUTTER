# PowerShell script to add firewall rule for Node.js
Write-Host "Adding firewall rule for Node.js Server on port 3000..." -ForegroundColor Yellow

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please right-click the script and select 'Run as Administrator'" -ForegroundColor Yellow
        Write-Host ""
        pause
        exit 1
    }
    
    # Add firewall rule
    netsh advfirewall firewall add rule name="Node.js Server Port 3000" dir=in action=allow protocol=TCP localport=3000
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS! Firewall rule added successfully." -ForegroundColor Green
        Write-Host "You can now restart your Flutter app and try to login." -ForegroundColor Green
        Write-Host ""
        Write-Host "Login credentials:" -ForegroundColor Cyan
        Write-Host "Email: admin@clothes.com" -ForegroundColor White
        Write-Host "Password: admin123" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "FAILED! Could not add firewall rule." -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
}

Write-Host ""
pause
