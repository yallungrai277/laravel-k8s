# Expects to be logged into container registry already.

# To build a specific set of containers with a version, you can use the VERSION as an arg of the docker build command (e.g make docker VERSION=0.0.2)
VERSION ?= latest # Defaults to latest

# You can use the REGISTRY as an arg of the docker build command (e.g make docker REGISTRY=my_registry.com/username) and
# You may also change the default value if you are using a different registry as a default
REGISTRY ?= ghcr.io/yallungrai277 # Defaults to this registry

# Commands
.PHONY: docker build push

docker: build push
    @echo "VERSION: $(VERSION)"
    @echo "REGISTRY: $(REGISTRY)"

build:
    docker build -f Dockerfile --target cli -t ${REGISTRY}/laravel-k8s-cli:${VERSION} .
    docker build -f Dockerfile --target fpm_server -t ${REGISTRY}/laravel-k8s-app:${VERSION} .
    docker build -f Dockerfile --target web_server -t ${REGISTRY}/laravel-k8s-nginx:${VERSION} .

push:
    docker push ${REGISTRY}/laravel-k8s-cli:${VERSION}
    docker push ${REGISTRY}/laravel-k8s-app:${VERSION}
    docker push ${REGISTRY}/laravel-k8s-nginx:${VERSION}

# Available commands
# make docker VERSION=v0.0.2 (Builds and pushes to registry)
# make docker-build VERSION=v0.0.2 (Only builds)
# make docker-push VERSION=v0.0.2 (Only pushes)
