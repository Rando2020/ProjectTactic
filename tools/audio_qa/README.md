# Demo audio regression — 2026-11-01

## Root cause, not an assumed mute setting

The demo creates Game, Music and FX buses at runtime. Godot 4.6.3's C++
`AudioServer::add_bus` normalizes append positions to `-1` and passes that to
`AudioDriverWeb::add_sample_bus`. The exact shipped Web engine's `Bus.addAt(-1)`
then calls `move`, whose `splice(toIndex-1,...)` moves the new bus ahead of the
existing Master. C++ and Web bus indices diverge. Applying the demo's sends then
creates disconnected/cyclic routes: none of the four buses reaches destination.
This reproduces with the shipped engine's actual Bus class, not a replacement.

Primary source:
- https://github.com/godotengine/godot/blob/4.6.3-stable/servers/audio/audio_server.cpp#L862-L913
- https://github.com/godotengine/godot/blob/4.6.3-stable/platform/web/audio_driver_web.cpp#L367-L376

Fix: grow `AudioServer.bus_count` when creating a missing named bus. Its `setCount`
path preserves Master and appends buses consistently. Names, hierarchy, saved
volume/mute choices and low-latency default Sample playback remain unchanged.
Passing explicit `add_bus(bus_count)` is NOT a fix: C++ normalizes that to `-1`.
No engine JavaScript patch or global Stream playback workaround is used.

## Reproduction and tests

```sh
node tools/audio_qa/test_web_bus_graph.cjs /path/to/exact/export/index.js
python tools/audio_qa/build_web_audio_probe.py /path/to/exact/export/index.js /tmp/probe.html
godot --headless --path demos/isometric-2v2 --scene res://tests/modular/test_audio.tscn
```

The JS regression extracts the actual exported Bus class. Legacy operations must
reproduce four disconnected outputs; fixed count-growth must produce four valid
output paths. It also checks the app uses the safe path.

The standalone HTML probe creates a real AudioContext from a button gesture,
routes a quiet known PCM tone through FX→Game→Master, and reports analyser RMS,
peak and context state. It needs no WebGL. The two buttons compare broken and fixed
bus creation. This file is diagnostic only, not a game deployment change.

Native audio checks: 27 pass, including bus idempotence/hierarchy, honoring zero FX
volume, valid distinct PCM, safe headroom, extended demo Fire windup, unchanged
legacy Fire WAV and exactly one Fire cue identity with stoppable voice.
Cancellation and actual Skirmish presentation regressions: 9 +105 pass.
These tests do not claim physical listening or browser acceptance.

## Cue readability

The old generated charge and release were identical .25-second waveforms. At
node gain they peaked around -33dBFS, RMS around -42dBFS: quiet even after routing
is fixed. New deterministic original cues have distinct builds/releases/contacts:

| Cue | Duration | Peak after node gain | RMS after node gain |
|---|---:|---:|---:|
| Charge | .60s | -10.50dBFS | -17.83dBFS |
| Release/fizzle | .20s | -10.50dBFS | -24.20dBFS |
| Contact | .23s | -10.50dBFS | -25.90dBFS |
| Heal | .40s | -10.50dBFS | -20.80dBFS |

These levels are before user bus settings. No settings are overridden. Only the
2D authored-demo Fire charge uses the shared .60s build; its original WAV and all
legacy cues remain unchanged. Existing ticket cancellation/phase-end ownership
stops the returned player normally. No combat costs, damage or turn rules changed.
