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

# Actualizar npm y preparar entorno
RUN npm install -g npm@11.6.2

# Instalar dependencias de desarrollo (sin scripts para evitar husky)
RUN npm install --legacy-peer-deps --ignore-scripts

# Copiar código fuente
COPY . .

# Compilar TypeScript
RUN npm run build

# ==============================
# Stage: runtime
# ==============================
FROM node:22-slim AS runtime

WORKDIR /usr/src/wpp-server

RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copiar artefactos del build y dependencias
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules

# Copiar script de inicio
COPY start.sh ./start.sh
RUN chmod +x ./start.sh

# Variables por defecto (Railway las sobrescribe)
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 8080


CMD ["./start.sh"]
