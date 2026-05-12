# Sprite Manifest

This manifest defines the first placeholder sprite set needed for a playable tactical RPG vertical slice.

## Naming Rules

- Use lowercase kebab-case.
- Include job, character, enemy, or action state.
- Include `placeholder` until final art is approved.
- Do not copy commercial game sprites or silhouettes directly.

## Player Units

| Unit | Job | Asset Name | Priority |
|---|---|---|---|
| Zane | Resonant | zane-resonant-idle-placeholder.png | High |
| Zane | Resonant | zane-resonant-cast-placeholder.png | Medium |
| Mira Vey | Luminary | mira-luminary-idle-placeholder.png | High |
| Mira Vey | Luminary | mira-luminary-heal-placeholder.png | Medium |
| Kael Orik | Warder | kael-warder-idle-placeholder.png | High |
| Kael Orik | Warder | kael-warder-slash-placeholder.png | Medium |

## Job Silhouette Placeholders

| Job | Asset Name | Notes |
|---|---|---|
| Warder | warder-idle-placeholder.png | Heavy frontline armor, broad weapon silhouette |
| Arcanist | arcanist-idle-placeholder.png | Robed elemental caster, readable staff shape |
| Resonant | resonant-idle-placeholder.png | Summoner/binder silhouette with ritual focus |
| Luminary | luminary-idle-placeholder.png | Healer with soft gold/white visual accents |
| Skywarden | skywarden-idle-placeholder.png | Spear/jump silhouette |
| Chronist | chronist-idle-placeholder.png | Clock, ring, or timepiece visual motif |
| Oathbound | oathbound-idle-placeholder.png | Shield and vow iconography |
| Voidcaller | voidcaller-idle-placeholder.png | Dark caster with violet-black accents |
| Null Resonant | null-resonant-idle-placeholder.png | Hybrid holy/dark resonance silhouette |

## Enemy Units

| Enemy | Asset Name | Priority |
|---|---|---|
| Null Drake | null-drake-idle-placeholder.png | High |
| Storm Imp | storm-imp-idle-placeholder.png | High |
| Fen Wraith | fen-wraith-idle-placeholder.png | Medium |
| Void Golem | void-golem-idle-placeholder.png | Medium |
| Null Shade | null-shade-idle-placeholder.png | Medium |

## Animation States for Later

Minimum state list:

```text
idle
move
attack
cast
hit
ko
victory
```

## Next Implementation Step

Create `src/game/data/assets.js` and map unit IDs, job IDs, and enemy IDs to placeholder sprite paths. Components should read from that registry instead of hardcoded strings.
