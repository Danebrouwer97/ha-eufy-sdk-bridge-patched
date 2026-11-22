# eufy-sdk bridge (patched)

A Home Assistant app repository with one app: the official
[eufy-sdk bridge](https://github.com/mega-yfue/ha-eufy-sdk-addon) plus **live camera sound and
push-to-talk**. The app's [README](eufy_sdk_bridge_patched/README.md) explains why the patch exists and
what it changes.

This is a stopgap. The change is meant for the official
[ha-eufy-sdk-bridge](https://github.com/mega-yfue/ha-eufy-sdk-bridge), and this repository goes away
once a release includes it.

## Install

1. In Home Assistant: **Settings → Apps → App store → ⋮ → Repositories**, add
   `https://github.com/Danebrouwer97/ha-eufy-sdk-bridge-patched`.
2. Install **eufy-sdk bridge (patched)**. Home Assistant builds it from the official image plus the
   patch, which takes a minute.
3. Stop the official eufy-sdk bridge app and set it not to start on boot. eufy allows one active login
   per account, so only one bridge can run.
4. Fill in the same options as the official app, and start it.

## Layout

| Path | What it is |
|---|---|
| `eufy_sdk_bridge_patched/` | The app. `Dockerfile` builds FROM the official app image and applies `runtime.patch`; `config.yaml` is generated from the official one. |
| `patches/0001-live-audio-and-push-to-talk.patch` | The full change to the bridge, tests included. It's the source of `runtime.patch`, and what goes upstream. |
| `patches/0002-door-event-recordings.patch` | Door event recordings (`/events`, `/event-thumb`, `/event-video`); the same file as the app's `recordings.patch`, applied after `runtime.patch`. |
| `scripts/check-upstream.sh` | Checks the official app for a new version, applies the patch to its bridge, runs the bridge's tests and builds the app. |
| `scripts/make-app-config.py` | Writes the app's `config.yaml` from the official one. |
| `.github/workflows/check-upstream.yml` | Runs the check daily. It opens a pull request when an update passes, and an issue when it doesn't. |

## Licences

The app files are derived from [ha-eufy-sdk-addon](https://github.com/mega-yfue/ha-eufy-sdk-addon)
(MIT, © mega-yfue) and are under the MIT licence in [LICENSE](LICENSE). The patch modifies
[ha-eufy-sdk-bridge](https://github.com/mega-yfue/ha-eufy-sdk-bridge) (Apache-2.0, © mega-yfue) and is
offered under the same Apache-2.0 licence, in [LICENSE-APACHE](LICENSE-APACHE). Changed files are listed
in the patch itself.

Not affiliated with eufy, Anker or the official bridge project.
