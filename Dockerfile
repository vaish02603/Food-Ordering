# Use NGINX base image stored inside YOUR Nexus hosted registry
FROM nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/library/nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy your static website files
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
