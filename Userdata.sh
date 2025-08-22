#!/bin/bash
set -xe

EFS_ID="<id_efs>"
DB_ROOT_PASSWORD="<db_root_password>"
DB_NAME="<db_name>"
DB_USER="<db_user>"
DB_PASSWORD="<db_password>"
WP_URL="<dns_alb>"

yum update -y
yum install -y aws-cli docker amazon-efs-utils

service docker start
systemctl enable docker
usermod -a -G docker ec2-user

curl -SL https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir -p /mnt/efs
mount -t efs ${EFS_ID}:/ /mnt/efs
echo "${EFS_ID}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab

chown -R 33:33 /mnt/efs

mkdir -p /home/ec2-user/projeto-docker
cd /home/ec2-user/projeto-docker

cat > .env <<EOL
MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
MYSQL_USER=${DB_USER}
MYSQL_PASSWORD=${DB_PASSWORD}
EOL

cat > docker-compose.yml <<EOL
version: '3.8'

services:
  database:
    mem_limit: 2048m
    image: mysql:8.0.43
    restart: unless-stopped
    ports:
      - 3306:3306
    env_file: .env
    environment:
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
      MYSQL_DATABASE: '${MYSQL_DATABASE}'
      MYSQL_USER: '${MYSQL_USER}'
      MYSQL_PASSWORD: '${MYSQL_PASSWORD}'
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - wordpress-network
      
  phpmyadmin:
    depends_on:
      - database
    image: phpmyadmin/phpmyadmin
    restart: unless-stopped
    ports:
      - 8081:80
    env_file: .env
    environment:
      PMA_HOST: database
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
    networks:
      - wordpress-network

  wordpress:
    depends_on:
      - database
    image: wordpress:6.8.2-php8.1-apache
    restart: unless-stopped
    ports:
      - 80:80
    env_file: .env
    environment:
      WORDPRESS_DB_HOST: database
      WORDPRESS_DB_NAME: '${MYSQL_DATABASE}'
      WORDPRESS_DB_USER: '${MYSQL_USER}'
      WORDPRESS_DB_PASSWORD: '${MYSQL_PASSWORD}'
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', '${WP_URL}');
        define('WP_SITEURL', '${WP_URL}');
    volumes:
      - /mnt/efs:/var/www/html
    networks:
      - wordpress-network

volumes:
  db-data:

networks:
  wordpress-network:
    driver: bridge
EOL

docker-compose up -d