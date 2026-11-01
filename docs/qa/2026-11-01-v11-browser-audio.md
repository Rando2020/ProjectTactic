# Browser WebAudio A/B — 2026-11-01

Opened isolated diagnostic via supported Sites preview and clicked actual buttons in the supported cloud browser. No GPU/WebGL requirement or browser flags changed. Probe extracts the exact shipped Godot Bus class from index.js SHA256 e3f56ee40e6f84371053db06692cfac15e2c8659547b11c6b2dfa1996dabd981.

- Old add_bus(-1): AudioContext running, measured RMS0, peak0, no signal at destination analyser.
- Corrected bus_count growth: AudioContext running, RMS0.08483481564525135, peak0.1199999675154686, signal detected; expected result PASS.

Thus a successful click/unlock does not repair the old disconnected bus graph; corrected creation restores a measurable signal through FX→Game→Master→output. No human listening claim, no complete WebGL game acceptance, no physical phone claim.

Probe source builder: tools/audio_qa/build_web_audio_probe.py. Exact-engine graph regression: tools/audio_qa/test_web_bus_graph.cjs. Native PCM/cue checks are separate and include user-mute preservation, distinct channel/release/contact, bounded peaks and cancellation.
