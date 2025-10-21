FROM webdevops/php-apache-dev:8.0

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list
RUN sed -i '/security/d' /etc/apt/sources.list

RUN apt-get upgrade && apt-get update && apt-get install nano
