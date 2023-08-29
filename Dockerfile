# Imagen base con Apache y PHP 7.4
FROM php:7.4-apache

# Actualizar paquetes y descargar dependencias necesarias
RUN apt-get update 
RUN apt-get install -y \
        libpng-dev \
        libjpeg-dev \
        libpq-dev \
        libicu-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
        wget \
        git \
        && rm -rf /var/lib/apt/lists/*

# Instalar extensiones de PHP necesarias
RUN docker-php-ext-configure gd --with-jpeg && \
    docker-php-ext-install gd mysqli pdo pdo_mysql zip intl xmlrpc opcache gettext

# Crear directorios 
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html 
RUN mkdir -p /var/www/files && chown -R www-data:www-data /var/www/files 

# Habilitar mod_rewrite y ajustar configuración del servidor Apache
RUN a2enmod rewrite && \
    sed -i 's,/var/www/html/public,/var/www/html,g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/<Directory \/var\/www\/>/<Directory \/var\/www\/html\/>/g' /etc/apache2/apache2.conf

# Exponer puerto 80 para acceder al servidor Apache
EXPOSE 80
