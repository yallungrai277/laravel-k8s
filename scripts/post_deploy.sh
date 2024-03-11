#!/bin/sh

# Should be run on cli container.

# On kuberenetes context, When using PV and PVC, it overrides the container file system user and permissions and sometimes removes directories too which are
# already present there where the pv path is mounted. So we create required directories that are removed and set permissions in. For this specific container image
# context these were missing. Please check for other images.
# deployments.
cd /var/www/html
mkdir -p storage/app storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs
cd ./storage
chmod -R 777 app framework logs

cd /var/www/html

php artisan cache:clear
php artisan config:clear
php artisan config:cache
php artisan event:cache
php artisan view:cache
php artisan route:cache
php artisan migrate --force

composer dump-autoload
## End of script.