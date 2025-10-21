#!/bin/sh
set -e

echo "=== STARTING SERVER ==="

# Mostrar ubicación y archivos
echo "=== CURRENT DIR ==="
pwd
echo "=== FILES IN ROOT ==="
ls -la
echo "=== FILES IN DIST ==="
ls -la ./dist || true

# Variables por defecto si no vienen del entorno
: ${NODE_ENV:=production}
: ${PORT:=3000}
export NODE_ENV PORT

echo "NODE_ENV=${NODE_ENV} PORT=${PORT}"
echo "=== TRYING TO START APP ==="

# Intentar múltiples posibles entrypoints
if [ -f ./dist/server.js ]; then
  echo "Running ./dist/server.js"
  exec node ./dist/server.js
fi

if [ -f ./dist/index.js ]; then
  echo "Running ./dist/index.js"
  exec node ./dist/index.js
fi

if [ -f ./dist/src/server.js ]; then
  echo "Running ./dist/src/server.js"
  exec node ./dist/src/server.js
fi

if [ -f ./dist/src/index.js ]; then
  echo "Running ./dist/src/index.js"
  exec node ./dist/src/index.js
fi

# Si no encuentra ninguno, mostrar estructura y salir con error
echo "No known entrypoint found in ./dist — printing dist tree and exiting"
ls -R ./dist || true
exit 1
