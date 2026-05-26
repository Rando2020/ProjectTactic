# Godot Stability Check

Run this from the repository root before opening or reloading the Godot editor:

```cmd
tools\check_godot_stability.cmd
```

The command uses the repo's Node-based checker, so it does not require Python.

The checker performs a fast static pass over the Godot scripts and then attempts
a supported Godot headless reload smoke command. On this workstation, Godot
4.6.2 headless currently crashes with signal 11 even for a clean quit command,
so the smoke crash is reported as a warning by default. The editor reload remains
the final validator until the engine/headless crash is resolved.

Static checks fail on issues that have already broken editor reloads:

- missing literal `preload("res://...")` resources
- duplicate function declarations in one script
- corrupted/mojibake text in GDScript files
- accidental `Color.faded()` calls
- unsupported Godot CLI references that came from older local check attempts
- obvious empty blocks after `if`, `for`, `while`, `match`, and `func`

For automation that should fail when the headless smoke crashes, use:

```cmd
tools\check_godot_stability.cmd --strict-godot
```
