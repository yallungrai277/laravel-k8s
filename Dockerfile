# You can see a list of required extensions for Laravel here: https://laravel.com/docs/8.x/deployment#server-requirements
ARG PHP_EXTS="bcmath ctype fileinfo mbstring pdo pdo_mysql dom pcntl"
ARG PHP_PECL_EXTS="redis"

FROM composer:2.6.6 as composer_base

ARG PHP_EXTS
ARG PHP_PECL_EXTS

RUN mkdir -p /var/www/html /var/www/html/bin

WORKDIR /var/www/html

# We need to create a composer group and user, and create a home directory for it, so we keep the rest of our image safe,
# And not accidentally run malicious scripts
RUN addgroup -S composer \
    && adduser -S composer -G composer \
    && chown -R composer /var/www/html \
    && apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev \
    && docker-php-ext-install -j$(nproc) ${PHP_EXTS} \
    && pecl install ${PHP_PECL_EXTS} \
    && docker-php-ext-enable ${PHP_PECL_EXTS} \
    && apk del build-dependencies


# Next we want to switch over to the composer user before running installs.
# This is very important, so any extra scripts that composer wants to run,
# don't have access to the root filesystem.
# This especially important when installing packages from unverified sources.
USER composer

COPY --chown=composer composer.json composer.lock ./

# Install all the dependencies without running any installation scripts.
# We skip scripts as the code base hasn't been copied in yet and script will likely fail,
# as `php artisan` available yet. Also helps us to cache previous runs and layers.
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=composer . .

# Now that the code base and packages are all available, we can run the install again, and let it run any install scripts.
RUN composer install --no-dev --prefer-dist


########################################################################################################
############################################### Frontend ###############################################
########################################################################################################

FROM node:16 as frontend

COPY --from=composer_base /var/www/html /var/www/html

WORKDIR /var/www/html

RUN npm install && \
    npm run build

########################################################################################################
################################################## CLI #################################################
########################################################################################################

FROM php:8.2-alpine as cli

ARG PHP_EXTS
ARG PHP_PECL_EXTS

WORKDIR /var/www/html

# We need to install some requirements into our image,
# used to compile our PHP extensions, as well as install all the extensions themselves.
# https://laravel.com/docs/8.x/deployment#server-requirements
RUN apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) ${PHP_EXTS} && \
    pecl install ${PHP_PECL_EXTS} && \
    docker-php-ext-enable ${PHP_PECL_EXTS} && \
    apk del build-dependencies

# Copy in our code base from our initial build which we installed in the previous stage
COPY --from=composer_base /var/www/html /var/www/html
COPY --from=composer_base /usr/bin/composer /usr/bin/composer
COPY --from=frontend /var/www/html/public /var/www/html/public

########################################################################################################
################################################ PHP FPM ###############################################
########################################################################################################

FROM php:8.2-fpm-alpine as fpm_server

ARG PHP_EXTS
ARG PHP_PECL_EXTS

WORKDIR /var/www/html

RUN apk add --virtual build-dependencies --no-cache ${PHPIZE_DEPS} openssl ca-certificates libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) ${PHP_EXTS} && \
    pecl install ${PHP_PECL_EXTS} && \
    docker-php-ext-enable ${PHP_PECL_EXTS} && \
    apk del build-dependencies

# As FPM uses the www-data user when running our application,
# we need to make sure that we also use that user when starting up,
# so our user "owns" the application when running
USER  www-data

# We have to copy in our code base from our initial build which we installed in the previous stage
COPY --from=composer_base --chown=www-data /var/www/html /var/www/html
COPY --from=frontend --chown=www-data /var/www/html/public /var/www/html/public

# We want to cache the event, routes, and views so we don't try to write them when we are in Kubernetes.
# Docker builds should be as immutable as possible.
RUN php artisan event:cache && \
    php artisan route:cache && \
    php artisan view:cache

########################################################################################################
################################################# NGINX ################################################
########################################################################################################

FROM nginx:1.20-alpine as web_server

WORKDIR /var/www/html

COPY docker/nginx/nginx.conf.template /etc/nginx/templates/default.conf.template

# Copy in ONLY the public directory of our project. This is where all the static assets will live.
COPY --from=frontend /var/www/html/public /var/www/html/public

########################################################################################################
################################################ CRON ###############################################
########################################################################################################

FROM cli as cron

WORKDIR /var/www/html

RUN touch laravel.cron && \
    echo "* * * * * cd /var/www/html && php artisan schedule:run" >> laravel.cron && \
    crontab laravel.cron

CMD ["crond", "-l", "2", "-f"]

# Default stage.
FROM cli
