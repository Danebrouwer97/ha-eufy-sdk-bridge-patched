# The official eufy-sdk bridge app image, plus runtime.patch (live audio and push-to-talk; see README.md).
# The official image already has the bridge in /app and the app's /run.sh as its command; this only patches
# /app. If the patch no longer applies to a newer base, the build fails and the installed version keeps
# running, so an update can't silently drop the feature.
ARG BUILD_FROM=ghcr.io/mega-yfue/addon-eufy-sdk-bridge:0.8.2
FROM ${BUILD_FROM}

COPY runtime.patch /tmp/runtime.patch
RUN apk add --no-cache --virtual .patch-deps patch \
 && cd /app \
 && patch -p1 --forward --no-backup-if-mismatch < /tmp/runtime.patch \
 && for f in go2rtc-config.mjs src/config.mjs src/http-routes.mjs src/live-audio.mjs src/talkback-route.mjs; do node --check "$f"; done \
 && apk del .patch-deps \
 && rm /tmp/runtime.patch

LABEL \
    org.opencontainers.image.title="Home Assistant app: eufy-sdk bridge (patched)" \
    org.opencontainers.image.description="The official eufy-sdk bridge with a local live-audio and push-to-talk patch."
