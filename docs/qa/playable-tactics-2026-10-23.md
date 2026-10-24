# Playable tactics evidence, 2026-10-23

- Godot 4.6.2 real scene integration: 43 checks passed after the final VFX lifetime correction, with no runtime script errors. Two resources still report in-use warnings at process shutdown.
- Includes a standalone battle and two generated encounter victories, actual deployment validation, waiting for human input, ability-before-movement, buff safety, advanced job gating, rewards, route and boon checkpoints.
- The first deeper run exposed delayed death VFX retaining freed units. The resolver now captures their grid coordinate instead.
- The provided cloud browser reported missing WebGL2 and Secure Context at the managed HTTP preview. Browser playthrough and visual acceptance are therefore unverified in this environment. No browser security workaround was applied.
- Earlier PR art screenshots are historical evidence only, not a playtest of this new build.
- Desktop browser acceptance: start a descent, deploy, move/attack/cast, win, Continue, pick a boon, reload and Continue Descent, inspect jobs, then test defeat/retry. Verify music toggle and target readability at 1366x768.
