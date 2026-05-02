#!/usr/bin/env bash

PTK_CONFIG="${PLATFORM_TOOLKIT_CONFIG_PATH:-/tmp}"
PTK_INIT="${HOME}/.ptk-init"

PTK_CONFIG_FILES=(
    "devbox.json"
    "devbox.lock"
    "mise.toml"
    ".tool-versions"
)

for PTK_CFILE in "${PTK_CONFIG_FILES[@]}" ; do
    if [ -f "${PTK_CONFIG}/${PTK_CFILE}" ] && [ ! -e "${HOME}/${PTK_CFILE}" ] ; then
        ln -s "${PTK_CONFIG}/${PTK_CFILE}" "${HOME}/${PTK_CFILE}"
    fi
done

if [ -n "$(command -v devbox)" ] ; then
    export PATH="${HOME}/.nix-profile/bin:${HOME}/.devbox/nix/profile/default/bin:${PATH}"
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    eval "$(devbox global shellenv)"
fi

[ -n "$(command -v mise)" ] && eval "$(mise activate --shims)"

[ -f "${PTK_INIT}" ] && task build-env && touch "${PTK_INIT}"

eval "$@"
