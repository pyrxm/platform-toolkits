# Simple build arg I can over-write in justfile.
ARG BASE_IMAGE="localhost:5000/ptk-platform-toolkit:latest"

# Using BUILD_IMAGE build arg, but in the real world you'd use:
#   ghcr.io/pyrxm/ptk-platform-toolkit:latest
FROM ${BASE_IMAGE} AS custom_toolkit

# Set an "out of the way" location for placing devbox.json, mise.toml, etc.
# The image will automatically pick up the files from here and configure your
# environment.
ENV PLATFORM_TOOLKIT_CONFIG_PATH="/tools"
COPY . "${PLATFORM_TOOLKIT_CONFIG_PATH}"

# Running the entrypoint script during build will install all your tools,
# one complete it will mark the operation as done and not re-run at container
# run time.
RUN /entrypoint.sh
