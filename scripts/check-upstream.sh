#!/usr/bin/env bash
# Compare this app with the official eufy-sdk bridge app, and test the patch against it.
#
#   check-upstream.sh check    If the official app has a newer version than build.yaml pins: apply the
#                              patch to that version's bridge source, run the bridge's tests, build the
#                              app image on it, and update this repo's files (app folder + patches/).
#                              Does nothing when already up to date.
#   check-upstream.sh verify   Do the same tests and build for the version already pinned, changing no
#                              files. Run on every push, so a hand edit can't break the app unnoticed.
#
# Writes status=uptodate|updated|verified, official=<app version> and bridge=<bridge version> to
# $GITHUB_OUTPUT when set. Exits non-zero when the patch doesn't apply, a test fails or the build fails.
# Needs: git, curl, node 24 + npm, python3, docker.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP=$ROOT/eufy_sdk_bridge_patched
PATCH=$ROOT/patches/0001-live-audio-and-push-to-talk.patch
RAW=https://raw.githubusercontent.com/mega-yfue/ha-eufy-sdk-addon
BRIDGE_GIT=https://github.com/mega-yfue/ha-eufy-sdk-bridge.git
IMAGE=ghcr.io/mega-yfue/addon-eufy-sdk-bridge
MODE=${1:-check}
WORK=$ROOT/work
rm -rf "$WORK" && mkdir -p "$WORK"

out() { echo "$1=$2"; if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi; }
yaml_val() { sed -n "s/^ *$1: *\"\{0,1\}\([^\"]*\)\"\{0,1\} *$/\1/p" "$2" | head -1; }

pinned=$(sed -n "s|.*${IMAGE}:\([^ ]*\).*|\1|p" "$APP/build.yaml" | head -1)
pinned_bridge=$(yaml_val BRIDGE_VERSION "$APP/build.yaml")

case "$MODE" in
  check)
    curl -fsSL "$RAW/main/eufy_sdk_bridge/config.yaml" -o "$WORK/config.yaml"
    curl -fsSL "$RAW/main/eufy_sdk_bridge/build.yaml" -o "$WORK/build.yaml"
    official=$(yaml_val version "$WORK/config.yaml")
    bridge=$(sed -n 's|.*ha-eufy-sdk-bridge:\([^ ]*\).*|\1|p' "$WORK/build.yaml" | head -1)
    out official "$official"
    out bridge "$bridge"
    if [ "$official" = "$pinned" ]; then
      echo "Up to date: the official app is $official, and this app is built on it."
      out status uptodate
      exit 0
    fi
    echo "The official app moved from $pinned to $official (bridge $bridge)."
    ;;
  verify)
    official=$pinned
    bridge=$pinned_bridge
    out official "$official"
    out bridge "$bridge"
    ;;
  *) echo "usage: $0 check|verify" >&2; exit 2 ;;
esac
[ -n "$official" ] && [ -n "$bridge" ] || { echo "couldn't read the official versions" >&2; exit 1; }

echo "::group::Apply the patch to bridge $bridge"
git clone -q --depth 1 --branch "$bridge" "$BRIDGE_GIT" "$WORK/bridge"
git -C "$WORK/bridge" -c user.name=ci -c user.email=ci@localhost am --3way --keep-cr "$PATCH"
echo "::endgroup::"

echo "::group::Run the bridge's tests with the patch"
(cd "$WORK/bridge" && npm ci --no-audit --no-fund && npm test)
echo "::endgroup::"

if [ "$MODE" = check ]; then
  echo "::group::Update the app to $official"
  # The patch as it now applies to the new bridge (author and message kept from the original).
  git -C "$WORK/bridge" format-patch -1 --stdout --no-signature > "$PATCH"
  git -C "$WORK/bridge" diff HEAD~1 -- . ':!test' > "$APP/runtime.patch"
  python3 "$ROOT/scripts/make-app-config.py" "$WORK/config.yaml" "$official" "$APP/config.yaml"
  for f in translations/en.yaml icon.png logo.png; do
    curl -fsSL "$RAW/main/eufy_sdk_bridge/$f" -o "$APP/$f"
  done
  sed -i.bak -E "s|(${IMAGE}:)[^ ]+|\1${official}|; s|(BRIDGE_VERSION: )\"[^\"]*\"|\1\"${bridge}\"|" "$APP/build.yaml"
  rm -f "$APP/build.yaml.bak"
  python3 - "$APP/CHANGELOG.md" "$official" "$bridge" <<'EOF'
import sys
path, official, bridge = sys.argv[1:]
s = open(path).read()
entry = (f"## {official}-audio.1\n\n- Rebuilt on the official eufy-sdk bridge app {official} (bridge {bridge}); "
         "the patch applied and the bridge's tests passed.\n\n")
head, _, rest = s.partition("## ")
open(path, "w").write(head + entry + "## " + rest)
EOF
  echo "::endgroup::"
fi

echo "::group::Build the app image on $IMAGE:$official"
docker build --pull --build-arg "BUILD_FROM=$IMAGE:$official" -t eufy-sdk-bridge-patched:test "$APP"
docker run --rm --entrypoint sh eufy-sdk-bridge-patched:test -c \
  'test -f /app/src/live-audio.mjs && test -f /app/src/talkback-route.mjs && grep -q eufy_audio /app/go2rtc-config.mjs'
echo "::endgroup::"

out status "$([ "$MODE" = check ] && echo updated || echo verified)"
echo "OK: the patch applies to bridge $bridge, its tests pass, and the app builds on $IMAGE:$official."
