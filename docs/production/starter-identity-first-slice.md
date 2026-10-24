# Starter identity — bounded, unreleased first slice

Original independently reviewed component: `22bd6c9d38a280cf6d73c49d1058f4b7633d1f61`,
based on `c80a025930a7e27c6fc2def169b82b1e23d1e3f5` (PR #74).
The current integration candidate is based on released PR #75 main
`f900b54a2417d6192e5111f9239e8a4a10dfd371`, tree
`ed32741c360c27f3d5eb2c1cb4f47367b1bc6bec`.
It remains local and unreleased; component approval is not exact-integration,
browser/native, publication or rollout approval.

## Implemented contract

- `fireball` is a compatibility alias for existing **Fire**: 12 MP, range 3, power 100, existing fan/Burn and 100 JP. This is the parent's explicit repair inference, **not** evidence of historical Fireball mechanics. No other aliases or ability definitions were added.
- Canonical known/equipped/catalog projections leave raw base, learned and equipped records untouched. Unknown ownership remains queryable; unavailable known rows say “Unavailable — progress retained” without fabricated statistics or Equip controls. The original PR #74 base had no downstream ability-ID-triggered combat branch. Current Scout code does dispatch existing `quickstep`/`long_shot` IDs; those identities, range normalization and hit-secondary helpers are preserved, not replaced by this alias.
- An explicit user equip action admits owned, defined abilities, deduplicates canonical identities before the existing four-slot setter cap, and stores canonical IDs. UI learn auto-equip and toggles use that same setter. It does not rewrite prior raw learned/base records.
- One purchase quote supplies display/eligibility/cost and is recomputed at commit. Only explicit nonnegative integer prices are accepted; zero is free, not absent. Unknown, missing/invalid-price, secret, wrong-current-job, owned-alias and unaffordable requests never spend JP. Already-owned unpriced defined abilities remain equippable/usable.
- The current-job shop uses existing job definitions consistently on fresh start, reload and job changes. Character base ownership and cross-job learned/equipped abilities are retained; available JP is separate from historical job JP.
- Primary save restore preserves explicitly stored base ownership (including unknown IDs and explicit empty arrays) from existing `unit_resources`; absent fields still use existing defaults. Legacy catalog metadata is retained but non-authoritative. Save version stays **1**; queries and load never write disk.

## Consumer audit

The production ownership/purchase consumers are GameState, CharacterScreen, BattleScene and SaveSystem. `learn_ability` is called only from CharacterScreen and remains a JP-purchase API, not a grant API. WandererData's secret rewards are unconsumed metadata on this base; actual Orren encounter choices award existing gold/JP and story state. No production story ownership predicates were found. No teacher system or grant API was invented. These are static source observations, not a proof about arbitrary external/dynamic callers.

The slot SaveSystem still directly merges learned ownership and does not persist equipped ability arrays. No callers of its slot API were found outside its own file. It remains untouched; the derived current-job catalog does not depend on its stale raw catalog metadata.

## Explicit omissions and limits

- **No loadout migration.** Legacy empty equipment still means all usable known abilities and may exceed four. Existing oversized nonempty saved loadouts also are not capped on reads. Only explicit setter actions enforce the four-slot cap. A nonempty owned-but-unresolved selection remains unusable; it does not silently expand into all-known. Wholly unowned selections retain the historical fallback.
- No new explicit-empty semantics, revision flag, provenance relocation, slot-save equipment repair, old-save disk rewriting, refunds, prices, automatic ability grants or job-history unlock grants.
- No Slash/Holy Strike/Void Scar design; no Heal, Silence, status-on-hit/miss, Quickstep, range or terrain mechanic changes. Current PR #75 hit-gated damaging-secondary behavior and the deliberately retained status-only MISS+Blind gap remain unchanged. Defined but unpriced staged shop entries say “Not available for JP yet”; this patch is not an implementation audit of every owned advanced/secret ability.
- No GUI/browser acceptance, publication, PR, merge or deploy for this identity candidate. PR #74/#75 evidence belongs to those earlier released source trees, not this candidate.

## Original component verification (historical; not the new integration count)

Godot `4.6.3.stable.official.7d41c59c4`, isolated HOME/XDG, hash-verified local LFS assets, cold import without resource/parse errors. Initial pointer/import-sidecar failures were diagnosed and corrected, with failed logs retained outside the branch.

- New headless identity contract: **109 checks, 0 failures**; corrected-environment original-base RED: **23 checks, 12 intended failures**. Includes real CharacterScreen learn/toggle calls and BattleScene spawns, aliases, explicit setter cap, preserved uncapped legacy reads, prices/disabled reasons, double clicks, stale job/JP, fresh/reload/switch catalog consistency, raw unknown base/learned/equipped ownership, absent versus explicit-empty base fields, read-only in-memory and disk-hash checks, primary roundtrips, and practice baseline/retry/exit.
- Project gameplay/presentation runner: **16 contracts**, all green; **6,747 checks/assertions plus 10 terrain cycles**. Baseline runner also green. UI readability covers more now-resolved Fire rows, so its count rises from 2,465 to 2,505 without dropping assertions.
- Python tool suite **36/36**, story static check, script parse **66**, asset manifest **94**, HUD layout **30**, Orren story **31**, elemental resolver **9**, vow/sigil **23**, and faceted mesh bounds/normal checks pass.
- Static Godot checker passes with the same **19 pre-existing warnings**. Existing exit-only ObjectDB/resource diagnostics appear in baseline and patch and remain visible. No preload, import or script errors count as clean evidence.

Godot JSON numbers deserialize as floats; roundtrip tests compare persisted values, not numeric Variant types. Pure read tests require exact in-memory equality and unchanged disk SHA-256. Practice's existing checkpoint clears death presentation; exit restores the full baseline.
