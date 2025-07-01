# Dockerfile: builder for Alpine ARM64 SD‑card image
FROM alpine:3.19 AS builder

# install build tools inside container
RUN apk add --no-cache \
      bash \
      apk-tools \
      alpine-sdk \
      curl \
      qemu-user-static \
      util-linux \
      parted \
      e2fsprogs \
      dosfstools \
      squashfs-tools

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

# entrypoint runs the build script, which emits /out/rg353vs-alpine.img
ENTRYPOINT ["/usr/local/bin/build.sh"]
