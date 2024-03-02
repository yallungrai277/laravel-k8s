#!/bin/sh

#Note: This script should be run inside the container.

set -e

# You can see a list of required extensions for Laravel here: https://laravel.com/docs/8.x/deployment#server-requirements
PHP_EXTS="bcmath ctype fileinfo mbstring pdo pdo_mysql dom pcntl"
PHP_PECL_EXTS="redis"

# PHPIZE_DEPS -> Automatically injected by the image.
install_php_extensions() {
    apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) $PHP_EXTS && \
    pecl install $PHP_PECL_EXTS && \
    docker-php-ext-enable $PHP_PECL_EXTS && \
    apk del build-dependencies
}

install_php_extensions
