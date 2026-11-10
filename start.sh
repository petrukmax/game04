#!/usr/bin/env sh
# Start a local server for the Web export and open the default browser.
cd "$(dirname "$0")" || exit 1
exec node tools/serve.mjs 8787 --open
