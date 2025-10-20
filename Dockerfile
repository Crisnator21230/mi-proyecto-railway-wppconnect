# ==============================
# Etapa 1: build
# ==============================
FROM node:22-slim AS build

# Crear directorio de trabajo
WORKDIR /usr/src/wpp-server

# Instalar dependencias necesarias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de configuración
COPY package*.json ./

# Instalar dependencias globales necesarias
RUN npm install -g npm@11.6.2 cross-env typescript

# Instalar dependencias del proyecto (sin las de desarrollo si usas build separado)
RUN sed -i '/"prepare":/d' package.json && npm install --legacy-peer-deps

# Copiar el resto del código fuente
COPY . .

# Compilar TypeScript → genera dist/
RUN npm run build

# ==============================
# Etapa 2: runtime
# ==============================
FROM node:22-slim

WORKDIR /usr/src/wpp-server

# Instalar dependencias necesarias en runtime
RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Copiar solo lo necesario del build
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./

# Instalar solo dependencias necesarias para producción
RUN npm install --omit=dev --legacy-peer-deps

# Exponer el puerto (ajústalo según tu app)
EXPOSE 21465

# Comando de inicio (usando cross-env)
CMD ["npx", "cross-env", "NODE_ENV=production", "node", "./dist/server.js"]
