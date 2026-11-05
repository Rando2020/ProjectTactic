# Shared stats, equipment, and company screen validation

Base: main 5941987. Engine: Godot 4.6.2. Scope: party stat composition, owned equipment, character/jobs UI, save compatibility.

## Verified locally
- Equipment behavioral tests: slot validation, ownership, shared battle/roster values, resource initialization, serialization, legacy names, health clamp/no healing exploit, actual equipment button, earned job selection, disk save/reload.
- Character screen layout: 732 checks, including real keyboard input, focus visibility, rapid selection, and resize at 1328x861, 1920x1080, and 3840x2160 with native/scaled canvases.
- Progression speed: 73 checks, preserving positive speed floor and configured nonpositive factory behavior.
- Playable loop: 427 assertions pass. The run reports two resources still in use at shutdown; this is not a clean shutdown result.
- Starter identity: 109 checks, preserving existing ability and practice contracts.
- Tactical contract integration: 30 checks.
- Combat formula regression test passes.
- Production script parser passes (74 scripts).
- Native OpenGL-rendered roster and job screenshots inspected at 1920x1080. Existing portraits and sprite assets are reused.

Each behavioral test runs with a separate APPDATA directory inside the worktree; player saves are not used.

## Limits
Local Web export attempted but blocked because matching web_nothreads_debug.zip and web_nothreads_release.zip templates are absent. No local browser-playability claim is made. PR CI has template installation and browser smoke workflows; check their results before merge. No deployment was triggered.

Special loot affixes (elemental damage, JP gain, on-kill healing) remain unavailable for equipping until their hooks are implemented. The UI marks these items unavailable rather than silently promising their effects. Armor slots and sell/discard are future work. This pass is a foundation and cohesive UI revision, not final reference-image parity.
