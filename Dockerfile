FROM nginx:alpine

# Remove default NGINX website
RUN rm -rf /usr/share/nginx/html/*

# Copy your static HTML/CSS/JS files
COPY . /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
