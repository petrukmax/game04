@echo off
setlocal
cd /d "%~dp0"

echo Stopping the local server on port 8787 (if this project started it)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$conn = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1; if ($conn) { $proc = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $conn.OwningProcess); if ($proc.CommandLine -match 'serve\.mjs') { Stop-Process -Id $conn.OwningProcess -Force; Write-Host ('Stopped server PID ' + $conn.OwningProcess) } else { Write-Host 'Port 8787 is used by another app; the new server will use the next free port.' } } else { Write-Host 'No local server was running.' }"
timeout /t 1 /nobreak >nul

where node >nul 2>nul
if errorlevel 1 goto :no_node

echo Starting the server again on http://127.0.0.1:8787/
echo Close this window or press Ctrl+C to stop the server.
node tools\serve.mjs 8787 --open
goto :eof

:no_node
echo.
echo Node.js was not found on PATH.
echo Install Node.js 20+ from https://nodejs.org/ and run this file again.
echo.
pause
