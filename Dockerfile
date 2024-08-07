ARG ALPINE_VERSION="3.20"
ARG DEFAULT_SHELL="zsh"
ARG NON_ROOT=true
ARG USERNAME="engineer"

# -------
# BASE IMAGE
# -------
#
# Dependencies
FROM registry.k8s.io/pause:3.10 AS dep_base_image

# Base image builder
FROM alpine:${ALPINE_VERSION} AS base_image
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT

COPY --from=dep_base_image /pause /bin/pause

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

# RUN if [ "${DEFAULT_SHELL}" = "zsh" ] ; then \
#         sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" ; \
#     fi

# -------
# NETWORK TOOLKIT
# -------
#
# Dependencies
FROM ghcr.io/httptoolkit/docker-socks-tunnel AS dep_network_toolkit_microsocks

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

# -------
# PROXY TOOLKIT
# -------
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

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/microsocks"]

# -------
# PLATFORM TOOLKIT
# -------
# Platform Toolkit Builder
FROM alpine:${ALPINE_VERSION} AS platform_toolkit_build
ARG USERNAME

COPY --from=base_image / /

RUN apk update --no-cache && \
    apk add --no-cache \
        bind-tools \
        curl \
        net-tools \
        netcat-openbsd

# Final image
FROM scratch AS platform_toolkit
ARG USERNAME
COPY --from=platform_toolkit_build / /

USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/pause"]

# -------
# DATA TOOLKIT
# -------
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
