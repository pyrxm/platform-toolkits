INTERNAL_REG=localhost:5000
IMAGE_BUILDER=podman

IMAGE_BASE=ptk-base
IMAGE_NETWORK_TOOLKIT=ptk-network-toolkit
IMAGE_PROXY_TOOLKIT=ptk-proxy-toolkit
IMAGE_PLATFORM_TOOLKIT=ptk-platform-toolkit
IMAGE_DATA_TOOLKIT=ptk-data-toolkit

INTERNAL_TAG := $(shell git rev-parse --short HEAD)

.PHONY: images
images: image-base image-network image-proxy image-platform image-data

.PHONY: image-base
image-base:
	$(IMAGE_BUILDER) build \
		--target base_image \
		-t $(INTERNAL_REG)/$(IMAGE_BASE):$(INTERNAL_TAG) .

.PHONY: run-base
run-base:
	image-base && \
	$(IMAGE_BUILDER) run --rm -it $(INTERNAL_REG)/$(IMAGE_BASE):$(INTERNAL_TAG) zsh

.PHONY: image-network
image-network:
	$(IMAGE_BUILDER) build \
		--target network_toolkit \
		-t $(INTERNAL_REG)/$(IMAGE_NETWORK_TOOLKIT):$(INTERNAL_TAG) .

.PHONY: run-network
run-network: image-network
	$(IMAGE_BUILDER) run --rm -it $(INTERNAL_REG)/$(IMAGE_NETWORK_TOOLKIT):$(INTERNAL_TAG) zsh

.PHONY: image-proxy
image-proxy:
	$(IMAGE_BUILDER) build \
		--target proxy_toolkit \
		-t $(INTERNAL_REG)/$(IMAGE_PROXY_TOOLKIT):$(INTERNAL_TAG) .

.PHONY: run-proxy
run-proxy: image-proxy
	$(IMAGE_BUILDER) run --rm -it $(INTERNAL_REG)/$(IMAGE_PROXY_TOOLKIT):$(INTERNAL_TAG) zsh

.PHONY: image-platform
image-platform:
	$(IMAGE_BUILDER) build \
		--target platform_toolkit \
		-t $(INTERNAL_REG)/$(IMAGE_PLATFORM_TOOLKIT):$(INTERNAL_TAG) .

.PHONY: run-platform
run-platform: image-platform
	$(IMAGE_BUILDER) run --rm -it \
		$(INTERNAL_REG)/$(IMAGE_PLATFORM_TOOLKIT):$(INTERNAL_TAG) zsh

.PHONY: test-platform
test-platform: image-platform
	$(IMAGE_BUILDER) run --rm -it \
        -e "PLATFORM_TOOLKIT_CHEZMOI_REPO=https://gist.github.com/f7c2e4748b80e311e2fd0d6d31fb866b.git" \
	    -e "PLATFORM_TOOLKIT_INSTALL_OMZ=true" \
		-v "$(shell pwd)/tests/devbox.json:/tmp/devbox.json:ro" \
		-v "$(shell pwd)/tests/mise.toml:/tmp/mise.toml:ro" \
		$(INTERNAL_REG)/$(IMAGE_PLATFORM_TOOLKIT):$(INTERNAL_TAG) zsh

.PHONY: image-data
image-data:
	$(IMAGE_BUILDER) build \
		--target data_toolkit \
		-t $(INTERNAL_REG)/$(IMAGE_DATA_TOOLKIT):$(INTERNAL_TAG) .

.PHONY: run-data
run-data: image-data
	$(IMAGE_BUILDER) run --rm -it $(INTERNAL_REG)/$(IMAGE_DATA_TOOLKIT):$(INTERNAL_TAG) zsh
