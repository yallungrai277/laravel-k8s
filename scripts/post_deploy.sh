#!/bin/sh

cd /var/www/html

php artisan migrate --force
# Since the image has cache of configurations, we clear out the config cache specifically as values defer depending on the environment.
php artisan config:clear
php artisan config:cache

# On kuberenetes context, When using PV and PVC, it overrides the container file system user and permissions and sometimes removes directories too which are
# already present there where the pv path is mounted. So we create required directories and set permissions in init container. Not required for docker based
# deployments.
cd /var/www/html/storage/framework
mkdir -p session views cache
chmod -R 777 /var/www/html/storage

cd /var/www/html
