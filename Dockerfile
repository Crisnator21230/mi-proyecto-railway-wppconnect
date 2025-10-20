# --- Etapa base ---
FROM node:22.20.0-slim

# Instalar dependencias necesarias del sistema
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

# Instalar dependencias sin las de desarrollo
RUN npm install --omit=dev

# Copiar el resto del proyecto
COPY . .

# Compilar (si usas TypeScript)
RUN npm run build

# Exponer el puerto
EXPOSE 21465

# Comando para ejecutar
CMD ["npm", "start"]
