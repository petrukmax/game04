#!/usr/bin/env sh
# Stop the local server for this project (only if it runs tools/serve.mjs)
# and start it again. Pass a port as the first argument; 8787 is the default.
cd "$(dirname "$0")" || exit 1
PORT="${1:-8787}"

if command -v lsof >/dev/null 2>&1; then
  PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null)
elif command -v fuser >/dev/null 2>&1; then
  PIDS=$(fuser "$PORT"/tcp 2>/dev/null)
fi

for pid in $PIDS; do
  if ps -p "$pid" -o args= 2>/dev/null | grep -q 'serve\.mjs'; then
    kill "$pid" 2>/dev/null && echo "Stopped server PID $pid."
  fi
done
sleep 0.3
exec node tools/serve.mjs "$PORT" --open
