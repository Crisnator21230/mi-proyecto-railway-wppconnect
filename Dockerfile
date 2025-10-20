# --- Etapa base ---
FROM node:20-bullseye-slim AS base

WORKDIR /usr/src/wpp-server
ENV NODE_ENV=production

# Instalar dependencias del sistema necesarias para Sharp y Puppeteer
RUN apt-get update && apt-get install -y \
  build-essential \
  libvips-dev \
  chromium \
  ffmpeg \
  && rm -rf /var/lib/apt/lists/*

COPY package.json yarn.lock* ./

RUN yarn install --production --frozen-lockfile && yarn cache clean

# --- Etapa de build ---
FROM base AS build
WORKDIR /usr/src/wpp-server
COPY . .
RUN yarn build

# --- Etapa final ---
FROM base
WORKDIR /usr/src/wpp-server
COPY --from=build /usr/src/wpp-server /usr/src/wpp-server
EXPOSE 21465
CMD ["node", "dist/server.js"]
