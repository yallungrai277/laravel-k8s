#!/bin/sh

# Should be run on cli container.

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