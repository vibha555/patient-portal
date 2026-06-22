# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first for better layer caching.
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Build the Vite app.
COPY . .
RUN npm run build

# Runtime stage
FROM nginx:1.27-alpine

ENV NODE_ENV=production

# Replace default nginx site config with SPA-friendly config.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder stage.
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
