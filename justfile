internal_registry := "localhost:5000"
image_builder := "podman"
image_prefix := "ptk"
internal_tag := `git rev-parse --short HEAD`

# List available recipes
default:
  @just --list

# Build the toolkit base image
[group('build')]
build-base-image:
  {{image_builder}} build \
    --target base_image \
    -t {{internal_registry}}/{{image_prefix}}-base:{{internal_tag}} .

# Build target image
[group('build')]
build-image target="network":
  {{image_builder}} build \
    --target "{{target}}_toolkit" \
    -t {{internal_registry}}/{{image_prefix}}-{{target}}-toolkit:{{internal_tag}} .

# Run the toolkit base image
[group('run')]
run-base-image: build-base-image
  {{image_builder}} run \
    --rm -it {{internal_registry}}/{{image_prefix}}-base:{{internal_tag}} zsh

# Run target image
[group('run')]
run-image target="network":
  @just build-image "{{target}}"
  {{image_builder}} run \
    --rm -it {{internal_registry}}/{{image_prefix}}-{{target}}-toolkit:{{internal_tag}} zsh

# Test Platform Toolkit image (hardcoded recipe)
[group('test')]
test-image-platform:
  @just build-image "platform"
  {{image_builder}} run \
    -e "PLATFORM_TOOLKIT_CHEZMOI_REPO=https://gist.github.com/f7c2e4748b80e311e2fd0d6d31fb866b.git" \
    -e "PLATFORM_TOOLKIT_INSTALL_OMZ=true" \
    -v "`pwd`/tests/devbox.json:/tmp/devbox.json:ro" \
    -v "`pwd`/tests/mise.toml:/tmp/mise.toml:ro" \
    --rm -it {{internal_registry}}/{{image_prefix}}-platform-toolkit:{{internal_tag}} zsh
