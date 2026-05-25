# ========= BUILD STAGE =========
FROM node:22-slim AS builder

# Install build tools via apt-get (Debian) to avoid Alpine network/TLS issues
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Accept NEXT_PUBLIC_ variables at build time
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1

# Copy source code
COPY . .

# Build Next.js
RUN npm run build

# ========= RUN STAGE =========
FROM node:22-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user (Debian syntax)
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

# Copy necessary files from builder
COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static

USER nodejs
EXPOSE 3000

CMD ["node", "server.js"]
