# Use the official Node.js 20 image.
# https://hub.docker.com/_/node
FROM node:20-slim

# Create and change to the app directory.
WORKDIR /usr/src/app

# Copy application dependency manifests to the container image.
# A wildcard is used to ensure both package.json AND package-lock.json are copied.
# Copying this separately prevents re-running npm install when only application source code changes.
COPY package*.json ./

# Install production dependencies.
RUN npm install && npm cache clean --force

# Copy local code to the container image.
COPY . .

# Run the web service on the container's port 3000.
EXPOSE 3000

# Start the Node.js source as a service.
CMD [ "npm", "start" ]
