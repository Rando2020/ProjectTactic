# Tactics Reference Notes

This project can use tactical RPGs as design references while keeping all implementation,
data, art, names, maps, formulas, scripts, and code original to Project-Tactics.

## User-Supplied Video References

- https://www.youtube.com/watch?v=iXnKYtTZrAo
- https://www.youtube.com/watch?v=wn4CLCNdujs

Use these as visual/design references only. Pull out observable ideas such as camera
angle, map readability, animation pacing, turn feedback, UI clarity, and player flow.
Do not copy proprietary assets, audio, scripts, dialogue, maps, character designs, or
implementation details.

## Final Fantasy Tactics References

Useful public reference areas:

- Wikipedia: high-level context for FFT's release history, genre, development context,
  reception, and remaster notes.
- Final Fantasy Wiki / Fandom: public game-derived reference pages for jobs, abilities,
  stats, terminology, and mechanics summaries.
- StrategyWiki: public gameplay reference material such as battle flow, EXP/JP, party
  progression, and tactical systems.
- Final Fantasy Hacktics: community research on FFT data, tools, file structures, and
  assembly-level behavior.
- FFT fan documentation and battle-system notes: useful for understanding the shape of
  systems such as charge time, height-aware tiles, facing, movement, job data, and
  ability targeting.
- Public reporting around The Ivalice Chronicles: useful confirmation that even Square
  Enix had to reconstruct behavior from available retail versions and fan-preserved
  data after original source was lost.

Safe takeaways for Project-Tactics:

- Use a data-driven unit/job/ability model.
- Represent maps as tiles with height, walkability, movement cost, and occupancy.
- Build a deterministic battle loop with explicit phases: select unit, preview movement,
  preview action, commit, resolve, advance timeline.
- Prefer readable tactical feedback over hidden math: highlight reachable tiles, target
  tiles, area effects, height issues, and turn order changes.
- Treat camera, cursor, and tile selection as first-class systems rather than one-off
  prototype logic.
- Use wiki/reference pages to understand categories and relationships, such as how jobs,
  learned abilities, stats, equipment, EXP, and JP interact.

Avoid:

- Copying FFT names, sprites, sounds, maps, scenario text, formulas verbatim, binary
  data, disassembled code, or ROM-derived assets.
- Building from leaked or unauthorized material.
- Depending on exact proprietary values when original, tunable equivalents are enough.
- Treating wiki tables as drop-in data. Convert observations into original Project-Tactics
  concepts, names, progression curves, and balance values.

## Triangle Strategy / Project Triangle Strategy References

Triangle Strategy was announced under the working title Project Triangle Strategy. It is
a useful reference for modern tactics presentation and HD-2D readability, not a source
for code or assets.

Safe takeaways for Project-Tactics:

- Modern tactics games benefit from strong terrain readability and vertical silhouettes.
- Preview UI matters: show action consequences before commitment where possible.
- Positioning systems should make flanking, back attacks, elevation, and hazards legible.
- Story choices and tactical encounters can share data hooks without tying the engine to
  a specific campaign.

Avoid:

- Attempting to obtain or use Triangle Strategy source code.
- Copying its HD-2D assets, shaders, character designs, dialogue, names, or encounter
  layouts.

## Project-Tactics Direction

The clean-room approach:

1. Observe public gameplay and public documentation.
2. Write original requirements in plain language.
3. Implement original systems in this repository.
4. Use our own data, assets, tuning values, and names.
5. Keep reference notes separate from source implementation details.

Near-term engineering targets:

- Add a tactical grid model with tile height and occupancy.
- Add unit turn timeline / charge-time style scheduling.
- Add movement and targeting previews.
- Add data files for original jobs, units, and abilities.
- Build a small original vertical test map for iteration.
