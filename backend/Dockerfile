# ---- Base ----
FROM node:22-alpine AS base
WORKDIR /app

# ---- Dependencies ----
FROM base AS deps
# Add build tools in case any dependencies require native compilation (node-gyp)
RUN apk add --no-cache libc6-compat python3 make g++ 

# Copy package files
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --omit=dev && npm cache clean --force

# ---- Release ----
FROM base AS runner
ENV NODE_ENV=production

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source code
COPY . .

# Create required directories and set proper ownership
RUN mkdir -p data/uploads && chown -R nodejs:nodejs /app/data

# Switch to non-root user
USER nodejs

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5000/health', (r) => {if(r.statusCode!==200)throw new Error(r.statusCode)})"

CMD ["node", "server.js"]
