# OJS 3.5 para SEDICI/SUMARC. Requiere el tarball oficial junto a este archivo.
ARG OJS_VERSION=3.5.0-6

FROM alpine:3.20 AS source
ARG OJS_VERSION
COPY ojs-${OJS_VERSION}.tar.gz /tmp/ojs.tar.gz
RUN mkdir /ojs \
    && tar xzf /tmp/ojs.tar.gz -C /ojs --strip-components=1 \
    && rm -f /ojs/config.inc.php

# Dependencias PHP de los plugins; plugins-src/ lo genera docker/fetch-plugins.sh.
FROM composer:2 AS plugins
COPY plugins-src/ /plugins/
RUN for dir in /plugins/generic/jatsParser/JATSParser /plugins/importexport/scieloAdapter; do \
        composer install -d "$dir" --no-dev --no-interaction --optimize-autoloader --ignore-platform-reqs; \
    done \
    && find /plugins -name .git -prune -exec rm -rf {} +

# 8.3 es la version mas nueva que PKP prueba en CI para stable-3_5_0.
FROM php:8.3-apache
ARG OJS_VERSION
LABEL org.opencontainers.image.title="OJS SEDICI" \
      org.opencontainers.image.version="${OJS_VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev \
        libwebp-dev libxml2-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath ftp gd intl mysqli opcache pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite headers remoteip

COPY docker/php.ini /usr/local/etc/php/conf.d/zz-ojs.ini
COPY docker/apache.conf /etc/apache2/conf-enabled/zz-ojs.conf
COPY docker/init-config.php /usr/local/lib/ojs/init-config.php
COPY docker/entrypoint.sh /usr/local/bin/ojs-entrypoint
COPY --from=source --chown=www-data:www-data /ojs/ /var/www/html/
COPY --from=plugins --chown=www-data:www-data /plugins/ /var/www/html/plugins/

# config.inc.php vive en un volumen: el instalador lo reescribe y debe persistir.
RUN chmod +x /usr/local/bin/ojs-entrypoint \
    && cp -a /var/www/html/public /usr/local/lib/ojs/public-default \
    && ln -s /var/www/config/config.inc.php /var/www/html/config.inc.php \
    && chown -h www-data:www-data /var/www/html/config.inc.php

VOLUME ["/var/www/config", "/var/www/files", "/var/www/html/public"]
EXPOSE 80
ENTRYPOINT ["ojs-entrypoint"]
CMD ["apache2-foreground"]
