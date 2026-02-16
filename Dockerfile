FROM nginx:alpine
# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*
#copies the static files from the report directory to the nginx html directory
COPY report/ /usr/share/nginx/html/
EXPOSE 80
#starts nginx
CMD ["nginx", "-g" , "daemon off;"]