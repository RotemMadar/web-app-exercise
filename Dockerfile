# Stage 1: Build Environment
FROM node:22-alpine AS builder

WORKDIR /app

COPY sample-nodejs-main/package.json sample-nodejs-main/package-lock.json ./

# To update npm packages and prevent Trivy to find vulnerabilities
RUN npm ci

COPY . .

# Stage 2: Production Environment
FROM node:22-alpine AS runner

ARG PORT=8083

WORKDIR /app

RUN apk update && apk upgrade --no-cache

RUN npm install -g npm@latest

# Create a non-root user for security (Alpine Linux comes with a 'node' user)
RUN chown -R node:node /app
USER node

COPY --from=builder --chown=node:node /app/node_modules ./node_modules

COPY sample-nodejs-main/package.json ./
COPY sample-nodejs-main/app.js ./

EXPOSE $PORT

CMD ["node", "app.js"]
