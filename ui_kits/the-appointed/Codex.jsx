// Codex.jsx — character sheet / lore explorer
const { useState: useStateCD } = React;

const CODEX_NARRATIVE = {
  aeryn: {
    costumeDescription: "Aeryn doesn't experience pride as vanity. They experience it as clarity. The world has a right and a wrong and Aeryn can see which is which. This certainty has saved the party many times. It has also cost them things they haven't finished counting.",
    surfacePersonality: "The leader. Magnetic, decisive, genuinely moral. The one people naturally defer to because Aeryn is usually right. Calm in crisis. Absolute in judgment.",
    wound: "Aeryn is terrified of being wrong — not for practical reasons but because their entire architecture of self is built on being right. If they are wrong about this, they might be wrong about everything. And if they're wrong about everything, what are they?",
    crackEvent: "Aeryn meets a soul on the mountain who did exactly what they did — same certainty, same mandate, same peace in the doing of it — for a cause that history has judged catastrophically wrong. How do I know the difference between my certainty and theirs?",
    resolution: "Dignity without the armor of certainty. The capacity to act without God guaranteeing the outcome in advance. Conviction that can hold uncertainty rather than being destroyed by it.",
    flavor: "Carries conviction like a weapon and has never considered that weapons cut both directions."
  },
  brennan: {
    costumeDescription: "Brennan doesn't experience wrath as cruelty. They experience it as the only honest response to injustice. The cause is real. The targets deserve it. Brennan has receipts.",
    surfacePersonality: "The fist. Direct, fearless, blunt as iron. The one who walks toward what others walk around. People follow Brennan into rooms they would never enter alone.",
    wound: "There is a child inside Brennan that was not protected when it should have been, and that child decided very early that the way to never be unsafe again was to become the most dangerous thing in any room.",
    crackEvent: "Brennan meets Moses on the mountain. The man who killed for justice and was put down for forty years to learn what it cost. The conversation lasts a long time.",
    resolution: "Anger as instrument, not identity. The capacity to be the fierce one without needing to be only the fierce one. Tenderness alongside teeth.",
    flavor: "Burning with a fire that has not yet decided whether it is heating the room or consuming it."
  },
  solan: {
    costumeDescription: "Solan doesn't experience sloth as laziness. They experience it as the discipline of not-acting. Of refusing to feed energy into a system that is already taking too much.",
    surfacePersonality: "The still one. Quiet, contemplative, observes more than speaks. Has a quality of presence that calms rooms — and sometimes hides in it.",
    wound: "Solan acted once, fully, with all of themselves, and what they loved died anyway. They have never told anyone this. They are not sure they remember it clearly themselves.",
    crackEvent: "Anamnesis returns a memory fragment Solan did not ask for. They are five years old. They are holding something that is no longer breathing. The fragment ends there.",
    resolution: "Stillness chosen, not retreated to. The capacity to be present to what is happening without needing to be elsewhere. Sacred rest as gift, not as hiding place.",
    flavor: "Watches the fire so carefully you forget they have hands."
  },
};

function CodexNav({ items, selectedId, onSelect, tier }) {
  return (
    <div className="codex-list">
      <div className="group">The Seven</div>
      {THE_SEVEN.map((c) => (
        <button key={c.id} className={`item${c.id === selectedId ? ' selected' : ''}`} onClick={() => onSelect(c)}>
          <span className="swatch" style={{ background: c.color }} />
          <span>{c.name}</span>
          <span className="muted" style={{ marginLeft: 'auto', fontStyle: 'italic', fontSize: 11 }}>{c.sin}</span>
        </button>
      ))}
      <div className="group">Antechamber</div>
      {HUB_LOCATIONS.slice(0, 3).map((l) => (
        <button key={l.id} className="item" onClick={() => {}}>{l.keeper}</button>
      ))}
      {HUB_LOCATIONS.slice(3).map((l) => (
        <button key={l.id} className={`item${l.tier > tier ? ' locked' : ''}`}>{l.tier > tier ? '— sealed —' : l.keeper}</button>
      ))}
      <div className="group">Fallen Angels</div>
      {BOSSES.map((b) => (
        <button key={b.id} className={`item${tier < 3 ? ' locked' : ''}`}>
          {tier < 3 ? '— unrevealed —' : b.title}
        </button>
      ))}
    </div>
  );
}

function CodexDetail({ char, tier }) {
  const lore = CODEX_NARRATIVE[char.id] || CODEX_NARRATIVE.aeryn;
  const trueRevealed = tier >= 4;
  return (
    <div className="codex-detail">
      <div className="codex-head">
        <div className="codex-portrait" style={{ color: char.color, borderColor: char.color, background: `${char.color}22` }}>
          {char.glyph}
        </div>
        <div>
          <div className="eyebrow ash">The {char.sin}-bearer · Costume of {char.costume}</div>
          <h1 className="name">{char.name}</h1>
          <div className="true">
            True name: {trueRevealed
              ? <span className="reveal">{char.trueName}</span>
              : <em>— unrevealed —</em>}
          </div>
        </div>
      </div>

      <div className="sin-virtue">
        <div className="step">
          <div className="l">The Sin</div>
          <div className="v" style={{ color: 'var(--crimson)' }}>{char.sin}</div>
        </div>
        <div className="arrow">⟶</div>
        <div className="step">
          <div className="l">The Costume</div>
          <div className="v" style={{ color: 'var(--fg-2)' }}>{char.costume}</div>
        </div>
        <div className="arrow">⟶</div>
        <div className="step">
          <div className="l">The Virtue</div>
          <div className="v" style={{ color: char.color }}>{char.virtue}</div>
        </div>
      </div>

      <div className="codex-grid">
        <div className="codex-block">
          <h4>The Costume</h4>
          <p>{lore.costumeDescription}</p>
        </div>
        <div className="codex-block">
          <h4>Surface</h4>
          <p>{lore.surfacePersonality}</p>
        </div>
        <div className="codex-block full-span" style={{ borderColor: 'var(--line-hot)' }}>
          <h4 style={{ color: 'var(--crimson)' }}>The Wound · {tier >= 2 ? 'visible' : 'beneath'}</h4>
          <p style={{ fontStyle: tier < 2 ? 'italic' : 'normal', opacity: tier < 2 ? 0.55 : 1 }}>
            {tier < 2 ? '— Not yet surfaced. Reach Tier 2 to learn what lives underneath. —' : lore.wound}
          </p>
        </div>
        <div className="codex-block">
          <h4 style={{ color: tier >= 3 ? 'var(--sloth-dusk)' : 'var(--fg-3)' }}>Crack Event</h4>
          <p style={{ fontStyle: tier < 3 ? 'italic' : 'normal', opacity: tier < 3 ? 0.55 : 1 }}>
            {tier < 3 ? '— Tier 3 required —' : lore.crackEvent}
          </p>
        </div>
        <div className="codex-block">
          <h4 style={{ color: tier >= 5 ? 'var(--sacred-gold)' : 'var(--fg-3)' }}>Resolution</h4>
          <p style={{ fontStyle: tier < 5 ? 'italic' : 'normal', opacity: tier < 5 ? 0.55 : 1 }}>
            {tier < 5 ? '— Tier 5 required —' : lore.resolution}
          </p>
        </div>
        <div className="codex-block full-span" style={{ background: 'transparent', borderColor: 'transparent', borderTop: '1px solid var(--line-hot)' }}>
          <p style={{ fontStyle: 'italic', textAlign: 'center', color: 'var(--fg-2)', fontSize: 16 }}>"{lore.flavor}"</p>
        </div>
      </div>
    </div>
  );
}

function Codex({ tier }) {
  const [selected, setSelected] = useStateCD(THE_SEVEN[0]);
  return (
    <div className="codex">
      <CodexNav items={THE_SEVEN} selectedId={selected.id} onSelect={setSelected} tier={tier} />
      <CodexDetail char={selected} tier={tier} />
    </div>
  );
}

Object.assign(window, { Codex });
