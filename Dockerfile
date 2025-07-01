ARG ALPINE_VERSION=3.19
FROM --platform=$TARGETPLATFORM alpine:${ALPINE_VERSION}

# set a default timezone (optional)
ENV TZ=UTC

# enable the community repository so we can install qemu-user-static
RUN sed -i \
    -e 's|/v'"${ALPINE_VERSION}"'/main|&\n/v'"${ALPINE_VERSION}"'/community|' \
    /etc/apk/repositories

# update + install build tools (including qemu-user-static)
RUN apk update && apk add --no-cache \
      bash \
      alpine-sdk \
      curl \
      qemu-user-static \
      util-linux \
      parted \
      e2fsprogs \
      dosfstools \
      squashfs-tools \
    && rm -rf /var/cache/apk/*

# create a default non‑root user
ARG USER=player
ARG UID=1000
ARG GID=1000
RUN addgroup -g ${GID} ${USER} \
  && adduser -u ${UID} -G ${USER} -s /bin/bash -D ${USER} \
  && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/bin/sh"]
