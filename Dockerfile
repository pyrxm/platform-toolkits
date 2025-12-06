ARG ALPINE_VERSION="3.23"
ARG FEDORA_VERSION="43"
ARG GOLANG_VERSION="1.25"
ARG DEFAULT_SHELL="zsh"
ARG NON_ROOT=true
ARG USERNAME="engineer"
ARG MICROSOCKS_VERSION="v1.0.5" # use "master" for latest
ARG LOCAL_BIN_DIR="/home/${USERNAME}/.local/bin"



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

FROM fedora:${FEDORA_VERSION} AS base_image_fedora
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT

COPY --from=dep_base_image_pause /pause /bin/pause

RUN dnf update -y && \
    dnf install -y \
    git \
    curl \
    ${DEFAULT_SHELL} && \
    dnf clean all && \
    chmod 0640 /etc/shadow # PAM gets cranky otherwise

RUN if [ "${NON_ROOT}" = "true" ] ; then \
    useradd -m ${USERNAME} -s "$(command -v ${DEFAULT_SHELL})" ; \
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

FROM ghcr.io/natesales/q:latest AS dep_network_toolkit_q
ARG USERNAME

# Network Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS network_toolkit_build
ARG USERNAME
ARG NON_ROOT

COPY --from=base_image / /
COPY --from=dep_network_toolkit_microsocks /usr/local/bin/microsocks /bin/microsocks
COPY --from=dep_network_toolkit_q /usr/bin/q /bin/q

RUN apk update --no-cache && \
    apk add --no-cache \
    apache2-utils \
    bash \
    bind-tools \
    busybox-extras \
    curl \
    ethtool \
    gping \
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
    wget \
    xh

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

# Platform Toolkit Builder
FROM fedora:${FEDORA_VERSION} AS platform_toolkit
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT
ARG LOCAL_BIN_DIR

COPY --from=base_image_fedora / /

RUN if [ "${NON_ROOT}" = "true" ] ; then \
    # Yes, I know... bad practice
    echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}-access ; \
    fi

RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/bin

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV PATH="${LOCAL_BIN_DIR}:$PATH"

COPY assets/entrypoint/platform.sh /entrypoint.sh
COPY ./assets/tasks/taskfile.platform.yaml /home/${USERNAME}/taskfile.yaml

RUN task build-utils

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
