# -----------------------
# Stage: build
# -----------------------
FROM node:22-slim AS build

WORKDIR /usr/src/wpp-server

RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install tools needed for build
RUN npm install -g npm@11.6.2 cross-env typescript

# Remove prepare to avoid husky triggers
RUN sed -i '/"prepare":/d' package.json

# Install all deps (including dev) for build tools
RUN npm install --legacy-peer-deps

# Copy source and build
COPY . .
RUN npm run build

# show dist contents for build logs
RUN echo "=== dist contents (build stage) ===" && ls -la /usr/src/wpp-server/dist || true

# -----------------------
# Stage: runtime
# -----------------------
FROM node:22-slim AS runtime

WORKDIR /usr/src/wpp-server

RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copy built artifacts and prod package.json
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./
# Copy node_modules to avoid re-running npm install and re-triggering scripts
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules

# Copy the startup script and make executable
COPY start.sh ./start.sh
RUN chmod +x ./start.sh

# Safety: ensure no prepare script if any odd package.json present
RUN sed -i '/"prepare":/d' package.json || true

ENV PORT=21465
EXPOSE ${PORT}

# Use the debug start script so logs show what is in dist and which file is used
CMD ["./start.sh"]
