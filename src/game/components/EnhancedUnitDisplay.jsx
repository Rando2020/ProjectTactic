/**
 * Enhanced unit display with better class silhouettes, portraits, and facing indicators.
 * This replaces the simple emoji-based system with a more polished FFT/Disgaea-style look.
 */

// Job color system with silhouette icons and descriptions
export const JOB_PROFILES = {
  // Tank/Defender jobs
  warder: {
    label: 'Warder',
    bg: '#dc2626',
    border: '#991b1b',
    text: '#fecaca',
    icon: '⚔️',
    silhouette: '🛡️',
    accent: '#ff6b6b',
    description: 'Tank — Guard allies',
  },
  null_breaker: {
    label: 'Null Breaker',
    bg: '#b91c1c',
    border: '#7f1d1d',
    text: '#fecaca',
    icon: '🗡️',
    silhouette: '⚔️',
    accent: '#ff8787',
    description: 'Warrior — Heavy damage',
  },

  // Healer jobs
  luminary: {
    label: 'Luminary',
    bg: '#059669',
    border: '#065f46',
    text: '#d1fae5',
    icon: '✨',
    silhouette: '✨',
    accent: '#31d584',
    description: 'Healer — Restore allies',
  },
  seraph: {
    label: 'Seraph',
    bg: '#0891b2',
    border: '#164e63',
    text: '#cffafe',
    icon: '☆',
    silhouette: '⭐',
    accent: '#22d3ee',
    description: 'Holy — Blessed support',
  },

  // Caster jobs
  arcanist: {
    label: 'Arcanist',
    bg: '#7c3aed',
    border: '#4c1d95',
    text: '#e9d5ff',
    icon: '⚡',
    silhouette: '✦',
    accent: '#a78bfa',
    description: 'Mage — Elemental spells',
  },
  etherweaver: {
    label: 'Etherweaver',
    bg: '#6366f1',
    border: '#312e81',
    text: '#e0e7ff',
    icon: '◆',
    silhouette: '✪',
    accent: '#818cf8',
    description: 'Caster — Control magic',
  },

  // Summoner/Guardian jobs
  resonant: {
    label: 'Resonant',
    bg: '#d97706',
    border: '#92400e',
    text: '#fef3c7',
    icon: '◎',
    silhouette: '◎',
    accent: '#fb923c',
    description: 'Summoner — Void tech',
  },
  primal_binder: {
    label: 'Primal Binder',
    bg: '#ca8a04',
    border: '#713f12',
    text: '#fef08a',
    icon: '⊕',
    silhouette: '◉',
    accent: '#fcd34d',
    description: 'Guardian — Bind power',
  },

  // Jump attacker
  skywarden: {
    label: 'Skywarden',
    bg: '#0ea5e9',
    border: '#0c4a6e',
    text: '#cffafe',
    icon: '△',
    silhouette: '△',
    accent: '#38bdf8',
    description: 'Jumper — Aerial strikes',
  },

  // Default
  default: {
    label: 'Adventurer',
    bg: '#4b5563',
    border: '#1e293b',
    text: '#cbd5e1',
    icon: '◇',
    silhouette: '◇',
    accent: '#9ca3af',
    description: 'Unknown — Varied tactics',
  },
}

export const getJobProfile = (jobId) => JOB_PROFILES[jobId] || JOB_PROFILES.default

/**
 * Enhanced unit portrait with better visual hierarchy and class clarity
 */
export function EnhancedUnitPortrait({
  unit,
  isSelected = false,
  isActive = false,
  isFlashing = false,
  size = 'normal', // 'small' | 'normal' | 'large'
}) {
  const profile = getJobProfile(unit.baseJobId || unit.currentJobId)
  const initials = unit.name.split(' ').map(n => n[0]).join('')

  const sizeMap = {
    small: { portrait: 20, icon: 8, initials: 7, barHeight: 2 },
    normal: { portrait: 28, icon: 10, initials: 8, barHeight: 3 },
    large: { portrait: 40, icon: 14, initials: 11, barHeight: 4 },
  }

  const dims = sizeMap[size]

  return (
    <div
      style={{
        position: 'relative',
        width: dims.portrait,
        height: dims.portrait,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Main portrait circle */}
      <div
        style={{
          width: dims.portrait,
          height: dims.portrait,
          borderRadius: '50%',
          border: `2px solid ${profile.border}`,
          background: profile.bg,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative',
          fontSize: dims.initials,
          fontWeight: 900,
          color: profile.text,
          textShadow: '0 1px 2px rgba(0,0,0,.5)',
          filter: isSelected
            ? `drop-shadow(0 0 8px ${profile.border})`
            : isActive
            ? `drop-shadow(0 0 4px ${profile.border})`
            : 'none',
          opacity: isFlashing ? 0.9 : 1,
          boxShadow: isFlashing
            ? `0 0 12px ${profile.accent}, inset 0 0 8px rgba(255,255,150,.3)`
            : 'none',
          animation: size === 'normal' ? 'juicyBob 2.2s ease-in-out infinite' : 'none',
          transition: 'all 150ms ease',
        }}
      >
        {/* Class silhouette icon */}
        <div
          style={{
            position: 'absolute',
            fontSize: dims.icon,
            top: 2,
            right: 1,
            opacity: 0.95,
            lineHeight: 1,
            filter: `drop-shadow(0 1px 2px rgba(0,0,0,.5))`,
          }}
        >
          {profile.silhouette}
        </div>

        {/* Initials center */}
        <div style={{ position: 'relative', zIndex: 2 }}>{initials}</div>
      </div>

      {/* Enemy badge */}
      {unit.team === 'enemy' && (
        <div
          style={{
            position: 'absolute',
            top: -4,
            right: -4,
            width: dims.portrait * 0.5,
            height: dims.portrait * 0.5,
            background: '#dc2626',
            border: '1px solid #991b1b',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: dims.icon * 0.7,
            fontWeight: 900,
            color: '#fff',
            zIndex: 3,
          }}
        >
          E
        </div>
      )}

      {/* Status indicators on side */}
      {unit.statuses?.length > 0 && (
        <div
          style={{
            position: 'absolute',
            right: -12,
            top: '50%',
            transform: 'translateY(-50%)',
            display: 'flex',
            flexDirection: 'column',
            gap: 2,
          }}
        >
          {unit.statuses.slice(0, 3).map((status, idx) => (
            <div
              key={idx}
              style={{
                width: 6,
                height: 6,
                borderRadius: '50%',
                background:
                  status.id === 'bleed'
                    ? '#ef4444'
                    : status.id === 'burning'
                    ? '#f97316'
                    : status.id === 'blessed'
                    ? '#4ade80'
                    : status.id === 'stun'
                    ? '#fbbf24'
                    : '#9ca3af',
                border: '1px solid rgba(255,255,255,.3)',
              }}
              title={status.id}
            />
          ))}
        </div>
      )}
    </div>
  )
}

/**
 * Job class indicator card shown on hover or in unit info
 */
export function JobIndicator({ jobId, size = 'compact' }) {
  const profile = getJobProfile(jobId)

  if (size === 'compact') {
    return (
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 6,
          padding: '4px 8px',
          borderRadius: 6,
          background: profile.bg,
          border: `1px solid ${profile.border}`,
          color: profile.text,
          fontSize: 11,
          fontWeight: 700,
        }}
      >
        <span>{profile.silhouette}</span>
        <span>{profile.label}</span>
      </div>
    )
  }

  // Full card
  return (
    <div
      style={{
        padding: 12,
        borderRadius: 10,
        background: profile.bg,
        border: `2px solid ${profile.border}`,
        color: profile.text,
      }}
    >
      <div style={{ fontSize: 24, marginBottom: 6 }}>{profile.silhouette}</div>
      <div style={{ fontSize: 14, fontWeight: 900, marginBottom: 4 }}>
        {profile.label}
      </div>
      <div style={{ fontSize: 12, opacity: 0.8 }}>{profile.description}</div>
    </div>
  )
}

/**
 * Facing indicator with enhanced visibility
 */
export function FacingIndicator({ facing, style }) {
  const facingMap = {
    N: { symbol: '↑', label: 'North', angle: 0 },
    E: { symbol: '→', label: 'East', angle: 90 },
    S: { symbol: '↓', label: 'South', angle: 180 },
    W: { symbol: '←', label: 'West', angle: 270 },
  }

  const f = facingMap[facing] || facingMap.S

  return (
    <div
      style={{
        ...style,
        width: 20,
        height: 20,
        borderRadius: 999,
        background: 'rgba(0,0,0,.6)',
        border: '2px solid #fff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 12,
        fontWeight: 900,
        color: '#fff',
        textShadow: '0 1px 3px rgba(0,0,0,.8)',
        transform: `rotate(${f.angle}deg)`,
        title: `Facing ${f.label}`,
      }}
    >
      {f.symbol}
    </div>
  )
}

/**
 * Status bar group with labels (HP, Temper, Ether)
 */
export function StatusBars({ unit, direction = 'vertical', size = 'normal' }) {
  const maxHp = unit.stats?.hp ?? unit.hp ?? 1
  const maxTemper = unit.stats?.temper ?? unit.temper ?? 1
  const maxEther = unit.stats?.ether ?? unit.ether ?? 1

  const bars = [
    { current: unit.hp, max: maxHp, color: '#4ade80', label: 'HP' },
    { current: unit.temper, max: maxTemper, color: '#f97316', label: 'TMP' },
    { current: unit.ether, max: maxEther, color: '#a78bfa', label: 'ETH' },
  ]

  const sizeMap = {
    small: { height: 2, gap: 1, fontSize: 7 },
    normal: { height: 3, gap: 2, fontSize: 8 },
    large: { height: 4, gap: 2, fontSize: 9 },
  }

  const dims = sizeMap[size]

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: direction === 'horizontal' ? 'row' : 'column',
        gap: dims.gap,
        width: direction === 'horizontal' ? '100%' : 'auto',
      }}
    >
      {bars.map((bar, idx) => (
        <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          {direction === 'vertical' && (
            <div style={{ fontSize: dims.fontSize, fontWeight: 700, width: 20, color: bar.color }}>
              {bar.label}
            </div>
          )}
          <div
            style={{
              flex: 1,
              height: dims.height,
              borderRadius: 2,
              background: 'rgba(0,0,0,.5)',
              overflow: 'hidden',
              minWidth: 60,
            }}
          >
            <div
              style={{
                height: '100%',
                width: `${Math.max(0, (bar.current / bar.max) * 100)}%`,
                background: bar.color,
                transition: 'width 200ms ease',
              }}
            />
          </div>
          {direction === 'horizontal' && (
            <div style={{ fontSize: dims.fontSize, fontWeight: 700, width: 30, color: bar.color }}>
              {bar.label}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}

// Add CSS for juicy bob animation with more prominent movement
const juicyBobStyles = `
  @keyframes juicyBob {
    0% { transform: translateY(0px); }
    50% { transform: translateY(-3px); }
    100% { transform: translateY(0px); }
  }

  @keyframes hitFlash {
    0% { filter: brightness(1) drop-shadow(0 0 0px rgba(255,255,150,0)); }
    50% { filter: brightness(1.4) drop-shadow(0 0 12px rgba(255,255,150,.8)); }
    100% { filter: brightness(1) drop-shadow(0 0 0px rgba(255,255,150,0)); }
  }

  @keyframes impactPulse {
    0% { transform: scale(1); }
    50% { transform: scale(1.08); }
    100% { transform: scale(1); }
  }
`

if (typeof window !== 'undefined' && !document.querySelector('style[data-battle-juice]')) {
  const style = document.createElement('style')
  style.setAttribute('data-battle-juice', 'true')
  style.textContent = juicyBobStyles
  document.head.appendChild(style)
}
