FROM debian:wheezy

MAINTAINER Edgar R. Sandi <edgar.sandi@dafiti.com.br>

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        apt-utils \
        aufs-tools \
        automake \
        bison \
        btrfs-tools \
        build-essential \
        ca-certificates \
        curl \
        git \
        libbz2-dev \
        libcurl4-openssl-dev \
        libmcrypt-dev \
        libreadline-dev \
        libxml2-dev \
        libxslt1-dev \
        locate \
        re2c \
        zlib1g-dev

# Ensure UTF-8 locale
RUN apt-get install --no-install-recommends -y locales
RUN sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN locale-gen
RUN apt-get install -y localepurge
RUN localepurge

# Install and configure Nginx
RUN apt-get install --no-install-recommends -y nginx
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
ADD ./default.conf /etc/nginx/sites-available/default

# get the latest PHP source from master branch
RUN git clone --depth=1 https://github.com/php/php-src.git /usr/local/src/php

# we re going to be working out of the PHP src directory for the compile steps
WORKDIR /usr/local/src/php
ENV PHP_DIR /usr/local/php

# Install PHP
## configure the build
RUN ./buildconf \
    && ./configure \
        --enable-bcmath \
        --enable-cli \
        --enable-fpm \
        --enable-opcache \
        --enable-sockets \
        --with-bz2=/usr \
        --with-config-file-scan-dir=$PHP_DIR/conf.d \
        --with-config-file-path=/etc \
        --with-curl=/usr \
        --with-iconv-dir=/usr \
        --with-icu-dir=/usr \
        --with-ldap=/usr \
        --with-libdir=/lib/x86_64-linux-gnu \
        --with-libxml-dir=/usr \
        --with-mcrypt \
        --with-openssl=/usr \
        --with-pdo-mysql \
        --with-readline \
        --with-xmlrpc \
        --with-xsl \
        --with-zlib=/usr \
        --prefix=$PHP_DIR \
            && make -j9 && make -j9 install \
            && cp php.ini-development /etc/php.ini \
            && cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
            && cp sapi/fpm/php-fpm /usr/local/bin \
            && cp sapi/cli/php /usr/local/bin \
            && rm -rf /usr/local/src

# Configure PHP-FPM
ADD www.conf /usr/local/php/etc/php-fpm.d/www.conf

# Adding php binaries to PATH
ENV PATH $PATH:/usr/local/php/bin
ENV PATH=$PATH:/usr/local/php/bin

# Install Supervisor
RUN apt-get install -y supervisor
ADD supervisord.conf /etc/supervisor/supervisord.conf

# Removing packages no more necessary
RUN apt-get remove -y \
        aufs-tools \
        automake \
        bison \
        btrfs-tools \
        build-essential

WORKDIR /

EXPOSE 80

CMD ["/usr/bin/supervisord"]
