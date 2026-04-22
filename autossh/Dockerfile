# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
ARG BUILD_FROM=ghcr.io/home-assistant/base:3.23
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8

RUN apk add --no-cache tzdata openssh vim curl autossh

COPY rootfs /
RUN chmod a+x /etc/services.d/autossh/run /etc/services.d/autossh/finish

# io.hass.* labels (name, description, type, version, arch, url) are
# injected by the Supervisor via --label on the build command.
LABEL \
    org.opencontainers.image.authors="Thomas Dietrich" \
    org.opencontainers.image.title="SSH Tunnel & Forwarding" \
    org.opencontainers.image.description="Permanent HA forwarding and domain linking through an SSH tunnel" \
    org.opencontainers.image.documentation="https://github.com/ThomDietrich/home-assistant-addons/blob/master/autossh/DOCS.md" \
    org.opencontainers.image.source="https://github.com/ThomDietrich/home-assistant-addons" \
    org.opencontainers.image.vendor="Thomas Dietrich" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.base.name="ghcr.io/home-assistant/base:3.23"
