# -----------------------
# Stage: build
# -----------------------
FROM node:22-slim AS build

WORKDIR /usr/src/wpp-server

# system deps needed for sharp / puppeteer
RUN apt-get update && apt-get install -y \
    build-essential \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copy package files and install build deps
COPY package*.json ./

# Install npm, cross-env, typescript for build
RUN npm install -g npm@11.6.2 cross-env typescript

# Remove prepare script to avoid husky during install
RUN sed -i '/"prepare":/d' package.json

# Install all deps (including dev) so build tools exist
RUN npm install --legacy-peer-deps

# Copy source and build
COPY . .
# Optional debug: list src before build
# RUN ls -la /usr/src/wpp-server/src
RUN npm run build

# Debug: list dist contents so logs show that dist was produced
RUN ls -la /usr/src/wpp-server/dist || true

# -----------------------
# Stage: runtime
# -----------------------
FROM node:22-slim AS runtime

WORKDIR /usr/src/wpp-server

# Minimal runtime system deps for libvips/chromium
RUN apt-get update && apt-get install -y \
    libvips-dev \
    chromium \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Copy only built artifacts and production package.json
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/package*.json ./
# Copy node_modules from build (so we don't re-run npm install and re-trigger scripts)
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules

# Ensure prepare hook removed (safety)
RUN sed -i '/"prepare":/d' package.json || true

# Expose port
ENV PORT=21465
EXPOSE ${PORT}

# Start using cross-env via npx to set NODE_ENV reliably
CMD ["npx", "cross-env", "NODE_ENV=production", "node", "./dist/server.js"]
