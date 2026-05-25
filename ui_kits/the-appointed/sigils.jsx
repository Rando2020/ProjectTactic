// sigils.jsx — heraldic medallions for run-map nodes.
//
// Each sigil is a circular brass-rimmed badge with a single ink/gold
// glyph inside. They are deliberately simple — line-only forms that
// read like coin engravings at small sizes (24px works; 48-72px is
// where the detail shows). All six render from the same `<Sigil />`
// component so they share the frame, the ring, the dark field, and
// the inset shadow — only the inner glyph swaps.
//
// Type → colour key:
//   regular  → iron grey      (a workmanlike fight)
//   elite    → brass          (heightened, marked)
//   mystery  → sloth-dusk     (?, unread)
//   boss     → crimson glow   (a Fallen waits)
//   boon     → sacred-gold    (a Guardian's gift)
//   wanderer → bronze         (a pilgrim with something to trade)

const SIGIL_TYPES = {
  regular:  { color: '#8a7e6a',  ring: '#3d3530',                label: 'Battle',    desc: 'A workmanlike fight.' },
  elite:    { color: '#d4af37',  ring: '#8c6f2a', halo: '#d4af37', label: 'Elite',    desc: 'Marked. Heavier loot.' },
  mystery:  { color: '#a585ff',  ring: '#6b5b8a',                label: 'Mystery',   desc: 'Unread until you step on it.' },
  boss:     { color: '#e0304a',  ring: '#5c1620', halo: '#9b2335', label: 'Boss',     desc: 'A Fallen waits.' },
  boon:     { color: '#ffe680',  ring: '#8c6f2a', halo: '#d4af37', label: 'Boon',     desc: "A Guardian's gift." },
  wanderer: { color: '#c8a96e',  ring: '#6a4a1a',                label: 'Wanderer',  desc: 'A pilgrim with something to trade.' },
};

function SigilGlyph({ type }) {
  // Each path/stroke set is hand-tuned for the 64px viewBox.
  // currentColor lets the wrapper colour the inner glyph.
  switch (type) {
    case 'regular':
      return (
        <g stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" fill="none">
          {/* crossed daggers */}
          <line x1="22" y1="22" x2="42" y2="42" />
          <line x1="42" y1="22" x2="22" y2="42" />
          {/* hilts */}
          <line x1="20" y1="20" x2="24" y2="24" strokeWidth="3" />
          <line x1="40" y1="24" x2="44" y2="20" strokeWidth="3" />
        </g>
      );
    case 'elite':
      return (
        <g stroke="currentColor" fill="none">
          {/* crown of three points */}
          <path d="M20 26 L24 18 L28 24 L32 16 L36 24 L40 18 L44 26" strokeWidth="2" strokeLinejoin="round" />
          <line x1="20" y1="28" x2="44" y2="28" strokeWidth="1.5" />
          {/* small sword below */}
          <line x1="32" y1="32" x2="32" y2="46" strokeWidth="2.4" strokeLinecap="round" />
          <line x1="28" y1="36" x2="36" y2="36" strokeWidth="2" strokeLinecap="round" />
          <circle cx="32" cy="48" r="1.4" fill="currentColor" />
        </g>
      );
    case 'mystery':
      return (
        <g fill="currentColor">
          {/* ornate question mark — top hook + dot */}
          <path
            d="M32 18 c-5.6 0 -9 3.2 -9 7.5 c0 2.4 1.2 4.3 3.6 5.4 l0 0 c2 1 2.8 1.9 2.8 3.4 l0 5 l5.2 0 l0 -5 c0 -2.8 -1.2 -4.4 -3.6 -5.6 c-1.6 -0.8 -2.4 -1.5 -2.4 -3.0 c0 -1.8 1.6 -3.2 3.4 -3.2 c1.8 0 3.2 1.4 3.2 3.2 l5.2 0 c0 -4.2 -3.4 -7.7 -8.4 -7.7 z"
            stroke="none"
          />
          <circle cx="32" cy="44.5" r="2.4" />
        </g>
      );
    case 'boss':
      return (
        <g fill="none" stroke="currentColor">
          {/* spiked crown + watching eye */}
          <path d="M16 28 L20 18 L24 26 L28 14 L32 24 L36 14 L40 26 L44 18 L48 28" strokeWidth="2" strokeLinejoin="round" />
          <ellipse cx="32" cy="38" rx="11" ry="7" strokeWidth="1.6" />
          <circle cx="32" cy="38" r="3.2" fill="currentColor" />
          <circle cx="32" cy="38" r="1" fill="#08090d" />
        </g>
      );
    case 'boon':
      return (
        <g stroke="currentColor" fill="none" strokeLinecap="round">
          {/* chalice cradled in a halo */}
          {/* halo arc */}
          <path d="M14 22 a18 18 0 0 1 36 0" strokeWidth="1.4" opacity="0.55" />
          <path d="M18 22 a14 14 0 0 1 28 0" strokeWidth="1.4" opacity="0.8" />
          {/* chalice */}
          <path d="M22 26 L42 26 Q42 38 32 42 Q22 38 22 26 Z" strokeWidth="1.8" strokeLinejoin="round" />
          <line x1="32" y1="42" x2="32" y2="48" strokeWidth="2" />
          <line x1="26" y1="48" x2="38" y2="48" strokeWidth="2" />
          {/* one drop / a star inside */}
          <circle cx="32" cy="32" r="1.6" fill="currentColor" />
        </g>
      );
    case 'wanderer':
      return (
        <g stroke="currentColor" fill="none" strokeLinecap="round">
          {/* pilgrim staff + travelling pack */}
          <line x1="36" y1="14" x2="22" y2="50" strokeWidth="2.4" />
          {/* small loop at top of staff */}
          <circle cx="36" cy="14" r="2.2" strokeWidth="1.6" />
          {/* the pack — a small bundle hanging off the staff */}
          <path d="M37 22 Q44 24 44 30 Q44 35 38 36 Q34 36 33 32 Z" strokeWidth="1.6" strokeLinejoin="round" />
          {/* a tied knot at top of pack */}
          <line x1="38" y1="22" x2="39" y2="20" strokeWidth="1.4" />
          <line x1="40" y1="22" x2="41" y2="20" strokeWidth="1.4" />
        </g>
      );
    default:
      return null;
  }
}

function Sigil({ type = 'regular', size = 56, completed = false, current = false }) {
  const t = SIGIL_TYPES[type] || SIGIL_TYPES.regular;
  const halo = t.halo;
  const opacity = completed ? 0.36 : 1;
  return (
    <span className={`sigil sigil-${type}${current ? ' is-current' : ''}${completed ? ' is-done' : ''}`}
          style={{ width: size, height: size, ['--ring']: t.ring, ['--glyph']: t.color, ['--halo']: halo || 'transparent', opacity }}>
      <svg viewBox="0 0 64 64" width={size} height={size} aria-hidden="true">
        <defs>
          <radialGradient id={`field-${type}`} cx="50%" cy="40%" r="60%">
            <stop offset="0%"  stopColor="#1a1610" />
            <stop offset="100%" stopColor="#08090d" />
          </radialGradient>
        </defs>
        {/* outer brass ring */}
        <circle cx="32" cy="32" r="30" fill="none" stroke={t.ring} strokeWidth="2" />
        {/* dark field */}
        <circle cx="32" cy="32" r="27.5" fill={`url(#field-${type})`} />
        {/* inner hairline */}
        <circle cx="32" cy="32" r="25" fill="none" stroke={t.ring} strokeWidth="0.6" opacity="0.5" />
        {/* glyph */}
        <g style={{ color: t.color }}>
          <SigilGlyph type={type} />
        </g>
        {/* completion: a brass slash across */}
        {completed && (
          <line x1="14" y1="50" x2="50" y2="14" stroke={t.ring} strokeWidth="2" opacity="0.7" />
        )}
      </svg>
      {current && <span className="sigil-ring" aria-hidden="true" />}
    </span>
  );
}

Object.assign(window, { Sigil, SIGIL_TYPES });
