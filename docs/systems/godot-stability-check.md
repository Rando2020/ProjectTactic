# Godot Stability Check

Run the fast static pass from the repository root before opening or reloading
the Godot editor:

```cmd
tools\check_godot_stability.cmd --skip-godot
```

The command uses the repo's Node-based checker, so it does not require Python.

Run the full pass when you want the best local signal available:

```cmd
tools\check_godot_stability.cmd
```

The full command performs the same static pass, then attempts a supported Godot
headless reload smoke command. On this workstation, Godot 4.6.2 headless has
crashed with signal 11 even for clean quit-style checks, so a headless crash is
reported as a warning by default. The editor reload remains the final validator
until the engine/headless crash is resolved.

Static checks fail on issues that have already broken editor reloads:

- missing literal `preload("res://...")` resources
- duplicate function declarations in one script
- corrupted/mojibake text in GDScript files
- accidental `Color.faded()` calls
- autoload singletons hidden by same-name `class_name` declarations
- direct calls to non-static methods on a `class_name`
- unsupported Godot CLI references that came from older local check attempts
- obvious empty blocks after `if`, `for`, `while`, `match`, and `func`

Static checks warn on issues that often become editor warnings or reload churn:

- unnecessary `await` on local functions that do not yield
- function parameters that appear unused and are not prefixed with `_`
- locals and parameters that shadow common Godot names such as `name`, `size`,
  `tr`, `visible`, and `wrap`
- constants that shadow global script classes, such as
  `const CombatFormula := preload(...)`
- `Dictionary.get()` assignments where Godot may infer a `Variant`
- missing dynamic `load("res://...")` targets

To make warnings fail the command during cleanup passes, use:

```cmd
tools\check_godot_stability.cmd --skip-godot --warnings-as-errors
```

For automation that should fail when the headless smoke crashes, use:

```cmd
tools\check_godot_stability.cmd --strict-godot
```

## Interpreting Godot Smoke Results

The full checker classifies Godot CLI failures into three likely buckets:

- `permission/cache setup issue`: Godot could not create or write its editor
  data/cache folders. Run from a normal local shell with writable
  `%APPDATA%\Godot` and `%LOCALAPPDATA%\Godot`, or create those folders before
  re-running.
- `project parse/compile issue`: the project has a script error the static pass
  did not catch. Open the editor output panel and fix the first parse error.
- `Godot/headless engine crash`: the CLI hit the current signal 11 crash. Treat
  the static pass plus an editor reload/playtest as the validation path.

Recommended local loop:

1. Run `tools\check_godot_stability.cmd --skip-godot`.
2. Fix any `FAIL` lines. Treat `WARN` lines as cleanup unless you are in a
   warning-strict pass.
3. Run `tools\check_godot_stability.cmd`.
4. Reload the Godot editor and confirm the Output panel has no new red parse
   errors.
