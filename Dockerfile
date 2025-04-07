# Stage 1: Build the UI assets using a full Node image (if needed for native build tools)
FROM node:10 AS ui-build
WORKDIR /usr/src/app
COPY my-app/ ./my-app/
RUN cd my-app && npm install && npm run build

# Stage 2: Build the server using a smaller Alpine image
FROM node:10-alpine AS server-build
WORKDIR /usr/src/app
# Copy the built UI assets from the previous stage
COPY --from=ui-build /usr/src/app/my-app/build ./my-app/build
# Copy API package files
COPY api/package*.json ./api/
# Install API dependencies in production mode and clean npm cache afterward
RUN cd api && npm install --production && npm cache clean --force
# Copy the API server code
COPY api/server.js ./api/

EXPOSE 3080

CMD ["node", "./api/server.js"]
