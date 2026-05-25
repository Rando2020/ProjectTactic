// chrome.jsx — TopRail, TierMeter, mute toggle

const { useState: useStateCh } = React;

function MuteToggle() {
  const [muted, setMuted] = useStateCh(() => window.Sfx?.isMuted() ?? false);
  const toggle = () => {
    const next = !muted;
    window.Sfx?.setMuted(next);
    setMuted(next);
    if (!next) window.Sfx?.play('nav');
  };
  return (
    <button className={`mute-toggle${muted ? ' muted' : ''}`} onClick={toggle} aria-label={muted ? 'Unmute' : 'Mute'} title={muted ? 'Sound off' : 'Sound on'}>
      <span className="mute-glyph" aria-hidden="true">
        {/* Three concentric arcs as a bell — single ::after dot when muted */}
        <span className="bell" />
        <span className="bell" />
        <span className="bell" />
        {muted && <span className="slash" />}
      </span>
    </button>
  );
}

function TopRail({ screen, onNav, tier, onTierChange }) {
  const tabs = ['title', 'antechamber', 'roster', 'chapter', 'runmap', 'battle', 'codex'];
  const tierName = TIER_NAMES[tier];
  const handleNav = (t) => {
    window.Sfx?.play('nav');
    onNav(t);
  };
  const handleTier = (n) => {
    if (n !== tier) window.Sfx?.play('crack');
    onTierChange(n);
  };
  return (
    <div className="rail">
      <div className="mark">
        The Appointed
        <span className="subtitle">As · Above</span>
      </div>
      <div className="rail-nav">
        {tabs.map((t) => (
          <button key={t} className={t === screen ? 'active' : ''} onClick={() => handleNav(t)}>
            {t === 'antechamber' ? 'Antechamber'
              : t === 'codex' ? 'The Seven'
              : t === 'battle' ? 'Mountain'
              : t === 'chapter' ? 'Chronicle'
              : t === 'runmap' ? 'Pathway'
              : t === 'roster' ? 'Roster'
              : 'Title'}
          </button>
        ))}
      </div>
      <div className="rail-tier">
        <MuteToggle />
        <div style={{ textAlign: 'right' }}>
          <div className="label">Revelation</div>
          <div className="name">Tier {tier} · {tierName}</div>
        </div>
        <div className="meter" role="group" aria-label="Revelation tier">
          {[1,2,3,4,5].map((n) => (
            <button
              key={n}
              className={`pip${n <= tier ? ' lit' : ''}`}
              onClick={() => handleTier(n)}
              aria-label={`Set tier ${n}`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { TopRail, MuteToggle });
