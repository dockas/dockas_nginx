#!/bin/bash

# Make letsencrypt live directory
mkdir -p /etc/letsencrypt

# Make letsencrypt directories
mkdir -p /var/www/dockas.com \
         /var/www/api.dockas.com \
         /var/www/file.dockas.com \
         /var/www/socket.dockas.com \
         /var/www/blog.dockas.com

# See https://github.com/letsencrypt/letsencrypt/issues/1154#issuecomment-151672549
# run let's encrypt
if [ "$MODE" = "prod" ]; then
    # Start nginx as a daemon to receive requests from letsencrypt
    nginx -c /home/conf/nginx_cert.conf -t && \
        nginx -c /home/conf/nginx_cert.conf -g 'daemon on;'

    # Give a break for health checking.
    sleep 20

    if [ ! -f /etc/letsencrypt/live/dockas.com/fullchain.pem ]; then
        certbot certonly -m dev@dockas.com --text --agree-tos --keep-until-expiring --webroot \
            -w /var/www/dockas.com -d dockas.com -d www.dockas.com -d dockas.com.br -d www.dockas.com.br \
            -w /var/www/file.dockas.com -d file.dockas.com -d file.dockas.com.br \
            -w /var/www/api.dockas.com -d api.dockas.com -d api.dockas.com.br \
            -w /var/www/socket.dockas.com -d socket.dockas.com -d socket.dockas.com.br \
            -w /var/www/blog.dockas.com -d blog.dockas.com
    else
        echo "letsencrypt/live/dockas.com has fullchain.pem file"
    fi

    # kill nginx
    nginx -c /home/conf/nginx_cert.conf -s stop
fi

if [ "$MODE" = "stage" ]; then
    # Start nginx as a daemon to receive requests from letsencrypt
    nginx -c /home/conf/nginx_cert.stage.conf -t && \
        nginx -c /home/conf/nginx_cert.stage.conf -g 'daemon on;'

    # Give a break for health checking.
    sleep 20

    if [ ! -f /etc/letsencrypt/live/dockas.com/fullchain.pem ]; then
        certbot certonly -m dev@dockas.com --text --agree-tos --keep-until-expiring --webroot \
            -w /var/www/dockas.com -d stage.dockas.com \
            -w /var/www/file.dockas.com -d file.stage.dockas.com \
            -w /var/www/api.dockas.com -d api.stage.dockas.com \
            -w /var/www/socket.dockas.com -d socket.stage.dockas.com
    else
        echo "letsencrypt/live/dockas.com has fullchain.pem file"
    fi

    # kill nginx
    nginx -c /home/conf/nginx_cert.stage.conf -s stop
fi

# Generate a self signed certificate for testing only.
if [ "$MODE" = "dev" ]; then
    # Create the letsencrypt destination dir
    mkdir -p /etc/letsencrypt/live/dockas.com

    # Generate a key for the Root CA
    openssl genrsa 8192 > /home/ssl/ca.key

    # Generate the root CA certificate
    openssl req \
        -x509 \
        -new \
        -nodes \
        -key /home/ssl/ca.key \
        -days 3650 \
        -subj "/C=BR/ST=Minas Gerais/L=Belo Horizonte/O=Dockas/OU=IT Department/CN=Dockas" \
        > /home/ssl/ca.pem

    # Generating a key for the multidomain certificate
    openssl genrsa 4096 > /etc/letsencrypt/live/dockas.com/privkey.pem

    # Create a certificate for multidomain
    openssl req \
        -new \
        -key /etc/letsencrypt/live/dockas.com/privkey.pem \
        -subj "/C=BR/ST=Minas Gerais/L=Belo Horizonte/O=Dockas/OU=IT Department/CN=dockas.dev" \
        > /home/ssl/dockas.dev.csr

    # Sign the certificate
    openssl x509 \
        -req \
        -days 3600 \
        -CA /home/ssl/ca.pem \
        -CAkey /home/ssl/ca.key \
        -CAcreateserial \
        -in /home/ssl/dockas.dev.csr \
        -extfile /home/conf/dockas.dev.extensions \
        -extensions dockas_dev \
        > /etc/letsencrypt/live/dockas.com/fullchain.pem
fi

# Run supervisord
/usr/bin/supervisord
