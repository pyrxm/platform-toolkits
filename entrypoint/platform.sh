#!/bin/sh

PTK_CONFIG="${PLATFORM_TOOLKIT_CONFIG_PATH:-/tmp}"

[ -f "${PTK_CONFIG}/devbox.json" ] && ln -s "${PTK_CONFIG}/devbox.json" "${HOME}/devbox.json"
[ -f "${PTK_CONFIG}/.tool-versions" ] && ln -s "${PTK_CONFIG}/.tool-versions" "${HOME}/.tool-versions"

if [ -f "${HOME}/devbox.json" ] ; then
    if [ "$(command -v devbox || true)" != "" ] ; then
        PATH="${HOME}/.nix-profile/bin:${HOME}/.devbox/nix/profile/default/bin:${PATH}"

        echo
        echo "devbox.json found!"
        devbox install
    fi
fi

if [ -f "${HOME}/.tool-versions" ] ; then
    if [ -d "$HOME/.asdf" ] ; then
        ASDF_DIR="$HOME/.asdf"
        . "$ASDF_DIR/asdf.sh"
    fi
    if [ "$(command -v asdf || true)" != "" ] ; then
        echo
        echo "asdf .tools-versions found!"

        while read -r plugin version ; do
            echo "${version}" > /dev/null
            asdf plugin add "${plugin}"
        done < "${HOME}/.tool-versions"

        echo
        asdf install
    fi
fi

eval "$@"
