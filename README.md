## Laravel K8s

Laravel K8s setup with docker.

## Installation

```
-   cp .env.local .env (Configure environment vars)
-   docker compose up -d (Build up all containers)
-   docker exec [cli_container_name] composer install
-   docker exec [cli_container_name] php artisan migrate
-   docker exec [cli_container_name] php artisan db:seed
-   docker exec [cli_container_name] php artisan storage:link (Create storage symlink)
```

Note: The container is set up so that there is already a vite server for development purposes. For hot reloading of assets.

### CS-Fixer

-   docker exec [cli_container_name] ./vendor/bin/pint

### PHP stan

-   docker exec [cli_container_name] ./vendor/bin/phpstan analyse
