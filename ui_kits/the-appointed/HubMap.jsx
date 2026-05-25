// HubMap.jsx — the Antechamber rendered as an illuminated manuscript map.
//
// Replaces the previous "list of locations" centre column. The map is a
// single SVG cartograph on the parchment surface, with hand-drawn ink
// boundaries, hairline paths between keepers, and a compass rose. Each
// location is a clickable inkwell — a small drop-cap marker. Sealed
// locations are drawn but slashed in red; revealed locations have a
// gold pip and shimmer at Tier 4+.
//
// The map uses real coordinates so the run CTA at the bottom can mark
// "the descent path" pointing south off the page.

function HubMap({ tier, onTalk, selected, onSelect }) {
  // Location layout on the 800×580 map canvas.
  // x/y are anchor points for the marker; labelDx/Dy place the label.
  const PLACES = [
    { id: 'dock',    name: 'The Dock',          keeper: 'Azrael',      x: 130, y: 130, labelDx:  10, labelDy: -22 },
    { id: 'pool',    name: 'The Deep Pool',     keeper: 'Anamnesis',   x: 400, y: 210, labelDx:  18, labelDy: -22, glow: true },
    { id: 'garden',  name: 'The Courtyard Garden', keeper: 'Ereshkigal', x: 620, y: 170, labelDx: -18, labelDy: -22, labelAnchor: 'end' },
    { id: 'library', name: 'The Library Corner',keeper: 'Casimir',     x: 165, y: 360, labelDx:  10, labelDy:  24 },
    { id: 'corners', name: 'The Dark Corners',  keeper: 'Lilith',      x: 410, y: 430, labelDx:  18, labelDy:  24, tierGate: 3 },
    { id: 'threshold', name: 'The Threshold',   keeper: 'Somnus',      x: 650, y: 400, labelDx: -18, labelDy:  24, labelAnchor: 'end', tierGate: 5 },
  ];

  // hairline ink paths between places (which ones connect)
  const PATHS = [
    ['dock', 'pool'], ['pool', 'garden'], ['pool', 'library'],
    ['library', 'corners'], ['corners', 'threshold'], ['garden', 'threshold'],
  ];

  // helper to get a Place by id
  const place = (id) => PLACES.find((p) => p.id === id);

  return (
    <div className="hub-map-wrap">
      <div className="parchment hub-map">
        {/* The illuminated cartograph itself */}
        <svg viewBox="0 0 800 580" className="hub-cartograph" preserveAspectRatio="xMidYMid meet">
          <defs>
            <filter id="ink-bleed" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="0.4" />
            </filter>
            <radialGradient id="pool-fill" cx="50%" cy="50%" r="50%">
              <stop offset="0%"  stopColor="#5c4530" stopOpacity="0.35"/>
              <stop offset="100%" stopColor="#5c4530" stopOpacity="0"/>
            </radialGradient>
            <radialGradient id="sacred-glow" cx="50%" cy="50%" r="50%">
              <stop offset="0%"  stopColor="#d4af37" stopOpacity={tier >= 4 ? 0.5 : 0}/>
              <stop offset="100%" stopColor="#d4af37" stopOpacity="0"/>
            </radialGradient>
          </defs>

          {/* outer rule — a double-line border 16px in from the edge */}
          <rect x="20" y="20" width="760" height="540" fill="none" stroke="#6a4a1a" strokeWidth="1" opacity="0.55"/>
          <rect x="26" y="26" width="748" height="528" fill="none" stroke="#6a4a1a" strokeWidth="0.6" opacity="0.4"/>

          {/* ink boundaries — the shape of the antechamber.  hand-drawn-irregular */}
          <g stroke="#5c4530" fill="none" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" filter="url(#ink-bleed)">
            {/* outer chamber wall (irregular polygon) */}
            <path d="M 80 100 L 200 80 L 380 95 L 540 75 L 690 100 L 720 230 L 710 380 L 660 480 L 460 500 L 280 490 L 130 470 L 70 360 L 60 220 Z"
                  strokeWidth="1.8" opacity="0.85"/>
            {/* dock — small jetty extending into the pool */}
            <path d="M 100 130 L 90 145 L 175 195 L 195 180 Z" />
            {/* the deep pool (central body of still water) */}
            <ellipse cx="400" cy="220" rx="100" ry="55" />
            <ellipse cx="400" cy="220" rx="100" ry="55" fill="url(#pool-fill)" stroke="none"/>
            <ellipse cx="400" cy="220" rx="78" ry="40" strokeWidth="0.6" opacity="0.6"/>
            <ellipse cx="400" cy="220" rx="50" ry="24" strokeWidth="0.6" opacity="0.4"/>
            {/* garden — courtyard with a circular planting */}
            <path d="M 540 110 L 700 110 L 700 240 L 540 240 Z" />
            <circle cx="620" cy="175" r="42" strokeWidth="0.8"/>
            {/* small plant marks inside the garden */}
            {Array.from({length: 8}).map((_, i) => {
              const a = (i / 8) * Math.PI * 2;
              const px = 620 + Math.cos(a) * 30;
              const py = 175 + Math.sin(a) * 30;
              return <g key={i} strokeWidth="0.6">
                <line x1={px} y1={py} x2={px} y2={py - 4}/>
                <line x1={px - 2} y1={py - 3} x2={px} y2={py - 5}/>
                <line x1={px + 2} y1={py - 3} x2={px} y2={py - 5}/>
              </g>;
            })}
            {/* library corner — rectangular alcove bottom-left */}
            <path d="M 90 320 L 240 320 L 240 410 L 90 410 Z" />
            {/* shelf marks */}
            <line x1="100" y1="340" x2="230" y2="340" strokeWidth="0.6"/>
            <line x1="100" y1="365" x2="230" y2="365" strokeWidth="0.6"/>
            <line x1="100" y1="390" x2="230" y2="390" strokeWidth="0.6"/>
            {/* dark corners — shadowy alcove bottom-centre */}
            <path d="M 350 420 L 480 420 L 480 470 L 350 470 Z" strokeDasharray="3 3" opacity="0.6"/>
            {/* threshold — a gated arch on the east wall */}
            <path d="M 620 360 L 700 360 L 700 440 L 620 440 Z" strokeWidth="1.2"/>
            <path d="M 620 360 Q 660 320 700 360" strokeWidth="1" opacity="0.75"/>
            <line x1="660" y1="360" x2="660" y2="440" strokeWidth="0.6" opacity="0.6"/>
          </g>

          {/* connecting paths — hairline dotted ink between places */}
          <g stroke="#6a4a1a" strokeWidth="0.8" fill="none" strokeDasharray="2 4" opacity="0.55">
            {PATHS.map(([a, b], i) => {
              const A = place(a), B = place(b);
              if (!A || !B) return null;
              const mx = (A.x + B.x) / 2 + (i % 2 ? 12 : -12);
              const my = (A.y + B.y) / 2 + (i % 2 ? -8 : 8);
              return <path key={i} d={`M ${A.x} ${A.y} Q ${mx} ${my} ${B.x} ${B.y}`} />;
            })}
          </g>

          {/* compass rose — bottom right */}
          <g transform="translate(720 510)" stroke="#5c4530" fill="none" strokeWidth="0.7">
            <circle r="22" strokeWidth="1"/>
            <circle r="14" opacity="0.5"/>
            <path d="M 0 -22 L 0 22 M -22 0 L 22 0" />
            <path d="M -16 -16 L 16 16 M 16 -16 L -16 16" opacity="0.4"/>
            <path d="M 0 -22 L 3 -6 L 0 0 L -3 -6 Z" fill="#5c4530" stroke="none"/>
            <text x="0" y="-26" textAnchor="middle" fontSize="10" fill="#8c1f1f"
                  fontFamily="var(--font-display)" letterSpacing="1.2">N</text>
          </g>

          {/* run-begin marker — descent arrow pointing south off the page */}
          <g transform="translate(400 540)" stroke="#8c1f1f" fill="#8c1f1f" filter="url(#ink-bleed)">
            <line x1="0" y1="-10" x2="0" y2="14" strokeWidth="1.4" strokeLinecap="round" fill="none"/>
            <path d="M 0 14 L -6 6 L 6 6 Z" strokeWidth="0.4"/>
            <text x="0" y="-16" textAnchor="middle" fontSize="9" fontFamily="var(--font-display)"
                  letterSpacing="2.6" fill="#8c1f1f">↡  THE DESCENT  ↡</text>
          </g>

          {/* sacred glow over the deep pool at tier 4+ */}
          {tier >= 4 && <circle cx="400" cy="220" r="120" fill="url(#sacred-glow)"/>}

          {/* location markers */}
          {PLACES.map((p) => {
            const sealed = p.tierGate && p.tierGate > tier;
            const isSel = selected === p.id;
            const dotFill = sealed ? '#5c4530' : '#8c1f1f';
            const ringColor = sealed ? '#5c4530' : isSel ? '#d4af37' : '#8c1f1f';
            return (
              <g key={p.id}
                 transform={`translate(${p.x} ${p.y})`}
                 className={`hub-marker${sealed ? ' sealed' : ''}${isSel ? ' selected' : ''}`}
                 onClick={() => !sealed && (window.Sfx?.play('page'), onSelect(p))}
                 style={{ cursor: sealed ? 'not-allowed' : 'pointer' }}>
                {/* outer ring */}
                <circle r="11" fill="#ede0c2" stroke={ringColor} strokeWidth="1.4"/>
                {/* inner pip */}
                <circle r="4" fill={dotFill}/>
                {sealed && <line x1="-8" y1="8" x2="8" y2="-8" stroke="#8c1f1f" strokeWidth="1.2" opacity="0.85"/>}
                {/* label — small leader line + brass underline + text */}
                <line x1="0" y1="0"
                      x2={p.labelDx > 0 ? p.labelDx - 2 : p.labelDx + 2}
                      y2={p.labelDy * 0.6}
                      stroke="#5c4530" strokeWidth="0.6" opacity="0.55"/>
                <text x={p.labelDx} y={p.labelDy}
                      textAnchor={p.labelAnchor || 'start'}
                      fontFamily="var(--font-display)"
                      fontWeight="700"
                      fontSize="11"
                      letterSpacing="1.8"
                      fill="#2a1d10">{p.name.toUpperCase()}</text>
                <text x={p.labelDx} y={p.labelDy + 13}
                      textAnchor={p.labelAnchor || 'start'}
                      fontFamily="var(--font-body)"
                      fontStyle="italic"
                      fontSize="11"
                      fill="#5c4530">— {p.keeper}</text>
              </g>
            );
          })}

          {/* illuminated title across the top */}
          <g>
            <text x="400" y="62" textAnchor="middle"
                  fontFamily="var(--font-display)" fontWeight="700"
                  fontSize="22" letterSpacing="6" fill="#8c1f1f">THE  ANTECHAMBER</text>
            <text x="400" y="80" textAnchor="middle"
                  fontFamily="var(--font-body)" fontStyle="italic"
                  fontSize="12" fill="#5c4530">— a cartograph of the holding-place, between worlds —</text>
          </g>
        </svg>

        {/* foot decorative ribbon — current tier rendered as marginalia */}
        <div className="hub-foot-ribbon">
          <span className="rubric" style={{ fontSize: 10, letterSpacing: '0.34em', color: 'var(--ink-rubric)' }}>
            Loop {7 + tier * 4} · Drawn at
          </span>
          <span style={{ font: '13px/1 var(--font-display)', fontWeight: 700, letterSpacing: '0.12em', color: 'var(--ink)', textTransform: 'uppercase' }}>
            Tier {tier} · {TIER_NAMES[tier]}
          </span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HubMap });
