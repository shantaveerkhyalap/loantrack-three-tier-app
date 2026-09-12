# Frontend Dockerfile (cleaned of comments)
FROM alpine:3.19 AS builder
WORKDIR /app
COPY index.html .
COPY nginx.conf .
FROM nginx:1.25-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/index.html /usr/share/nginx/html/index.html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
