FROM php:5.6-apache
MAINTAINER Klinnex

# Install required deb packages
RUN apt-get update && \
    apt-get install -y\
    git\
    rrdtool\
    net-snmp-utils\
    cronie\
    php5-ldap\
    php5-devel\
    php5 \
    ntp\
    bison\
    php5-cli\
    php5-mysql\
    php5-common\
    php5-mbstring\
    php5-snmp\
    curl \
    php5-gd\
    openssl\
    openldap\
    mod_ssl\
    php5-pear\
    net-snmp-libs\
    php5-pdo && \
    rm -rf /var/lib/apt/lists/*

# Configure apache and required PHP modules
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-install mysqli && \
    docker-php-ext-configure gd --enable-gd-native-ttf --with-freetype-dir=/usr/include/freetype2 --with-png-dir=/usr/include --with-jpeg-dir=/usr/include && \
    docker-php-ext-install gd && \
    docker-php-ext-install sockets && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install gettext && \
    ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
    docker-php-ext-configure gmp --with-gmp=/usr/include/x86_64-linux-gnu && \
    docker-php-ext-install gmp && \
    docker-php-ext-install mcrypt && \
    docker-php-ext-install pcntl && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install ldap && \
    echo ". /etc/environment" >> /etc/apache2/envvars && \
    a2enmod rewrite

COPY php.ini /usr/local/etc/php/

# copy phpipam sources to web dir
RUN git clone https://github.com/phpipam/phpipam.git ${WEB_REPO} &&\
    cd ${WEB_REPO} &&\
    git checkout ${PHPIPAM_VERSION} &&\
    git submodule update --init --recursive &&\
# Use system environment variables into config.php
# use MYSQL ENV MYSQL receive on docker-compose
    cp ${WEB_REPO}/config.dist.php ${WEB_REPO}/config.php && \
    sed -i -e "s/\['host'\] = 'localhost'/\['host'\] = 'mysql'/" \
    -e "s/\['user'\] = 'phpipam'/\['user'\] = 'root'/" \
    -e "s/\['pass'\] = 'phpipamadmin'/\['pass'\] = getenv(\"MYSQL_ENV_MYSQL_ROOT_PASSWORD\")/" \
    ${WEB_REPO}/config.php && \
    sed -i -e "s/\['port'\] = 3306;/\['port'\] = 3306;\n\n\$password_file = getenv(\"MYSQL_ENV_MYSQL_ROOT_PASSWORD\");\nif(file_exists(\$password_file))\n\$db\['pass'\] = preg_replace(\"\/\\\\s+\/\", \"\", file_get_contents(\$password_file));/" \
    ${WEB_REPO}/config.php

EXPOSE 80 443
