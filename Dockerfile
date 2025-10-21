# ==============================
# Stage: build
# ==============================
FROM node:22-slim AS build

WORKDIR /usr/src/wpp-server

# Dependencias del sistema necesarias (sharp, chromium, ffmpeg)
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copiar package files primero (mejor caching)
COPY package*.json ./

# Actualizar npm a la versión correcta
RUN npm install -g npm@11.6.2

# Instalar todas las dependencias (sin scripts para evitar husky/prepare)
RUN npm ci --legacy-peer-deps --ignore-scripts

# Copiar el código fuente
COPY . .

# Compilar TypeScript
RUN npx tsc --project tsconfig.json || npx tsc

# ==============================
# Stage: runtime
# ==============================
FROM node:22-slim AS runtime

WORKDIR /usr/src/wpp-server

# Dependencias del sistema necesarias en runtime
RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copiar artefactos del build
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# Instalar solo dependencias de producción
RUN npm ci --omit=dev --legacy-peer-deps --ignore-scripts

# Copiar script de inicio
COPY start.sh ./start.sh
RUN chmod +x ./start.sh

# Variables por defecto (Railway las sobrescribe)
ENV NODE_ENV=production
ENV PORT=21465

EXPOSE ${PORT}

# Comando final
CMD ["./start.sh"]
