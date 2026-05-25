// Antechamber.jsx — hub screen
const { useState: useStateAC } = React;

function PartyCard({ char, selected, onSelect }) {
  return (
    <button className={`party-card${selected ? ' selected' : ''}`} onClick={() => { window.Sfx?.play('select'); onSelect(char.id); }}>
      <div className="portrait" style={{ color: char.color, borderColor: char.color, background: `${char.color}22` }}>
        {char.glyph}
      </div>
      <div style={{ minWidth: 0 }}>
        <div className="name">{char.name}</div>
        <div className="role">{char.job} · {char.sin}</div>
      </div>
      <div className="integrity">
        <span className="v" style={{ color: char.integrity < 40 ? 'var(--crimson)' : char.integrity > 80 ? 'var(--fg-1)' : 'var(--hub-warm)' }}>
          {char.integrity}
        </span>
        costume
      </div>
    </button>
  );
}

function Location({ loc, tier, onEnter }) {
  const locked = loc.tier > tier;
  return (
    <div className={`location${locked ? ' locked' : ''}`} onClick={() => { if (locked) return; window.Sfx?.play('page'); onEnter(loc); }}>
      <div className="l-name">{loc.name}</div>
      <div className="l-desc">{loc.desc}</div>
      <div className="l-keeper">— {loc.keeper}, {loc.tradition}</div>
      {locked && <div className="l-lock">Sealed · Tier {loc.tier}</div>}
    </div>
  );
}

function Antechamber({ tier, onBeginRun, onTalk }) {
  const [selectedId, setSelectedId] = useStateAC('aeryn');
  const selected = THE_SEVEN.find((c) => c.id === selectedId);
  const partyAvg = Math.round(THE_SEVEN.reduce((a, c) => a + c.integrity, 0) / THE_SEVEN.length);

  return (
    <div className="antechamber">
      <div className="party-rail scroll">
        <div className="head">
          <span className="eyebrow">The Seven</span>
          <span className="muted" style={{ font: '11px/1 var(--font-mono)' }}>
            {partyAvg}<span style={{ color: 'var(--fg-3)' }}>/100 avg</span>
          </span>
        </div>
        {THE_SEVEN.map((c) => (
          <PartyCard key={c.id} char={c} selected={c.id === selectedId} onSelect={setSelectedId} />
        ))}
      </div>

      <div className="chamber-stage">
        <div className="chamber-head">
          <div className="crumb">The Mountain · Antechamber · Loop {tier === 5 ? 24 : 7}</div>
          <h2 className="h-title">The Antechamber</h2>
          <p className="h-blurb">
            {tier <= 2
              ? 'Holy ruin. Candlelight. The dock is quiet. The mountain waits to be climbed again.'
              : tier === 3
              ? 'Something has shifted. The dark corners are no longer empty. The pool has begun to hum.'
              : tier === 4
              ? 'The names you do not know yet are very close now. Casimir has stopped pretending.'
              : 'The Antechamber is breathing with you. The threshold is no longer sealed.'}
          </p>
        </div>
        <div className="chamber-locations scroll" style={{ flex: 1, alignContent: 'start' }}>
          {HUB_LOCATIONS.map((loc) => (
            <Location key={loc.id} loc={loc} tier={tier} onEnter={onTalk} />
          ))}
        </div>
      </div>

      <div className="meta-col scroll">
        <div className="run-cta">
          <div className="eyebrow ash">Roguelike</div>
          <div className="h">Descend the Mountain</div>
          <div className="sub">Ten floors. Battles, wanderers, Guardian boons, and one boss who may remember you.</div>
          <button className="btn btn-sacred" onClick={() => { window.Sfx?.play('confirm'); onBeginRun(); }}>Begin Descent</button>
        </div>

        <div className="meta-panel">
          <h3>Selected · {selected.name}</h3>
          <div className="stat">
            <span>True name</span>
            <span className="v" style={{ color: tier >= 4 ? 'var(--sacred-gold)' : 'var(--fg-3)', fontStyle: tier >= 4 ? 'normal' : 'italic' }}>
              {tier >= 4 ? selected.trueName : '— unrevealed —'}
            </span>
          </div>
          <div className="stat">
            <span>Sin / Costume</span>
            <span className="v">{selected.sin} · {selected.costume}</span>
          </div>
          <div className="stat">
            <span>Virtue (resolution)</span>
            <span className="v" style={{ color: selected.color }}>{selected.virtue}</span>
          </div>
          <div className="stat">
            <span>Costume integrity</span>
            <span className="v numeric">{selected.integrity} / 100</span>
          </div>
          <div className="bar-track" style={{ marginTop: 2 }}>
            <div className="bar-fill" style={{
              width: `${selected.integrity}%`,
              background: `linear-gradient(90deg, var(--crimson), ${selected.color})`
            }} />
          </div>
        </div>

        <div className="meta-panel">
          <h3>Run Progress</h3>
          <div className="stat"><span>Total loops</span><span className="v numeric">{7 + tier * 4}</span></div>
          <div className="stat"><span>Revelation pts</span><span className="v numeric">{[0, 120, 320, 520, 880, 1240][tier]} / {[150, 400, 750, 1200, 1200, 1200][tier]}</span></div>
          <div className="stat"><span>Souls returned</span><span className="v numeric">{tier * 3}</span></div>
          <div className="stat"><span>Crack events</span><span className="v numeric">{tier * 5 + 2}</span></div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Antechamber });
