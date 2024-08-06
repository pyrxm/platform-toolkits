ARG ALPINE_VERSION="3.20"
ARG DEFAULT_SHELL="zsh"
ARG NON_ROOT=true
ARG USERNAME="engineer"

# -------
# BASE IMAGE
# -------
FROM alpine:${ALPINE_VERSION} AS base_image
ARG DEFAULT_SHELL
ARG USERNAME
ARG NON_ROOT

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

# USER ${USERNAME}
# WORKDIR /home/${USERNAME}

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
ARG DEFAULT_SHELL
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

CMD [ ${DEFAULT_SHELL} ]

# Final image
FROM scratch as network_toolkit
ARG USERNAME
ARG NON_ROOT
COPY --from=network_toolkit_build / /

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# -------
# PLATFORM TOOLKIT
# -------
FROM alpine:${ALPINE_VERSION} AS platform_toolkit
ARG USERNAME

COPY --from=base_image / /

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["sleep", "infinity"]
