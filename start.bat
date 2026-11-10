@echo off
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 goto :try_python

echo Starting Mars Arachnid Defense on http://127.0.0.1:8787/
echo Close this window or press Ctrl+C to stop the server.
node tools\serve.mjs 8787 --open
goto :eof

:try_python
where python >nul 2>nul
if errorlevel 1 goto :no_runtime

echo Node.js not found; using Python instead.
echo Starting Mars Arachnid Defense on http://127.0.0.1:8787/
echo Close this window or press Ctrl+C to stop the server.
start "" http://127.0.0.1:8787/
python -m http.server 8787
goto :eof

:no_runtime
echo.
echo Neither Node.js nor Python was found on PATH.
echo Install Node.js 20+ from https://nodejs.org/ or Python 3 from https://python.org/
echo then double-click this file again.
echo.
pause
