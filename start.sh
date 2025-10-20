#!/bin/sh
echo "=== STARTUP DEBUG: pwd ==="
pwd
echo "=== LIST ROOT ==="
ls -la
echo "=== LIST APP DIR ==="
ls -la /usr/src/wpp-server || true
echo "=== LIST DIST ==="
ls -la ./dist || true
echo "=== TRY STARTS ==="

# Try common possible entry points
if [ -f ./dist/server.js ]; then
  echo "Starting ./dist/server.js"
  exec node ./dist/server.js
fi

if [ -f ./dist/src/server.js ]; then
  echo "Starting ./dist/src/server.js"
  exec node ./dist/src/server.js
fi

if [ -f ./dist/index.js ]; then
  echo "Starting ./dist/index.js"
  exec node ./dist/index.js
fi

echo "No known entrypoint found in ./dist — printing dist tree and exiting"
ls -R ./dist || true
exit 1
