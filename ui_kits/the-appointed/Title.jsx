// Title.jsx — main menu / start screen
function TitleScreen({ onNewGame, onContinue, tier }) {
  const tierName = TIER_NAMES[tier];
  return (
    <div className="title-stage">
      <div className="game-mark" style={{ whiteSpace: 'nowrap' }}>SEVEN ANGELS · ASSIGNED TO SIN</div>
      <h1 className="title-main">The Appointed</h1>
      <div className="title-sub">AS · ABOVE</div>
      <p className="title-tag">
        A theological tactical RPG with roguelike echoes. Seven angels administer
        the trials of Purgatory — while being refined by those same trials.
        <br />They don't know what they are yet.
      </p>
      <div className="title-menu">
        <button className="btn btn-sacred" onClick={() => { window.Sfx?.play('confirm'); onNewGame(); }}>Begin First Loop</button>
        <button className="btn" onClick={() => { window.Sfx?.play('select'); onContinue(); }}>Continue</button>
        <button className="btn btn-ghost" onClick={() => window.Sfx?.play('nav')}>Settings</button>
        <button className="btn btn-ghost" onClick={() => window.Sfx?.play('nav')}>The Lexicon</button>
      </div>
      <div style={{ marginTop: 56, opacity: 0.7 }}>
        <span className="eyebrow ash">Currently · </span>
        <span className="eyebrow" style={{ color: TIER_COLORS[tier] }}>Tier {tier} · {tierName}</span>
      </div>
    </div>
  );
}
Object.assign(window, { TitleScreen });
