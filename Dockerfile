# --- Etapa base ---
FROM node:22.20.0-slim

# Instalar dependencias del sistema necesarias para sharp, puppeteer y chromium
RUN apt-get update && apt-get install -y \
  build-essential \
  libvips-dev \
  chromium \
  ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Crear carpeta de trabajo
WORKDIR /usr/src/wpp-server

# Copiar archivos del proyecto
COPY package*.json ./

# Actualizar npm y luego instalar dependencias sin las de desarrollo
RUN npm install -g npm@11.6.2 && npm install --omit=dev --legacy-peer-deps

# Copiar el resto del código del proyecto
COPY . .

# Compilar si usas TypeScript
RUN npm run build

# Exponer el puerto
EXPOSE 21465

# Comando de inicio
CMD ["npm", "start"]
