# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20230202-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.14.3-erlang-25.2.3-debian-bullseye-20230202-slim
#
ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=25.2.3
ARG DEBIAN_VERSION=bullseye-20230202-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# Start with the builder image from the second Dockerfile
FROM ${BUILDER_IMAGE} as builder

# Install build dependencies from both Dockerfiles
RUN apt-get update -y && \
  apt-get install -y build-essential git npm python3 make cmake openssl libsrtp-dev ffmpeg-dev clang && \
  apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set working directory and environment variables
WORKDIR /app
ENV MIX_ENV="prod"

# Install Hex and Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Copy files and install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
COPY config config
RUN mix deps.compile

# Copy application code and assets
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets and code
RUN mix assets.deploy
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Copy release configuration
COPY rel rel

# Build the release
RUN mix release

# Start a new build stage for the running environment
FROM ${RUNNER_IMAGE}

# Install runtime dependencies
RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales libsrtp ffmpeg clang curl && \
  apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale and environment variables
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set work directory and permissions
WORKDIR "/app"
RUN chown nobody /app
ENV MIX_ENV="prod"

# Copy the compiled app
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/membrane_videoroom_demo ./

# Set user
USER nobody

# Set the command to run
CMD ["/app/bin/server"]
