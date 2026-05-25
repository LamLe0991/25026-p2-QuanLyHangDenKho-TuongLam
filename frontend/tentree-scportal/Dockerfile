# ========= BUILD STAGE =========
FROM node:22.15.1-alpine3.20 AS builder

WORKDIR /app

# Copy package files trước để cache layer
COPY package*.json ./
RUN npm ci

# Copy source
COPY . .

# Build Next.js
RUN npm run build


# ========= RUN STAGE =========
FROM node:22.15.1-alpine3.20 AS runner

WORKDIR /app
ENV NODE_ENV=production

# Chỉ copy phần cần thiết
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
# COPY --from=builder /app/next.config.js ./next.config.js

EXPOSE 3000

CMD ["npm", "start"]