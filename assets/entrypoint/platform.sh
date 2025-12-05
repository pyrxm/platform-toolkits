#!/bin/sh

PTK_CONFIG="${PLATFORM_TOOLKIT_CONFIG_PATH:-/tmp}"

[ -f "${PTK_CONFIG}/devbox.json" ] && ln -s "${PTK_CONFIG}/devbox.json" "${HOME}/devbox.json"
[ -f "${PTK_CONFIG}/mise.toml" ] && ln -s "${PTK_CONFIG}/mise.toml" "${HOME}/.config/mise.toml"
[ -f "${PTK_CONFIG}/.tool-versions" ] && ln -s "${PTK_CONFIG}/.tool-versions" "${HOME}/.tool-versions"

[ -n "$(command -v mise)" ] && eval "$(mise activate --shims)"
[ -n "$(command -v devbox)" ] && eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r

task build-env

eval "$@"
