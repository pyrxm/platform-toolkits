internal_registry := "localhost:5000"
image_builder := "podman"
image_prefix := "ptk"
internal_tag := `git rev-parse --short HEAD`
current_dir := `pwd`

toolkit_default_shell := "zsh"
toolkit_username := "engineer"

# List available recipes
default:
  @just --list

# Build the toolkit base image
[group('build')]
build-base-image:
  {{image_builder}} build \
    --target base_image \
    --build-arg "DEFAULT_SHELL={{toolkit_default_shell}}" \
    --build-arg "USERNAME={{toolkit_username}}" \
    -t {{internal_registry}}/{{image_prefix}}-base:{{internal_tag}} . \
  && {{image_builder}} tag \
    {{internal_registry}}/{{image_prefix}}-base:{{internal_tag}} \
    {{internal_registry}}/{{image_prefix}}-base:latest

# Build target image
[group('build')]
build-image target="network":
  {{image_builder}} build \
    --target "{{target}}_toolkit" \
    --build-arg "DEFAULT_SHELL={{toolkit_default_shell}}" \
    --build-arg "USERNAME={{toolkit_username}}" \
    -t {{internal_registry}}/{{image_prefix}}-{{target}}-toolkit:{{internal_tag}} . \
  && {{image_builder}} tag \
    {{internal_registry}}/{{image_prefix}}-{{target}}-toolkit:{{internal_tag}} \
    {{internal_registry}}/{{image_prefix}}-{{target}}-toolkit:latest

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

# Test Platform Toolkit image configured from configuration files + variables
[group('test')]
test-image-platform:
  @just build-image "platform"
  {{image_builder}} run \
    -e "PLATFORM_TOOLKIT_CHEZMOI_REPO=https://gist.github.com/f7c2e4748b80e311e2fd0d6d31fb866b.git" \
    -e "PLATFORM_TOOLKIT_INSTALL_OMZ=true" \
    -v "{{current_dir}}/tests/devbox.json:/tmp/devbox.json:ro" \
    -v "{{current_dir}}/tests/mise.toml:/tmp/mise.toml:ro" \
    --rm -it {{internal_registry}}/{{image_prefix}}-platform-toolkit:{{internal_tag}} zsh

# Test Customized Platform Toolkit image built from Dockerfile
[group('test')]
test-image-platform-custom:
  @just build-image "platform"
  {{image_builder}} build \
    -f "{{current_dir}}/tests/Dockerfile" \
    --build-arg "BASE_IMAGE={{internal_registry}}/{{image_prefix}}-platform-toolkit:{{internal_tag}}" \
    -t {{internal_registry}}/{{image_prefix}}-custom-toolkit:{{internal_tag}} ./tests/ ; \
  {{image_builder}} run \
    -e "PLATFORM_TOOLKIT_INSTALL_OMZ=true" \
    --rm -it {{internal_registry}}/{{image_prefix}}-custom-toolkit:{{internal_tag}} zsh
