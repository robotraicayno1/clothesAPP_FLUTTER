@echo off
echo Adding firewall rule for Node.js Server on port 3000...
netsh advfirewall firewall add rule name="Node.js Server Port 3000" dir=in action=allow protocol=TCP localport=3000

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Firewall rule added successfully.
    echo You can now restart your Flutter app and try to login.
    echo.
    echo Login credentials:
    echo Email: admin@clothes.com
    echo Password: admin123
) else (
    echo.
    echo FAILED! Please make sure you run this file as Administrator.
    echo Right-click on fix_firewall.bat and select "Run as administrator"
)

echo.
pause
