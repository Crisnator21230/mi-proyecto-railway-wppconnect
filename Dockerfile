# ==============================
# Etapa 1: build
# ==============================
FROM node:22-slim AS build

WORKDIR /usr/src/wpp-server

RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install -g npm@11.6.2 cross-env typescript

RUN sed -i '/"prepare":/d' package.json && npm install --legacy-peer-deps

COPY . .

RUN npm run build

# ==============================
# Etapa 2: runtime
# ==============================
FROM node:22-slim

WORKDIR /usr/src/wpp-server

RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# 🚫 Eliminar scripts 'prepare' antes de instalar dependencias
RUN sed -i '/"prepare":/d' package.json

# Instalar solo dependencias necesarias para producción
RUN npm install --omit=dev --legacy-peer-deps

EXPOSE 21465

CMD ["npx", "cross-env", "NODE_ENV=production", "node", "./dist/server.js"]
