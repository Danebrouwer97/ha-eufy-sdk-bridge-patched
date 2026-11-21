# eufy-sdk bridge (patched)

A local copy of the official [eufy-sdk bridge](https://github.com/mega-yfue/ha-eufy-sdk-addon) Home
Assistant app, with one patch on top: **live sound from the cameras, and push-to-talk through the
doorbell's speaker.** It runs instead of the official app, not beside it.

## Why the patch exists

The doorbell's live view in Home Assistant had no sound, and there was no way to talk to whoever was
at the door, although the eufy app can do both.

The eufy library inside the bridge
([@mega-yfue/eufy-sdk](https://www.npmjs.com/package/@mega-yfue/eufy-sdk)) already supports both
directions:

- Its live stream delivers the camera's microphone audio, as AAC-LC or G.711 frames.
- Its `talkback()` sends AAC audio to the camera's speaker.

The bridge just never connects either one. Its `/stream` feed is raw H.264 video only, and go2rtc is
told to copy the video (`#video=copy`), so the audio is dropped before Home Assistant ever sees it.
There is also no route that takes audio *to* a camera.

The patch adds the two missing links. It's written to go upstream: tests included, no behaviour change
for anyone who turns it off.

## What it changes

All changes are in the bridge (`/app` in the image). The file is `runtime.patch`, the same change as
`../patches/0001-live-audio-and-push-to-talk.patch` minus its tests.

| Change | What it does |
|---|---|
| `src/live-audio.mjs`, new | `GET /audio/<serial>`: the camera's live audio. AAC-LC passes through as ADTS, and A-law gets a streaming WAV header. It only plays alongside an open `/stream`, never wakes a camera, and stops when the camera's last `/stream` ends, so it can't keep a battery doorbell awake. |
| `go2rtc-config.mjs` | Each camera's go2rtc stream lists the audio feed as a second source, converted to Opus (`#audio=opus`), so WebRTC viewers hear the camera. |
| `src/talkback-route.mjs`, new | `POST /talk/<serial>?format=s16le\|alaw`: plays the streamed body through the camera's speaker. It encodes with ffmpeg to AAC-LC 16 kHz and only works during a live view. |
| `src/config.mjs` | `BRIDGE_LIVE_AUDIO=0` turns the audio source off. `BRIDGE_TALK_ALLOW` lists who may talk; the default is loopback and the Supervisor network `172.30.32.0/23`. The bridge's HTTP has no auth, and LAN devices must not be able to speak through the door. |
| `src/http-routes.mjs` | Wires the two routes in, and stops a camera's audio when its last `/stream` closes. |

The bridge's test suite passes with the patch: 232 tests, 8 of them new.

### Why talk-back doesn't go through go2rtc

go2rtc can pass a microphone backchannel, but not from one go2rtc to another over RTSP. This was
tested with 1.9.9: the bridge's RTSP server never offers the backchannel track. Home Assistant's own
go2rtc pulls the bridge over RTSP, so a browser's microphone can't reach the bridge that way.

Instead, a small Home Assistant integration (`eufy_talk`, kept in the owner's home-setup project) takes microphone audio over
Home Assistant's websocket and streams it to `/talk`. A Talk button in a dashboard page sends it.

## Updating when the official app updates

A GitHub workflow in this repository (`.github/workflows/check-upstream.yml`) checks the official app
every day. When there's a new version, it applies the patch to that version's bridge, runs the bridge's
tests, builds this app on it, and opens a pull request with the update. Merging the pull request makes
Home Assistant offer the update for this app.

If the patch no longer applies or a test fails, it opens an issue instead, and Home Assistant keeps
running the current version.

## When the change lands upstream

A pull request to [ha-eufy-sdk-bridge](https://github.com/mega-yfue/ha-eufy-sdk-bridge) is planned.
Once a released version includes it:

1. Stop this app and set it not to start on boot.
2. Install and start the official app.
3. Uninstall this app.

The eufy integration keeps working throughout, because both apps use the same port and the same
bridge identity.

## Install

This repository: add `https://github.com/Danebrouwer97/ha-eufy-sdk-bridge-patched` under
**Settings → Apps → App store → ⋮ → Repositories**, then install **eufy-sdk bridge (patched)**.
