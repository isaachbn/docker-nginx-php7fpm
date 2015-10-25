FROM debian:jessie

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Install necessary packages
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        wget \
        libcurl4-openssl-dev \
        libmcrypt-dev \
        libxml2-dev \
        libjpeg-dev \
        libjpeg62 \
        libfreetype6-dev \
        libmysqlclient-dev \
        libgmp-dev \
        libicu-dev \
        libpspell-dev \
        librecode-dev \
        libxpm-dev \
        nginx \
        supervisor \
        locales \
        autoconf \
        gcc \
        pkg-config \
        libmemcached-dev \
        libtool \
        automake \
        make

# Ensure UTF-8 locale
RUN sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN locale-gen

# Download PHP7
ADD http://repos.zend.com/zend-server/early-access/php7/php-7.0-latest-DEB-x86_64.tar.gz /usr/local/php7
ADD http://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz /tmp/php7-memcached.tar.gz
ADD https://github.com/alanxz/rabbitmq-c/archive/master.tar.gz /tmp/rabbitmq.tar.gz
ADD https://github.com/pinepain/php-amqp/archive/refactor_and_php7_with_bc.tar.gz /tmp/php7-amqp.tar.gz

RUN tar xzPf /usr/local/php7 \
    && cd /tmp \
    && tar xzf php7-memcached.tar.gz \
    && tar xzf rabbitmq.tar.gz \
    && tar xzf php7-amqp.tar.gz \
    && echo 'export PATH="$PATH:/usr/local/php7/bin:/usr/local/php7/sbin"' >> /etc/bash.bashrc \
    && cd php-memcached-php7 \
    && /usr/local/php7/bin/phpize \
    && ./configure --with-php-config=/usr/local/php7/bin/php-config \
    && make \
    && make install \
    && cd /tmp/rabbitmq-c-master \
    && autoreconf -i \
    && ./configure \
    && make \
    && make install \
    && cd /tmp/php-amqp-refactor_and_php7_with_bc \
    && /usr/local/php7/bin/phpize \
    && ./configure --with-php-config=/usr/local/php7/bin/php-config \
    && make \
    && make install \
    && mkdir /usr/local/php7/etc/conf.d

# Configure PHP-FPM, Nginx and Supervisor
ADD conf/php-fpm.conf /etc/php7/php-fpm.conf
ADD conf/www.conf /etc/php7/php-fpm.d/www.conf
ADD ./conf/supervisord.conf /etc/supervisor/supervisord.conf
ADD ./conf/nginx.conf /etc/nginx/sites-available/default

RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN touch /usr/local/php7/etc/conf.d/memcached.ini \
    && echo "extension=memcached.so" >> /usr/local/php7/etc/conf.d/memcached.ini \
    && touch /usr/local/php7/etc/conf.d/amqp.ini \
    && echo "extension=amqp.so" >> /usr/local/php7/etc/conf.d/amqp.ini \
    && rm -fr /tmp/* /var/lib/apt/lists/* /var/tmp/* \
    && apt-get remove --purge --auto-remove autoconf pkg-config gcc make libtool automake -y \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && apt-get clean

WORKDIR /

EXPOSE 80

CMD ["/usr/bin/supervisord"]
