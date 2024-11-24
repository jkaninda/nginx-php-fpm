IMAGE_NAME?=jkaninda/nginx-php-fpm
.PHONY: all
all: build
##@ Build
.PHONY: build
build: build-81 build-82 build-83 build-84
.PHONY: build-80
build-80:
	 docker build --build-arg phpVersion=8.0 -f src/docker/8.0/Dockerfile -t ${IMAGE_NAME}:8.0 .
.PHONY: build-81
build-81:
	 docker build --build-arg phpVersion=8.1 -f src/docker/Dockerfile -t ${IMAGE_NAME}:8.1 .
.PHONY: build-82
build-82:
	 docker build --build-arg phpVersion=8.2 -f src/docker/Dockerfile -t ${IMAGE_NAME}:8.2 .
.PHONY: build-83
build-83:
	 docker build --build-arg phpVersion=8.3 -f src/docker/Dockerfile -t ${IMAGE_NAME}:8.3 .
.PHONY: build-84
build-84:
	 docker build --build-arg phpVersion=8.4 -f src/docker/Dockerfile -t ${IMAGE_NAME}:8.4 .
