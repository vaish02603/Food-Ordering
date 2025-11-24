# Use NGINX as the web server
FROM nginx:alpine

# Remove the default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy your static website files (index.html, style.css, script.js, images, etc.)
COPY . /usr/share/nginx/html

# Expose port 80 for Kubernetes or Docker
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
