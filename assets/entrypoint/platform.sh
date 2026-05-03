#!/usr/bin/env bash

export PTK_INIT="${HOME}/.ptk-init"

if [ -n "$(command -v devbox)" ] ; then
    export PATH="${HOME}/.nix-profile/bin:${HOME}/.devbox/nix/profile/default/bin:${PATH}"
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    eval "$(devbox global shellenv)"
fi

[ -n "$(command -v mise)" ] && eval "$(mise activate --shims)"

[ ! -f "${PTK_INIT}" ] && task build-env

eval "$@"
