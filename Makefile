DOCKER_INTERNAL_REG=localhost:5000

DOCKER_IMAGE_BASE=ptk-base
DOCKER_IMAGE_NETWORK_TOOLKIT=ptk-network-toolkit
DOCKER_IMAGE_PROXY_TOOLKIT=ptk-proxy-toolkit
DOCKER_IMAGE_PLATFORM_TOOLKIT=ptk-platform-toolkit
DOCKER_IMAGE_DATA_TOOLKIT=ptk-data-toolkit

DOCKER_INTERNAL_TAG := $(shell git rev-parse --short HEAD)

.PHONY: images
images: image-base image-network image-proxy image-platform image-data

.PHONY: image-base
image-base:
	DOCKER_BUILDKIT=1 docker build \
		--target base_image \
		-t $(DOCKER_INTERNAL_REG)/$(DOCKER_IMAGE_BASE):$(DOCKER_INTERNAL_TAG) .

.PHONY: image-network
image-network:
	DOCKER_BUILDKIT=1 docker build \
		--target network_toolkit \
		-t $(DOCKER_INTERNAL_REG)/$(DOCKER_IMAGE_NETWORK_TOOLKIT):$(DOCKER_INTERNAL_TAG) .

.PHONY: image-proxy
image-proxy:
	DOCKER_BUILDKIT=1 docker build \
		--target proxy_toolkit \
		-t $(DOCKER_INTERNAL_REG)/$(DOCKER_IMAGE_PROXY_TOOLKIT):$(DOCKER_INTERNAL_TAG) .

.PHONY: image-platform
image-platform:
	DOCKER_BUILDKIT=1 docker build \
		--target platform_toolkit \
		-t $(DOCKER_INTERNAL_REG)/$(DOCKER_IMAGE_PLATFORM_TOOLKIT):$(DOCKER_INTERNAL_TAG) .

.PHONY: image-data
image-data:
	DOCKER_BUILDKIT=1 docker build \
		--target data_toolkit \
		-t $(DOCKER_INTERNAL_REG)/$(DOCKER_IMAGE_DATA_TOOLKIT):$(DOCKER_INTERNAL_TAG) .
