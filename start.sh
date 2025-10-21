#!/bin/sh
set -e

echo "=== STARTUP DEBUG: pwd ==="
pwd

echo "=== LIST APP DIR ==="
ls -la

echo "=== LIST DIST ==="
ls -la ./dist || true

# Variables por defecto si no vienen del entorno
: ${NODE_ENV:=production}
: ${PORT:=21465}
export NODE_ENV PORT

echo "NODE_ENV=${NODE_ENV} PORT=${PORT}"
echo "=== TRY STARTS ==="

# intenta múltiples posibles entrypoints
if [ -f ./dist/server.js ]; then
  echo "Starting ./dist/server.js"
  exec node ./dist/server.js
fi

if [ -f ./dist/index.js ]; then
  echo "Starting ./dist/index.js"
  exec node ./dist/index.js
fi

if [ -f ./dist/src/server.js ]; then
  echo "Starting ./dist/src/server.js"
  exec node ./dist/src/server.js
fi

if [ -f ./dist/src/index.js ]; then
  echo "Starting ./dist/src/index.js"
  exec node ./dist/src/index.js
fi

echo "No known entrypoint found in ./dist — printing dist tree and exiting"
ls -R ./dist || true
exit 1
