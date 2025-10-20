# --- Etapa base ---
FROM node:22.20.0

# Crear directorio de trabajo
WORKDIR /usr/src/wpp-server

# Instalar dependencias del sistema necesarias para wppconnect
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar npm actualizado y dependencias sin las de desarrollo
RUN npm install -g npm@11.6.2 && npm install --omit=dev --legacy-peer-deps

# Copiar el resto del proyecto
COPY . .

# Compilar el código TypeScript
RUN npm run build

# Exponer el puerto que usa tu app (por ejemplo, 21465)
EXPOSE 21465

# Comando de inicio (usando cross-env para compatibilidad)
CMD ["npx", "cross-env", "NODE_ENV=production", "node", "./dist/server.js"]
