# The official eufy-sdk bridge app image, plus runtime.patch (live audio and push-to-talk; see README.md).
# The official image already has the bridge in /app and the app's /run.sh as its command; this only patches
# /app. If the patch no longer applies to a newer base, the build fails and the installed version keeps
# running, so an update can't silently drop the feature.
ARG BUILD_FROM=ghcr.io/mega-yfue/addon-eufy-sdk-bridge:0.8.2
FROM ${BUILD_FROM}

# recordings.patch (door event recordings: /events, /event-thumb, /event-video) applies on top of runtime.patch.
COPY runtime.patch recordings.patch /tmp/
RUN apk add --no-cache --virtual .patch-deps patch \
 && cd /app \
 && patch -p1 --forward --no-backup-if-mismatch < /tmp/runtime.patch \
 && patch -p1 --forward --no-backup-if-mismatch < /tmp/recordings.patch \
 && for f in server.mjs go2rtc-config.mjs src/config.mjs src/http-routes.mjs src/live-audio.mjs src/talkback-route.mjs src/recordings.mjs src/warmup.mjs; do node --check "$f"; done \
 && apk del .patch-deps \
 && rm /tmp/runtime.patch /tmp/recordings.patch

LABEL \
    org.opencontainers.image.title="Home Assistant app: eufy-sdk bridge (patched)" \
    org.opencontainers.image.description="The official eufy-sdk bridge with a local live-audio and push-to-talk patch."
