# # Use NGINX as the web server
# FROM nginx:alpine

# # Remove the default nginx website
# RUN rm -rf /usr/share/nginx/html/*

# # Copy your static website files (index.html, style.css, script.js, images, etc.)
# COPY . /usr/share/nginx/html

# # Expose port 80 for Kubernetes or Docker
# EXPOSE 80

# # Start nginx
# CMD ["nginx", "-g", "daemon off;"]



# Use NGINX from Nexus Docker Proxy instead of Docker Hub
FROM nexus-service-for-docker-proxy.nexus.svc.cluster.local:8085/library/nginx:alpine

# Remove default nginx web content
RUN rm -rf /usr/share/nginx/html/*

# Copy your website
COPY . /usr/share/nginx/html
