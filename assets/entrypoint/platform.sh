#!/usr/bin/env bash

PTK_CONFIG="${PLATFORM_TOOLKIT_CONFIG_PATH:-/tmp}"

[ -f "${PTK_CONFIG}/devbox.json" ] && ln -s "${PTK_CONFIG}/devbox.json" "${HOME}/devbox.json"
[ -f "${PTK_CONFIG}/devbox.lock" ] && ln -s "${PTK_CONFIG}/devbox.lock" "${HOME}/devbox.lock"
[ -f "${PTK_CONFIG}/mise.toml" ] && ln -s "${PTK_CONFIG}/mise.toml" "${HOME}/.config/mise.toml"
[ -f "${PTK_CONFIG}/.tool-versions" ] && ln -s "${PTK_CONFIG}/.tool-versions" "${HOME}/.tool-versions"

if [ -n "$(command -v devbox)" ] ; then
    export PATH="${HOME}/.nix-profile/bin:${HOME}/.devbox/nix/profile/default/bin:${PATH}"
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    eval "$(devbox global shellenv)"
fi

[ -n "$(command -v mise)" ] && eval "$(mise activate --shims)"

task build-env

eval "$@"
