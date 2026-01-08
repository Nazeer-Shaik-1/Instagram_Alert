@echo off
echo ================================
echo Starting PHP local server
echo ================================

cd app
start cmd /k php -S localhost:8000

timeout /t 2 >nul

echo ================================
echo Starting Cloudflare Tunnel
echo ================================

cd ..
cloudflared\cloudflared.exe tunnel --url http://localhost:8000
