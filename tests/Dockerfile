ARG BASE_IMAGE="localhost:5000/ptk-platform-toolkit:latest"

FROM ${BASE_IMAGE} AS custom_toolkit

ENV PLATFORM_TOOLKIT_CONFIG_PATH="/tools"
COPY . "${PLATFORM_TOOLKIT_CONFIG_PATH}"

RUN /entrypoint.sh
