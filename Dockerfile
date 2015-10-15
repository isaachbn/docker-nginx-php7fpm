FROM debian:jessie

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Install basic packages
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
        libxpm-dev

# Ensure UTF-8 locale
RUN apt-get install locales
RUN sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
RUN locale-gen

# Download PHP7
ADD http://repos.zend.com/zend-server/early-access/php7/php-7.0-latest-DEB-x86_64.tar.gz /usr/local/php7
RUN tar xzPf /usr/local/php7

# Linking and Export
RUN echo 'export PATH="$PATH:/usr/local/php7/bin:/usr/local/php7/sbin"' >> /etc/bash.bashrc

# Configure PHP-FPM
ADD conf/php-fpm.conf /etc/php7/php-fpm.conf
ADD conf/www.conf /etc/php7/php-fpm.d/www.conf

# Install and configure Nginx
RUN apt-get install --no-install-recommends -y nginx
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
ADD ./conf/nginx.conf /etc/nginx/sites-available/default

# Install Supervisor
RUN apt-get install --no-install-recommends -y supervisor
ADD ./conf/supervisord.conf /etc/supervisor/supervisord.conf

WORKDIR /

EXPOSE 80

CMD ["/usr/bin/supervisord"]
