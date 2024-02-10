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
Moreover, cli is a running container, see compose file it has entryoint defined, if however you don't want the container lingering
or running. simply remove it from the yaml file and run below. (Will work since the cli image is already built on docker compose up).

-   docker run [cli_image_name] php artisan migrate [and so on for any other cmds].

### CS-Fixer

-   docker exec [cli_container_name] ./vendor/bin/pint

### PHP stan

-   docker exec [cli_container_name] ./vendor/bin/phpstan analyse --memory-limit=1G

## Todo

-   Add a post deploy script (See multi stage builds)
-   Make other changes (Reference to original repo for if anything needed.)
-   To do test pipelines and push to container registry.
-   Increase php ini storage file upload size
-   Add opcache etc.
-   Cypress and pipelines optimization
-   Improve final docker build
-   Run parallel test on CI
