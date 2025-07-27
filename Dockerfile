ARG ALPINE_VERSION="3.22"
ARG GOLANG_VERSION="1.24"
ARG DEFAULT_SHELL="zsh"
ARG NON_ROOT=true
ARG USERNAME="engineer"
ARG MICROSOCKS_VERSION="98421a21c4adc4c77c0cf3a5d650cc28ad3e0107" # use "master" for latest



## -------
# BASE IMAGE
## -------

# Dependencies
FROM registry.k8s.io/pause:3.10 AS dep_base_image_pause

# Base image builder
FROM alpine:${ALPINE_VERSION} AS base_image
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT

COPY --from=dep_base_image_pause /pause /bin/pause

RUN apk update --no-cache && \
    apk add --no-cache \
        busybox-extras \
        ${DEFAULT_SHELL} && \
    # Install git if default shell is zsh for oh-my-zsh
    if [ "${DEFAULT_SHELL}" = "zsh" ] ; then \
        apk add --no-cache git ; \
    fi

RUN if [ "${NON_ROOT}" = "true" ] ; then \
        adduser -D ${USERNAME}; \
    else \
        ln -s "${HOME}" /home/${USERNAME}; \
    fi



## -------
# NETWORK TOOLKIT
## -------

# Dependencies
FROM alpine:${ALPINE_VERSION} AS dep_network_toolkit_microsocks
ARG MICROSOCKS_VERSION

WORKDIR /tmp
ADD https://github.com/rofl0r/microsocks/archive/${MICROSOCKS_VERSION}.tar.gz /tmp/microsocks.tar.gz

RUN \
  echo "Installing build dependencies..." && \
  apk add --update --no-cache \
    git \
    build-base \
    tar && \
  echo "Building MicroSocks..." && \
    tar -xvf microsocks.tar.gz --strip 1 && \
    make && \
    chmod +x /tmp/microsocks && \
    mkdir -p /tmp/microsocks-bin && \
    cp -v /tmp/microsocks /tmp/microsocks-bin && \
    mv /tmp/microsocks-bin/microsocks /usr/local/bin/microsocks

# Network Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS network_toolkit_build
ARG USERNAME
ARG NON_ROOT

COPY --from=base_image / /
COPY --from=dep_network_toolkit_microsocks /usr/local/bin/microsocks /bin/microsocks

RUN apk update --no-cache && \
    apk add --no-cache \
        apache2-utils \
        bash \
        bind-tools \
        busybox-extras \
        curl \
        ethtool \
        iperf3 \
        iproute2 \
        iputils \
        lftp \
        mtr \
        net-tools \
        netcat-openbsd \
        nmap \
        nmap-scripts \
        openssh-client \
        openssl \
        perl-net-telnet \
        procps \
        rsync \
        socat \
        sudo \
        tcpdump \
        tcptraceroute \
        tshark \
        wget

RUN if [ "${NON_ROOT}" = "true" ] ; then \
        # Yes, I know... bad practice
        echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}-access ; \
    fi

# Final image
FROM scratch AS network_toolkit
ARG USERNAME
COPY --from=network_toolkit_build / /

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/pause"]



## -------
# PROXY TOOLKIT
## -------

# Proxy Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS proxy_toolkit_build

COPY --from=base_image / /
COPY --from=dep_network_toolkit_microsocks /usr/local/bin/microsocks /bin/microsocks

# TODO: investigate how to add mitmproxy
RUN apk update --no-cache && \
    apk add --no-cache \
        python3

# Final image
FROM scratch AS proxy_toolkit
COPY --from=proxy_toolkit_build / /
ARG USERNAME

EXPOSE 1080

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/microsocks"]



## -------
# PLATFORM TOOLKIT
## -------

# Dependencies
FROM golang:${GOLANG_VERSION}-alpine AS dep_platform_toolkit_asdf
ENV GOPATH="/go"

RUN test -d /go || mkdir /go
RUN apk update --no-cache && \
    apk add --no-cache \
        bash \
        git

RUN git clone https://github.com/asdf-vm/asdf.git /tmp/asdf

WORKDIR /tmp/asdf

RUN go install github.com/asdf-vm/asdf/cmd/asdf@$(git ls-remote --tags --sort=committerdate | grep -o 'v.*' | tail -1)


# Platform Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS platform_toolkit_build
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT

COPY --from=base_image / /
COPY --from=dep_platform_toolkit_asdf /go/bin/asdf /usr/bin/asdf

RUN apk update --no-cache && \
    apk add --no-cache \
        bash \
        bind-tools \
        coreutils \
        curl \
        git \
        net-tools \
        netcat-openbsd \
        sudo \
        shadow \
        xz

RUN if [ "${NON_ROOT}" = "true" ] ; then \
        # Yes, I know... bad practice
        echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}-access ; \
        install -d -m755 -o 1000 -g 1000 /nix ; \
    fi

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN curl -fsSL https://get.jetify.com/devbox | bash -s -- -f && \
    curl -fsSL https://nixos.org/nix/install | bash -s -- --no-daemon

RUN if [ "${DEFAULT_SHELL}" = "zsh" ] ; then \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ; \
        sed -i 's/plugins=(git)/plugins=(asdf git)/' "${HOME}/.zshrc" ; \
        echo 'export PATH=$HOME/.nix-profile/bin:$HOME/.devbox/nix/profile/default/bin:$PATH' >> "${HOME}/.zshrc" ; \
    else \
        echo 'export ASDF_DIR="$HOME/.asdf"' >> "${HOME}/.profile" ; \
        echo '. "$ASDF_DIR/asdf.sh"' >> "${HOME}/.profile" ; \
        echo 'export PATH=$HOME/.nix-profile/bin:$HOME/.devbox/nix/profile/default/bin:$PATH' >> "${HOME}/.profile" ; \
    fi

# Final image
FROM scratch AS platform_toolkit
ARG USERNAME
COPY --from=platform_toolkit_build / /
COPY entrypoint/platform.sh /entrypoint.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/bin/pause"]



## -------
# DATA TOOLKIT
## -------

# Data Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS data_toolkit_build
COPY --from=base_image / /

RUN apk update --no-cache && \
    apk add --no-cache \
        bind-tools \
        curl \
        mysql-client \
        net-tools \
        netcat-openbsd \
        postgresql-client \
        redis

# Final image
FROM scratch AS data_toolkit
ARG USERNAME
COPY --from=data_toolkit_build / /

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/pause"]
