#!/bin/sh

# Create SSL directory if it doesn't exist
mkdir -p /etc/nginx/ssl

# Generate self-signed certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    
    echo "SSL certificate generated successfully!"
    
    # Set proper permissions
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
else
    echo "SSL certificate already exists, skipping generation."
fi
