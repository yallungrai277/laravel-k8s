#!/bin/sh

# Should be run on cli container.

# On kuberenetes context, When using PV and PVC, it overrides the container file system user and permissions and sometimes removes directories too which are
# already present there where the pv path is mounted. So we create required directories that are removed and set permissions in. For this specific container image
# context these were missing. Please check for other images.
# deployments.
cd /var/www/html/storage/framework
mkdir -p session views cache
chmod -R 777 /var/www/html/storage

cd /var/www/html

# Since the image has cache of configurations, we clear out the config cache specifically as values defer depending on the environment.
php artisan config:clear
php artisan config:cache
php artisan migrate --force

composer dump-autoload