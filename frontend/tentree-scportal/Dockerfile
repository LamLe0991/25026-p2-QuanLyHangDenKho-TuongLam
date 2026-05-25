# ========= BUILD STAGE =========
FROM node:22-alpine AS builder

# Install build tools for native dependencies (fixes npm ci failures on alpine)
RUN apk add --no-cache libc6-compat python3 make g++ 

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
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy necessary files from builder
COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static

USER nodejs
EXPOSE 3000

CMD ["node", "server.js"]
