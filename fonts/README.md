# Fonts

## Active

| Family | Role | Source | Notes |
|---|---|---|---|
| **Trajan Pro** | Display + Headers | `fonts/TrajanPro-Regular.ttf` (brand-uploaded) | Roman-capitals face — no lowercase. Carries every UPPERCASE surface in the system. Only the Regular weight is shipped; the `@font-face` clamps weight 400–900 to it so calls to `font-weight: 700` don't synthesize-bold or fall back. If you need actual heavier weights, drop more `.ttf` files here and split the `@font-face` blocks. |
| **Crimson Text** | Body | Google Fonts (`@import`) | Old-style serif; italic for spoken thought. **Still a substitute** — awaiting a proprietary body face if one exists. |
| **Cormorant Garamond** | UI / fine labels | Google Fonts (`@import`) | Lighter weights for small chip labels and inline meta. **Still a substitute.** |
| **JetBrains Mono** | Numerics (HP, %s, IDs) | System fallback chain | No webfont — always rendered via the local stack. |

## ⚠ Remaining substitutions

- **Body** (Crimson Text) and **UI** (Cormorant Garamond) are still Google Fonts substitutes. If the brand has a proprietary body face (Sabon, Adobe Garamond, etc.), drop the `.ttf` / `.woff2` here, add a `@font-face` rule, and prepend the family to `--font-body` / `--font-ui` in `../colors_and_type.css`. Every component reads through those CSS vars — no other file needs to change.

## How to add a new face

1. Drop the `.ttf` / `.woff2` in this folder.
2. Add a `@font-face` block at the top of `../colors_and_type.css`, mirroring the Trajan Pro example (use a wide `font-weight` range if shipping a single file).
3. Prepend the family to the relevant CSS var (`--font-display`, `--font-header`, `--font-body`, `--font-ui`) so it sits ahead of the existing fallbacks.
4. Leave the fallbacks in place — they catch environments that can't load the file.
