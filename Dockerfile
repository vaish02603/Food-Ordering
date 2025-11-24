# Correct Nexus-hosted NGINX base image path
FROM nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/library/nginx:alpine

# Clean default Nginx website directory
RUN rm -rf /usr/share/nginx/html/*

# Copy static website files
COPY . /usr/share/nginx/html/

# Expose default Nginx port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
