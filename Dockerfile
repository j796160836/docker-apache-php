FROM alpine:3.7

ENV PHP_VERSION="7.1.14-r0" \
    APACHE_VERSION="2.4.29-r1" \
    OPENSSL_VERSION="1.0.2n-r0" \
    COMPOSER_VERSION="1.6.3" \
    COMPOSER_CHECKSUM="ec6ed7f897709a79f39c73d6a373d82516fbd32930070ab073f831c81c813a0cc155a08a0b56257938563f453e567ba4738051ae9956f856e43528b5262c2b3c  composer.phar"

# Install modules and updates
RUN apk update \
    && apk --no-cache add \
        openssl=="${OPENSSL_VERSION}" \
        apache2=="${APACHE_VERSION}" \
        apache2-ssl \
        apache2-http2

# Install PHP from community
RUN apk --no-cache add \
        php7=="${PHP_VERSION}" \
        php7-apache2 \
        php7-bcmath \
        php7-bz2 \
        php7-calendar \
        php7-common \
        php7-ctype \
        php7-curl \
        php7-dev \
        php7-dom \
        php7-json \
        php7-mbstring \
        php7-mcrypt \
        php7-memcached \
        php7-mysqlnd \
        php7-opcache \
        php7-openssl \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_sqlite \
        php7-phar \
        php7-session \
        php7-sockets \
        php7-xml \
        php7-zip \
        php7-xmlreader \
    && rm /var/cache/apk/*

    # Run required config / setup for apache
    # Ensure apache can create pid file
RUN mkdir /run/apache2
    # Fix group
RUN sed -i -e 's/Group apache/Group www-data/g' /etc/apache2/httpd.conf
    # Fix ssl module
RUN sed -i -e 's/LoadModule ssl_module lib\/apache2\/mod_ssl.so/LoadModule ssl_module modules\/mod_ssl.so/g' /etc/apache2/conf.d/ssl.conf \
    && sed -i -e 's/LoadModule socache_shmcb_module lib\/apache2\/mod_socache_shmcb.so/LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so/g' /etc/apache2/conf.d/ssl.conf
    # Enable modules
RUN sed -i -e 's/#LoadModule rewrite_module modules\/mod_rewrite.so/LoadModule rewrite_module modules\/mod_rewrite.so/g' /etc/apache2/httpd.conf
    # Change document root
RUN sed -i -e 's/\/var\/www\/localhost\/htdocs/\/var\/www/g' /etc/apache2/httpd.conf \
    && sed -i -e 's/\/var\/www\/localhost\/htdocs/\/var\/www/g' /etc/apache2/conf.d/ssl.conf
    # Allow for custom apache configs
RUN mkdir /etc/apache2/conf.d/custom \
    && echo '' >> /etc/apache2/httpd.conf \
    && echo 'IncludeOptional /etc/apache2/conf.d/custom/*.conf' >> /etc/apache2/httpd.conf
    # Fix modules
RUN sed -i -e 's/ServerRoot \/var\/www/ServerRoot \/etc\/apache2/g' /etc/apache2/httpd.conf \
    && mv /var/www/modules /etc/apache2/modules \
    && mv /var/www/run /etc/apache2/run \
    && mv /var/www/logs /etc/apache2/logs
    # Empty /var/www and add an index.php to show phpinfo()
RUN rm -rf /var/www/* \
    && touch /var/www/index.php
    # Install composer
RUN wget https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar \
    && echo "${COMPOSER_CHECKSUM}" > composerchecksum.txt \
    && sha512sum -c composerchecksum.txt \
    && rm composerchecksum.txt \
    && mv composer.phar /usr/bin/composer \
    && chmod +x /usr/bin/composer

WORKDIR /var/www

# Export http and https
EXPOSE 80 443
# Expose www path 
VOLUME ["/var/www"]

# Run apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
