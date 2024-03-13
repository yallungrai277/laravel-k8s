#!/bin/sh

# Should be run on cli container.

cd /var/www/html

php artisan migrate --force
php artisan cache:clear
php artisan config:clear
php artisan event:cache
php artisan view:cache
php artisan route:cache
php artisan config:cache

composer dump-autoload
## End of script.