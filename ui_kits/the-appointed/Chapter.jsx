// Chapter.jsx — FFT-style chapter card / loop transition.
// Used between runs as a sacred narrative interlude on parchment.

function ChapterCard({ tier }) {
  const loopRomans = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
  const loopNum = 7 + tier * 4;
  const loop = loopRomans[Math.min(loopNum, 10)] || String(loopNum);
  const chapterRoman = loopRomans[tier] || String(tier);
  const tierName = TIER_NAMES[tier];

  const epigraphs = {
    1: { line: "The objective is clear. I don't understand why the others hesitate.", who: "Aeryn, log entry" },
    2: { line: "There was a moment in the last battle — one of them stopped. Just stopped. And looked at me. I don't know what I saw in its face.", who: "Aeryn, fragment" },
    3: { line: "It said: 'You've been here before. Every loop, the same certainty, the same cost. Do you ever ask yourself who taught you to be this sure?'", who: "Aeryn, after the Fallen" },
    4: { line: "I met a man today who had been certain about everything. Completely, peacefully certain. He was wrong about all of it. He didn't know. How would he have known? How do I know?", who: "Aeryn, marginalia" },
    5: { line: "It was never about whether I was right enough. I understand that now.", who: "Aeryn — true name remembered" }
  };
  const ep = epigraphs[tier];

  return (
    <div style={{
      minHeight: '100%',
      padding: '40px 60px 60px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'radial-gradient(ellipse 900px 500px at 50% 40%, rgba(212,175,55,0.04), transparent 70%), var(--surface-0)'
    }}>
      <div className="parchment" style={{
        width: '100%',
        maxWidth: 860,
        padding: '64px 72px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 16,
        textAlign: 'center'
      }}>
        <div className="rubric" style={{ fontSize: 13, letterSpacing: '0.42em', color: 'var(--ink-rubric)' }}>
          Loop · {loop}
        </div>
        <hr style={{ width: 120 }} />
        <div style={{
          font: '88px/0.95 var(--font-display)',
          fontWeight: 700,
          color: 'var(--ink)',
          letterSpacing: '0.04em',
          textTransform: 'uppercase'
        }}>
          Chapter {chapterRoman}
        </div>
        <div style={{
          font: '32px/1.1 var(--font-display)',
          fontWeight: 400,
          color: 'var(--ink-faded)',
          letterSpacing: '0.22em',
          textTransform: 'uppercase'
        }}>
          {tierName}
        </div>
        <hr style={{ width: 240, marginTop: 24 }} />
        <p style={{
          font: 'italic 19px/1.55 var(--font-body)',
          color: 'var(--ink-faded)',
          maxWidth: '46ch',
          margin: '8px 0 0',
          textWrap: 'pretty'
        }}>
          &ldquo;{ep.line}&rdquo;
        </p>
        <p style={{
          font: '13px/1 var(--font-body)',
          color: 'var(--brass-deep)',
          letterSpacing: '0.24em',
          textTransform: 'uppercase',
          margin: '12px 0 0'
        }}>
          &mdash; {ep.who}
        </p>
        <div style={{ marginTop: 36, display: 'flex', gap: 10 }}>
          <button className="btn" style={{
            background: 'rgba(106,74,26,0.1)',
            border: '1px solid var(--brass-deep)',
            color: 'var(--ink)',
            fontFamily: 'var(--font-body)',
            fontStyle: 'italic',
            letterSpacing: '0.04em',
            textTransform: 'none',
            fontSize: 14
          }}>Open the chronicle</button>
          <button className="btn btn-sacred" style={{ fontSize: 12 }}>Begin chapter</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ChapterCard });
