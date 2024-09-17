# Use the official NGINX Alpine image as a base with JQ installed
FROM ##BASE_IMAGE##

# Create a non-root user and group
RUN addgroup -S nextgenapp && adduser -S nextgenapp -G nextgenapp

# Grant full permissions to the NGINX HTML directory
RUN chmod -R 777 /usr/share/nginx/html

# Expose the port on which NGINX will run
EXPOSE 8080

# Switch to the non-root user
USER nextgenapp

# Copy custom NGINX configuration (if any)
COPY distribution/* /usr/share/nginx/html/
COPY info /usr/share/nginx/html/actuator/info
COPY nginx.conf /etc/nginx/nginx.conf

#CUSTOMIZATION 
COPY start.sh start.sh
ENTRYPOINT ["sh", "start.sh" ]