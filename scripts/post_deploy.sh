#!/bin/sh

# Should be run on cli container.
cd /var/www/html

# On kuberenetes context, When using PV and PVC, it overrides the container file system permissions and removes folder. 
# Hence, we create folders and set those permissions here.   
mkdir -p storage/app storage/framework/cache storage/framework/sessions storage/framework/testing storage/framework/views storage/logs
chown -R www-data:www-data /var/www/html/storage
chmod -R 777 /var/www/html/storage

php artisan migrate --force
php artisan cache:clear
php artisan config:clear
php artisan event:cache
php artisan view:cache
php artisan route:cache
php artisan config:cache

composer dump-autoload
## End of script.