# Vaelthar: Eidolon Chronicles

A browser RPG built in React. Final Fantasy Tactics × Chrono Trigger × Birth by Sleep.

## Play It

```bash
npm install
npm run dev
```

Open http://localhost:5173

## Build for Deployment

```bash
npm run build
```

Output goes to `/dist` — deploy anywhere static (Netlify, Vercel, GitHub Pages).

---

## Game Systems

### ⚡ SURGE / DEFLECT Timing
- **SURGE**: When you cast a spell or attack, a glowing button flashes at the bottom of the screen. Click it during the window to deal **+45% bonus damage** on that hit.
- **DEFLECT**: When an enemy announces an attack, a shield button appears for 500ms. Click it to halve their damage.
- Each element has a **unique timing rhythm** — Thunder fires 4 rapid bursts, Ice fires one slow massive hit, Fire fires 3 medium hits, Wind fires 3 fast slashes, etc.

### 🟧 TEMPER / 🟪 ETHER (Armor)
Two separate armor values on every character and enemy:
- **Temper** (orange) = physical defense. Protects against Bleed, Knockdown, Slow.
- **Ether** (purple) = magical defense. Protects against Burn, Freeze, Stun, Silence, Curse.
- Armor reduces status chance by up to 85% when full. At zero armor, full base chance applies.
- Hits strip armor automatically. **+15% damage bonus** when hitting a target with 0 armor.

### 🔥 Elemental Surface Reactions
Apply surface states (Wet, Burning, Frozen, Cursed, Blessed) and then hit with a compatible element:
- 💧 + ❄ = **FREEZE** (hard to resist, Ether barely helps)
- 💧 + ⚡ = **ELECTRIFY** (same)
- 🧊 + ⚡ = **SHATTER** (×1.75 damage + shatter armor)
- 🔥 + 💧 = **Extinguish** (remove burn, apply wet)
- 💜 + ✨ = **Holy Purge** (×1.6 damage + party heal)
- ✨ + 🌑 = **Null Corrupt** (×1.6 damage + drain Ether)

### ⚡ 2-Way + 3-Way Elemental Combos
Chain different elements within 7 seconds to trigger massive combo attacks. 19 two-way combos, 10 three-way combos.

### 📖 32 Guardians (8 elements × 4 tiers)
- **Primal Guardian** (T1): Ignareth, Glacielle, Torvahk, Nerevan, Gorveth, Sylvara, Luminarch, Vaelthorn
- **Aspect** (T2), **Echo** (T3), **Shard** (T4) for each element
- Unlocked via Resonant JP level progression (Lv1 through Lv7)
- **Bahamut equivalent (Vaelthorn) requires 920 JP** — endgame grind target
- Summons use the elemental timing system too — calling Torvahk fires 4 rapid thunder strikes

### 💜 Resonance Window
When a corrupted Guardian drops to ≤20% HP, their Void Anchor is exposed. ATB pauses. Use Zane's **RESONATE** action (30 MP, 82% success for Resonant jobs) to shatter it. Success: Guardian freed, party healed, +50% JP bonus. Fail twice: Guardian goes BERSERK.

### 🔱 Limit Break
Each character has a gold gauge that fills when they take damage. At 100%, they can unleash a class-specific Limit Break:
- **Warder**: 3 hits all enemies, each strips 45 Temper
- **Arcanist**: Fire+Ice+Thunder simultaneously → forces TRI-NOVA combo
- **Resonant**: Grand Resonance — calls strongest available Guardian free
- **Luminary**: Full HP, max Ether, purge all, party Blessed
- ... unique per all 18 jobs

### ⚜ 18 Job Classes (9 Base + 9 Ascended)
Base classes: Warder, Arcanist, Resonant, Luminary, Skywarden, Chronist, Oathbound, Voidcaller, Null Resonant

Each has an **Ascended** version (800-1200 JP) with 6 skills, an always-active passive, and an enhanced Limit Break:
- **Null Breaker** (Warder+): passive strips 18 Temper per physical hit
- **Etherweaver** (Arcanist+): combo chains last 10 seconds instead of 7
- **Primal Binder** (Resonant+): all summons +20% power permanently
- **Seraph** (Luminary+): all healing also restores 35 Temper
- ... etc.

### 🧪 Items (Vaelthar-named)
- **Vitae Draught** — restore 200 HP
- **Resonance Phial** — restore 90 Ether
- **Ironcore Shard** — restore 90 Temper
- **Soul Ember** — revive KO'd ally at 60% HP
- **Null Bane** — cleanse all statuses

---


## Road to “Best Tactics RPG”

If your goal is to make this feel like a true tactics GOTY contender, focus your next iterations in this order:

1. **Battlefield Layer (Highest impact)**
   - Add grid positioning, height, and facing bonuses (front/side/back modifiers).
   - Keep current timing combat as the action-resolution layer after positional decisions.

2. **Role Identity + Party Builds**
   - Expand jobs into clear tactical archetypes (initiator, disruptor, anchor, finisher).
   - Add 2–3 cross-job passive slots to create buildcraft depth.

3. **Encounter Design**
   - Build map objectives beyond “defeat all” (protect target, survive turns, seize points).
   - Introduce enemy squads with synergies that force counter-play.

4. **Progression Loops**
   - Add town/prep phase: contracts, equipment upgrades, Guardian attunement.
   - Let players scout enemy elements before battle and reconfigure party.

5. **Presentation & UX Polish**
   - Improve timeline readability (turn order + status expiry markers).
   - Add clearer telegraphs for reaction setups and combo windows.

This game already has a strong identity through elemental timing + reactions. The biggest unlock is layering **positioning and objectives** on top of it.

---


## FFT/WotL-Inspired Tactical Layer (implemented prototype)

A new in-app **Tactics Prototype** mode is now available from the top-right toggle. It introduces core board concepts from FFT-style combat:

- Grid-based movement (8×8 tiles)
- Terrain types (plain/forest/water)
- Height values per tile
- Movement range using Manhattan distance
- Jump constraint (cannot traverse height deltas above Jump stat)
- Facing updates based on move direction

This is a foundation pass to start blending your existing timing/reaction combat with tactical positioning gameplay.


## VFX Asset Strategy (Do this now, but lightweight)

Short answer: **don't wait** for all custom effects. Use free licensed placeholders now, then replace later.

Recommended approach:
- Use **CC0 / permissive** packs for temporary spell FX while gameplay/UX is still moving.
- Track every asset in a simple credits sheet (`ASSET_CREDITS.md`) with source URL + license.
- Keep a consistent art direction pass later (same palette, frame rate, and blend style) before release.

Suggested free sources:
- Kenney (broad CC0 game assets)
- OpenGameArt (filter by CC0 / CC-BY and verify per-asset terms)
- itch.io free VFX packs (verify each creator's license text before import)

Priority order for your project right now:
1. Title screen / onboarding flow
2. Tactical controls + board readability
3. Placeholder VFX/SFX for player feedback
4. Final art pass and custom FX

## File Structure

```
vaelthar-chronicles/
├── index.html
├── package.json
├── vite.config.js
├── main.jsx
├── App.jsx
└── VaeltharChronicles.jsx   ← entire game (single file)
```

The entire game is one self-contained React component. No external game libraries.

---

## Enemy Waves

| Wave | Enemies | Notable |
|------|---------|---------|
| 1 | Null Drake | Intro wave, easy |
| 2 | Void Golem + Storm Imp | Dual enemies, armor test |
| 3 | **Ignareth [ENRAGED]** + Null Shade | First corrupted Guardian — Resonance Window available |
| 4 | **Nerevan + Sylvara + Luminarch** [corrupted] | Three Guardians, Resonance all three |
| 5 | **OMEGA NULL** | Final boss — regenerates Ether every action, strips armor aggressively |

---

## Lore

The **Null Conclave** excavated a pre-world ruin and found **Void Anchors** — shards of pure Null older than the elements. Driven into a Guardian's core, they corrupt its Ether from within. The Guardian feels only pain. It can't tell friend from foe.

You are a **Resonant** — one of the few whose Ether resonates with a Guardian's. Your job isn't to defeat them. It's to reach them through the corruption, shatter the Void Anchor, and bring them home.

**Omega Null** is not a Guardian. It is every Void Anchor ever planted, fused into a single weapon. It regenerates Ether because it *is* corrupted Ether, crystallized.
