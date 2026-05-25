// Roster.jsx — character management screen.
//
// Three-column layout matching the existing Antechamber rhythm but
// surfacing the entire stat / job-tree / abilities loadout of the
// selected character. The job tree is the centrepiece — 8 escutcheon
// insignias arranged in a circle around the primary job, with
// JP-progress arcs drawn behind each.
const { useState: useStateR } = React;

function StatBar({ label, value, max = 20, color = 'var(--fg-2)' }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '52px 1fr 36px', gap: 10, alignItems: 'center' }}>
      <div style={{ font: '10px/1 var(--font-header)', letterSpacing: '0.18em', textTransform: 'uppercase', color: 'var(--fg-3)', fontWeight: 700 }}>{label}</div>
      <div style={{ height: 6, background: '#0a0806', border: '1px solid #1a1410', overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${(value / max) * 100}%`, background: color, boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.18)' }} />
      </div>
      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--fg-1)', textAlign: 'right' }}>{value}</div>
    </div>
  );
}

// One job badge in the tree. Renders the insignia SVG inline so it can
// react to status (unlocked/locked/primary/secondary) via a glow ring.
function JobBadge({ jobId, state, onSelect, isCurrent }) {
  const j = JOBS[jobId];
  const t = state.status;
  const pct = state.max ? state.jp / state.max : 0;
  const ringColor = t === 'primary' ? 'var(--sacred-gold)'
                   : t === 'secondary' ? 'var(--hub-warm)'
                   : t === 'unlocked' ? 'var(--fg-2)'
                   : t === 'available' ? 'var(--sloth-dusk)'
                   : 'var(--fg-4)';
  return (
    <button
      className={`job-badge${t === 'locked' ? ' locked' : ''}${isCurrent ? ' current' : ''}`}
      style={{ ['--ring']: ringColor, ['--job-color']: j.color }}
      onClick={() => { window.Sfx?.play('select'); onSelect(jobId); }}
      title={`${j.name} · ${state.jp}/${state.max} JP`}>
      <svg viewBox="0 0 64 64" className="job-ring" width="76" height="76" aria-hidden="true">
        <circle cx="32" cy="32" r="29" fill="none" stroke="rgba(0,0,0,0.4)" strokeWidth="2"/>
        <circle cx="32" cy="32" r="29" fill="none" stroke={ringColor}
                strokeWidth="2"
                strokeDasharray={`${pct * 182} 182`}
                strokeDashoffset="0"
                strokeLinecap="butt"
                transform="rotate(-90 32 32)"
                opacity={t === 'locked' ? 0.2 : 0.85}/>
      </svg>
      <img src={`insignias/${jobId}.svg`} alt={j.name} width="56" height="63" className="job-img"/>
      <div className="job-name" style={{ color: ringColor }}>{j.name}</div>
      {t === 'primary'   && <div className="job-tag">★ Primary</div>}
      {t === 'secondary' && <div className="job-tag" style={{ color: 'var(--hub-warm)' }}>2°</div>}
      {t === 'available' && <div className="job-tag" style={{ color: 'var(--sloth-dusk)' }}>Open</div>}
      {t === 'locked'    && <div className="job-tag" style={{ color: 'var(--fg-4)' }}>Sealed</div>}
    </button>
  );
}

function AbilityRow({ ab, onToggle }) {
  const j = JOBS[ab.job];
  return (
    <button className={`ability-row${ab.equipped ? ' equipped' : ''}`} onClick={() => { window.Sfx?.play('tick'); onToggle(ab.id); }}>
      <div className="ab-mark" style={{ background: `${j.color}22`, color: j.color, borderColor: j.color }}>
        <img src={`insignias/${ab.job}.svg`} width="22" height="25" style={{ filter: 'brightness(1.2)' }}/>
      </div>
      <div style={{ minWidth: 0, flex: 1 }}>
        <div className="ab-name" style={{ color: ab.equipped ? 'var(--fg-1)' : 'var(--fg-3)' }}>{ab.name}</div>
        <div className="ab-desc">{ab.desc}</div>
      </div>
      <div className="ab-cost">
        {ab.cost > 0 && <span style={{ color: 'var(--eth)' }}>{ab.cost} ETH</span>}
        {ab.cost === 0 && <span style={{ color: 'var(--fg-3)' }}>free</span>}
      </div>
      <div className="ab-toggle">{ab.equipped ? '◉' : '○'}</div>
    </button>
  );
}

function CharacterDetail({ char }) {
  const jobs = CHAR_JOBS[char.id];
  const [selectedJobId, setSelectedJobId] = useStateR(jobs.primary);
  const [abilities, setAbilities] = useStateR(jobs.abilities);
  const selectedJob = JOBS[selectedJobId];
  const selectedJobState = jobs.tree[selectedJobId];

  const toggleAb = (id) => {
    setAbilities(abilities.map(a => a.id === id ? { ...a, equipped: !a.equipped } : a));
  };

  // Layout job badges in a ring around the centre.
  // Primary always at top; others clockwise by tier-order.
  const ORDER = ['soldier','knight','templar','cleric','mage','vagrant','monk','archer'];
  const ringJobs = ORDER.map((id, i) => {
    const angle = (i / ORDER.length) * Math.PI * 2 - Math.PI / 2;
    const radius = 158;
    return { id, x: Math.cos(angle) * radius, y: Math.sin(angle) * radius };
  });

  const equippedCount = abilities.filter(a => a.equipped).length;

  return (
    <div className="char-detail">
      {/* Stats column */}
      <div className="char-stats">
        <div className="ch-portrait-block">
          <div className="ch-portrait" style={{ color: char.color, borderColor: char.color, background: `${char.color}22` }}>
            {char.glyph}
          </div>
          <div className="eyebrow ash" style={{ marginTop: 14 }}>{char.sin}-bearer</div>
          <div className="ch-name">{char.name}</div>
          <div className="ch-true">True name: <em style={{ color: 'var(--fg-3)' }}>—&nbsp;unrevealed&nbsp;—</em></div>
        </div>

        <div className="meta-panel" style={{ marginTop: 16 }}>
          <h3>Stats · {selectedJob.name} loadout</h3>
          <StatBar label="ATK" value={selectedJob.stats.atk} color={selectedJob.color}/>
          <StatBar label="DEF" value={selectedJob.stats.def} color="var(--tmp)"/>
          <StatBar label="MAG" value={selectedJob.stats.mag} color="var(--eth)"/>
          <StatBar label="RES" value={selectedJob.stats.res} color="var(--sloth-dusk)"/>
          <StatBar label="SPD" value={selectedJob.stats.spd} color="var(--fg-2)"/>
          <StatBar label="MV"  value={selectedJob.stats.mv}  max={6} color="var(--hub-warm)"/>
        </div>

        <div className="meta-panel">
          <h3>Costume integrity</h3>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ font: 'italic 13px var(--font-body)', color: 'var(--fg-2)' }}>{char.costume}</span>
            <span className="numeric" style={{ color: char.integrity < 40 ? 'var(--crimson)' : 'var(--fg-1)' }}>{char.integrity}/100</span>
          </div>
          <div className="bar-track" style={{ marginTop: 4 }}>
            <div className="bar-fill" style={{ width: `${char.integrity}%`, background: `linear-gradient(90deg, var(--crimson), ${char.color})` }} />
          </div>
          <div className="muted" style={{ font: 'italic 11px/1.4 var(--font-body)', marginTop: 8 }}>
            Cracks at integrity 40. Resolves into <strong style={{ color: char.color }}>{char.virtue}</strong>.
          </div>
        </div>
      </div>

      {/* Job tree — circle of insignias around the selected one */}
      <div className="job-tree">
        <div className="tree-head">
          <div className="eyebrow ash">Job tree · 8 callings</div>
          <h2 style={{ margin: '6px 0 0', font: '24px/1 var(--font-header)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>{selectedJob.name}</h2>
          <p style={{ font: 'italic 13px/1.5 var(--font-body)', color: 'var(--fg-3)', margin: '6px 0 0', maxWidth: '46ch' }}>{selectedJob.desc}</p>
        </div>

        <div className="tree-stage">
          {/* connecting lines from centre to each badge */}
          <svg className="tree-lines" viewBox="-220 -220 440 440">
            {ringJobs.map((rj, i) => (
              <line key={rj.id}
                    x1="0" y1="0"
                    x2={rj.x} y2={rj.y}
                    stroke={rj.id === selectedJobId ? 'var(--sacred-gold)' : 'var(--line)'}
                    strokeWidth={rj.id === selectedJobId ? '1.6' : '0.8'}
                    strokeDasharray={jobs.tree[rj.id]?.status === 'locked' ? '4 6' : ''}
                    opacity={jobs.tree[rj.id]?.status === 'locked' ? 0.35 : 0.6} />
            ))}
          </svg>
          {ringJobs.map((rj) => (
            <div key={rj.id} className="tree-slot" style={{ transform: `translate(${rj.x}px, ${rj.y}px)` }}>
              <JobBadge jobId={rj.id} state={jobs.tree[rj.id]} onSelect={setSelectedJobId} isCurrent={rj.id === selectedJobId}/>
            </div>
          ))}
          {/* centre — JP progress for the selected job */}
          <div className="tree-centre">
            <div className="eyebrow" style={{ fontSize: 10 }}>JP progress</div>
            <div style={{ font: '36px/1 var(--font-display)', fontWeight: 700, color: selectedJob.color, marginTop: 4 }}>
              {selectedJobState.jp}
            </div>
            <div className="muted numeric" style={{ marginTop: 2 }}>/ {selectedJobState.max}</div>
            {selectedJobState.mastered && <div className="eyebrow" style={{ marginTop: 8 }}>★ Mastered</div>}
            {selectedJobState.requires && (
              <div className="muted" style={{ font: 'italic 10px var(--font-body)', marginTop: 8 }}>
                Requires {selectedJobState.requires}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Abilities column */}
      <div className="char-abilities">
        <div className="ab-head">
          <span className="eyebrow ash">Action loadout</span>
          <span className="muted numeric">{equippedCount} / 6 equipped</span>
        </div>
        <div className="ability-list">
          {abilities.map((ab) => (
            <AbilityRow key={ab.id} ab={ab} onToggle={toggleAb}/>
          ))}
        </div>
        <div className="ab-foot muted">
          Toggle to equip. The first three equipped become Combat action slots; the rest sit in the reserve menu.
        </div>
      </div>
    </div>
  );
}

function Roster() {
  const [selectedId, setSelectedId] = useStateR('aeryn');
  const selected = THE_SEVEN.find(c => c.id === selectedId);
  return (
    <div className="roster-stage">
      <aside className="roster-rail">
        <div className="rail-head">
          <span className="eyebrow">The Seven</span>
          <span className="muted numeric">7 souls assigned</span>
        </div>
        {THE_SEVEN.map((c) => {
          const jt = CHAR_JOBS[c.id];
          const primaryJob = JOBS[jt.primary];
          return (
            <button key={c.id} className={`roster-card${c.id === selectedId ? ' selected' : ''}`}
                    onClick={() => { window.Sfx?.play('nav'); setSelectedId(c.id); }}>
              <div className="rc-portrait" style={{ color: c.color, borderColor: c.color, background: `${c.color}22` }}>{c.glyph}</div>
              <div style={{ minWidth: 0, flex: 1 }}>
                <div className="rc-name">{c.name}</div>
                <div className="rc-meta">{primaryJob.name} · {c.sin}</div>
              </div>
              <img className="rc-insignia" src={`insignias/${jt.primary}.svg`} width="32" height="36"/>
            </button>
          );
        })}
      </aside>
      <CharacterDetail char={selected} key={selectedId}/>
    </div>
  );
}

Object.assign(window, { Roster });
