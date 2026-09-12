# Stage 1: Build/Prep (Technically no build steps for static HTML, but adhering to multi-stage rule)
FROM alpine:3.19 AS builder
WORKDIR /app
COPY index.html .
COPY nginx.conf .

# Stage 2: Final runtime image
FROM nginx:1.25-alpine

# Set non-root user for nginx if possible, or just rely on nginx:alpine default non-root mechanisms
# We'll just run it standard but ensure it's a slim image

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the static HTML from builder
COPY --from=builder /app/index.html /usr/share/nginx/html/index.html

# Copy our custom nginx configuration
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
