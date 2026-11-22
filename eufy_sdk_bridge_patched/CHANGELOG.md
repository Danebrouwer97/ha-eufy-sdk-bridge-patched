# Changelog

## 0.8.2-audio.2

- Door event recordings: `GET /events/<serial>?days=7` lists a camera's recorded events (newest first: start,
  end, ring/person/motion) from its station's own database; `GET /event-thumb/<serial>/<id>` serves each event's
  picture (cached, newest 300 per camera); `GET /event-video/<serial>/<id>` serves its video as an mp4 (range
  requests; cached, newest 30). The video is downloaded from the station and its keyframes decrypted with the
  key derived from the code in the download answer (as in eufy-sdk issue #385), so no cipher key or owner
  account is needed. Verified on a Chime T8020 with a T8210 doorbell: 2048x1536 H.264 + AAC, zero decode errors.
  See `recordings.patch`.

## 0.8.2-audio.1

- First release: the official eufy-sdk bridge app 0.8.2 (bridge 0.7.2) plus live camera audio
  (`/audio/<serial>`, added to each go2rtc stream as Opus) and push-to-talk (`/talk/<serial>`).
