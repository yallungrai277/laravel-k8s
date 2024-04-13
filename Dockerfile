########################################################################################################
################################################## Composer ############################################
########################################################################################################

FROM composer:2.6.6 as composer_base

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

RUN addgroup -S composer \
    && adduser -S composer -G composer \
    && chown -R composer /var/www/html

# Install required extensions required by some of composer packages.
COPY ./scripts ./scripts

RUN chmod +x ./scripts/install_php_extensions.sh && ./scripts/install_php_extensions.sh

# Next we want to switch over to the composer user before running installs.
# This is very important, so any extra scripts that composer wants to run,
# don't have access to the root filesystem.
USER composer

COPY --chown=composer composer.json composer.lock ./

# Install all the dependencies without running any installation scripts.
# We skip scripts as the code base hasn't been copied in yet and script will likely fail,
# as `php artisan` available yet. Also helps us to cache previous runs and layers.
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY --chown=composer . .

# Now that the code base and packages are all available, we can run the install again, and let it run any install scripts.
RUN composer install --optimize-autoloader --no-dev --prefer-dist -o

# Make files ignored by dockerignore. These needs to have persistent volumes on deployment along with /storage/public.
RUN mkdir -p boostrap/cache storage/app storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs

RUN chmod -R 777 boostrap storage

########################################################################################################
############################################### Frontend ###############################################
########################################################################################################

FROM node:18 as frontend

COPY --from=composer_base /var/www/html /var/www/html

WORKDIR /var/www/html

RUN npm install && \
    npm run build

# Remove hot from the container in case if added, otherwise vite will maker requests to assets as a dev server.
RUN rm -rf public/hot

########################################################################################################
################################################## CLI #################################################
########################################################################################################

FROM php:8.2-alpine as cli

WORKDIR /var/www/html

# Copy in our code base from our initial build which we installed in the previous stage
COPY --from=composer_base /var/www/html /var/www/html

# Install required extensions required by to run commands successfully.
RUN chmod +x ./scripts/install_php_extensions.sh && ./scripts/install_php_extensions.sh

# Copy composer binary so that composer can be run.
COPY --from=composer_base /usr/bin/composer /usr/bin/composer
COPY --from=frontend /var/www/html/public /var/www/html/public

########################################################################################################
################################################ PHP FPM ###############################################
########################################################################################################

FROM php:8.2-fpm-alpine as app

# Copy php ini configurations.
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini

WORKDIR /var/www/html

# We have to copy in our code base from our initial build which we installed in the previous stage.
COPY --from=composer_base --chown=www-data /var/www/html /var/www/html

# We need root user in order to install php extensions.
USER root
RUN chmod +x ./scripts/install_php_extensions.sh && ./scripts/install_php_extensions.sh

# Change back to normal user.
USER  www-data

COPY --from=frontend --chown=www-data /var/www/html/public /var/www/html/public

RUN cp .env.prod .env

RUN php artisan storage:link

########################################################################################################
################################################# NGINX ################################################
########################################################################################################

FROM nginx:1.20-alpine as web

WORKDIR /var/www/html

# Add nano and sudo
RUN apk add nano doas-sudo-shim

COPY docker/nginx/nginx.conf.prod.template /etc/nginx/templates/default.conf.template

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

# Set crond as the entrypoint
ENTRYPOINT [ "crond" ]

# Pass args to entrypoint binary.
CMD ["-l", "2", "-f"]

# Default stage.
FROM composer_base
