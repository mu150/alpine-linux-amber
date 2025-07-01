# Dockerfile
# -----------------------------------------------------------------------------
# Alpine Linux base for RG353VS (Allwinner A55 / ARM64)
# -----------------------------------------------------------------------------
ARG ALPINE_VERSION=3.19
FROM --platform=$TARGETPLATFORM alpine:${ALPINE_VERSION}

# set a default timezone (optional)
ENV TZ=UTC

# update & install common packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
      bash \
      ca-certificates \
      sudo \
      openssh \
      curl \
      util-linux \
      && rm -rf /var/cache/apk/*

# create a default user (optional)
ARG USER=player
ARG UID=1000
ARG GID=1000
RUN addgroup -g ${GID} ${USER} \
  && adduser -u ${UID} -G ${USER} -s /bin/bash -D ${USER} \
  && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# switch to non‑root by default
USER ${USER}
WORKDIR /home/${USER}

# set a minimal entrypoint
ENTRYPOINT ["/bin/sh"]
