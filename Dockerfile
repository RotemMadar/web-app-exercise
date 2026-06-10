# ==========================================
# Stage 1: Build Environment
# ==========================================
# Use a specific, slim version of the official image
FROM node:20-alpine AS builder

WORKDIR /app

# Copy ONLY the dependency files first to leverage Docker layer caching
COPY sample-nodejs-main/package.json sample-nodejs-main/package-lock.json ./

# Install all dependencies (including devDependencies needed for building)
RUN npm ci

# Copy the rest of your application code
COPY . .

# ==========================================
# Stage 2: Production Environment
# ==========================================
# Start fresh from a lightweight image to keep the final size tiny
FROM node:20-alpine AS runner

# Set environment to production
ENV NODE_ENV=production

WORKDIR /app

# Create a non-root user for security (Alpine Linux comes with a 'node' user)
# We change ownership of the /app directory to this user
RUN chown -R node:node /app
USER node

# Copy ONLY the production-ready artifacts from the 'builder' stage
# This leaves behind all the heavy build tools and source code
COPY --from=builder --chown=node:node /app/node_modules ./node_modules

COPY package.json ./
COPY app.js ./

# Expose the port your app listens on (matches the containerPort in your Helm chart)
EXPOSE 8080

# Define the command to start your application
CMD ["node", "app.js"]
