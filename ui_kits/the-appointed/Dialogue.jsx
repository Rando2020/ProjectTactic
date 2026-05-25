// Dialogue.jsx — full-screen dialogue overlay for the Antechamber keepers.
//
// Two modes:
//   • Tier 1-3 : the dark glass scene (default — keepers speak from the void)
//   • Tier 4-5 : the parchment unfurls. The line is no longer just spoken;
//                it has been transcribed. Sacred ink on aged paper.
function DialogueOverlay({ loc, onClose, tier }) {
  if (!loc) return null;

  // Sample dialogue by tier for each keeper. Strings use double quotes
  // throughout to avoid having to escape ASCII apostrophes.
  const DIALOGUE = {
    "Azrael": {
      1: ["I am Azrael. I have been here longer than you remember.", "Sit, if you like. I won't move."],
      3: ["I have watched you arrive seven times. Or twenty. The number is yours to count.", "I am not here to hurry you."],
      5: ["You're carrying something heavier this loop. Yes. Set it down here. I'll keep it until you're ready."]
    },
    "Casimir": {
      1: ["The library has the same books in a different order today. Curious.", "No, I do not know who reorders them."],
      3: ["You looked at me strangely yesterday. As though you'd seen me before. As though we were not both here for the first time.", "I'm beginning to think we aren't."],
      5: ["I'm not from a tradition. I'm from a house in Salisbury. I had a wife. Her name was Mara. I do not know what happened to her. Do you understand what I am saying?"]
    },
    "Ereshkigal": {
      1: ["These flowers will not grow anywhere else. Only here. Only for me.", "Sumerian, you would say. Older than that, really."],
      3: ["The light is changing. Your light. Not the light here. The light in you. Have you noticed?"],
      5: ["I tended the dead before there was a heaven to send them to. I will tend them after."]
    },
    "Lilith": {
      3: ["You should not have been able to reach me yet. Interesting."],
      5: ["I am not what they told you. I am not what I told myself."]
    },
    "Anamnesis": {
      3: ["I do not speak. I remember. Bring me something forgotten and I will give it back."],
      5: ["Here. This is yours. It was always yours."]
    },
    "Somnus": {
      5: ["Night, finally. The loop is slow enough now. Rest here."]
    }
  };

  const keeper = loc.keeper;
  const lines = DIALOGUE[keeper] || {};
  const available = Object.keys(lines).map(Number).filter((t) => t <= tier).sort((a, b) => b - a);
  const useTier = available[0] || 1;
  const text = (lines[useTier] && lines[useTier][0]) || "...";

  const sacred = tier >= 4;

  // play the right sound when the dialogue mounts
  React.useEffect(() => {
    if (sacred) window.Sfx?.play('sacred');
    else window.Sfx?.play('page');
  }, [keeper, sacred]);

  // --- Dark-mode variant (tier 1-3) ----------------------------------
  if (!sacred) {
    return (
      <div className="scene">
        <div className="scene-portrait" style={{ color: "var(--sacred-gold)" }}>
          {keeper.charAt(0)}
        </div>
        <div className="dialogue-box">
          <div className="speaker">
            <span className="name">{keeper}</span>
            <span className="true">{loc.tradition} · {loc.name}</span>
          </div>
          <p className="line">&ldquo;{text}&rdquo;</p>
          <div className="actions">
            <button className="btn btn-ghost" onClick={() => { window.Sfx?.play('cancel'); onClose(); }}>Leave</button>
            <button className="btn" onClick={() => window.Sfx?.play('select')}>Press further</button>
          </div>
        </div>
      </div>
    );
  }

  // --- Sacred parchment variant (tier 4+) ----------------------------
  // The keeper has been transcribed. Page unfurls from center.
  // At tier 5, embers drift behind the page — the loop can end.
  const embers = tier >= 5 ? Array.from({ length: 14 }, (_, i) => {
    const left = 8 + (i * 6.4) % 84;       // spread across the scene
    const drift = -20 + ((i * 7) % 40);    // horizontal wander
    const delay = -((i * 0.6) % 7);        // staggered phase
    return (
      <span key={i} className="ember" style={{
        left: `${left}%`,
        ['--drift']: `${drift}px`,
        animationDelay: `${delay}s`
      }} />
    );
  }) : null;

  return (
    <div className="scene scene-sacred">
      {embers}
      <div className="parchment scroll-unfurl" style={{
        width: "min(820px, 100% - 80px)",
        margin: "auto",
        padding: "56px 64px",
        display: "grid",
        gridTemplateColumns: "92px 1fr",
        gap: 28,
        alignItems: "start"
      }}>
        {/* Illuminated initial — the keeper as rubric capital */}
        <div style={{
          alignSelf: "stretch",
          border: "1.5px solid var(--brass-deep)",
          background: "rgba(106,74,26,0.08)",
          padding: "16px 8px",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 8
        }}>
          <div className="rubric" style={{ fontSize: 10, letterSpacing: "0.3em" }}>
            Keeper
          </div>
          <div style={{
            font: "60px/1 var(--font-display)",
            fontWeight: 700,
            color: "var(--ink-rubric)",
            textShadow: "0 0 8px rgba(140,31,31,0.25)"
          }}>
            {keeper.charAt(0)}
          </div>
          <div style={{
            font: "italic 11px/1.3 var(--font-body)",
            color: "var(--ink-faded)",
            textAlign: "center"
          }}>
            transcribed at<br />Tier {tier}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12, minWidth: 0 }}>
          <div className="rubric" style={{
            fontSize: 11,
            letterSpacing: "0.36em",
            color: "var(--ink-rubric)"
          }}>
            {loc.tradition} · {loc.name}
          </div>
          <div style={{
            font: "44px/1 var(--font-display)",
            fontWeight: 700,
            color: "var(--ink)",
            letterSpacing: "0.04em",
            textTransform: "uppercase"
          }}>
            {keeper}
          </div>
          <hr style={{ margin: "6px 0" }} />
          <p style={{
            font: "italic 22px/1.55 var(--font-body)",
            color: "var(--ink)",
            margin: 0,
            textWrap: "pretty"
          }}>
            &ldquo;{text}&rdquo;
          </p>
          <div style={{
            display: "flex",
            gap: 8,
            marginTop: 18,
            justifyContent: "flex-end"
          }}>
            <button className="btn parchment-btn" onClick={() => { window.Sfx?.play('cancel'); onClose(); }}>Leave</button>
            <button className="btn parchment-btn" onClick={() => window.Sfx?.play('select')}>Press further</button>
            <button className="btn parchment-btn primary" onClick={() => window.Sfx?.play('confirm')}>Give a gift</button>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DialogueOverlay });
