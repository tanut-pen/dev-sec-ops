# ── Stage 1: builder ───────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

# Copy dependency manifests and install dependencies
COPY package*.json ./
RUN npm ci

# Copy the rest of the application files
COPY . .

# ── Stage 2: runtime ───────────────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /usr/src/app

# Copy built dependencies and source files from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/server.js ./
COPY --from=builder /usr/src/app/public ./public/

# Hardening: Run as non-root user
USER node

# Document service port and define entrypoint
EXPOSE 3000
ENTRYPOINT ["node", "server.js"]
