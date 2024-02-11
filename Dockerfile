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
COPY ./docker/scripts ./docker/scripts

RUN chmod +x ./docker/scripts/install_php_extensions.sh && ./docker/scripts/install_php_extensions.sh

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
RUN composer install --no-dev --prefer-dist -o

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

WORKDIR /var/www/html

# Install required extensions required by to run commands successfully.
COPY ./docker/scripts ./docker/scripts

RUN chmod +x ./docker/scripts/install_php_extensions.sh && ./docker/scripts/install_php_extensions.sh

# Copy in our code base from our initial build which we installed in the previous stage
COPY --from=composer_base /var/www/html /var/www/html
# Copy composer binary so that composer can be run.
COPY --from=composer_base /usr/bin/composer /usr/bin/composer
COPY --from=frontend /var/www/html/public /var/www/html/public

########################################################################################################
################################################ PHP FPM ###############################################
########################################################################################################

FROM php:8.2-fpm-alpine as app

WORKDIR /var/www/html

COPY ./docker/scripts ./docker/scripts

RUN chmod +x ./docker/scripts/install_php_extensions.sh && ./docker/scripts/install_php_extensions.sh

# As FPM uses the www-data user when running our application,
# we need to make sure that we also use that user when starting up,
# so our user "owns" the application when running
USER  www-data

# We have to copy in our code base from our initial build which we installed in the previous stage.
COPY --from=composer_base --chown=www-data /var/www/html /var/www/html
COPY --from=frontend --chown=www-data /var/www/html/public /var/www/html/public

RUN cp .env.prod .env

# Make files ignored by dockerignore. These needs to have persistent volumes on deployment along with /storage/public
RUN mkdir -p boostrap/cache storage/app storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs

RUN chmod -R 777 boostrap storage

# We want to cache the event, routes, and views so we don't try to write them when we are in Kubernetes.
# Docker builds should be as immutable as possible. Can be done after a post deploy script ?
RUN php artisan event:cache && \
    php artisan route:cache && \
    php artisan storage:link

########################################################################################################
################################################# NGINX ################################################
########################################################################################################

FROM nginx:1.20-alpine as web_server

WORKDIR /var/www/html

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
FROM cli
