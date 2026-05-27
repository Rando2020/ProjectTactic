import { useState } from 'react'
import { BOON_RARITIES, getBoonLane, BOON_LANE_LIMITS, getBoonsInLane } from '../data/boons.js'

/**
 * Reusable boon card component with hover details and lane information.
 * Used in both BoonPickScreen and BoonReplacementModal.
 */
export default function BoonCard({
  boon,
  onSelect,
  isSelected = false,
  activeBoons = [],
  selectionReason = '',
  variant = 'full', // 'full' | 'compact' | 'selection'
  showLaneInfo = true,
}) {
  const [isHovering, setIsHovering] = useState(false)
  const rarity = BOON_RARITIES[boon.rarity] ?? BOON_RARITIES.common
  const lane = getBoonLane(boon)
  const laneBoonsCount = lane ? getBoonsInLane(activeBoons, lane).length : 0
  const laneLimit = lane ? BOON_LANE_LIMITS[lane] : null
  const laneIsFull = lane && laneLimit && laneBoonsCount >= laneLimit

  // Determine lane display label
  const getLaneLabel = () => {
    if (!lane) return ''
    if (lane === 'movement') return 'Movement'
    return lane.charAt(0).toUpperCase() + lane.slice(1)
  }

  if (variant === 'compact') {
    // Minimal card for modal replacement options
    return (
      <div
        onMouseEnter={() => setIsHovering(true)}
        onMouseLeave={() => setIsHovering(false)}
        style={{
          ...s.compactCard,
          borderColor: isSelected ? rarity.color : 'rgba(255,255,255,.14)',
          background: isSelected ? 'rgba(255,255,255,.06)' : 'rgba(255,255,255,.02)',
          position: 'relative',
        }}
      >
        <div style={s.compactIcon}>{boon.icon ?? '*'}</div>
        <div style={s.compactContent}>
          <div style={s.compactTop}>
            <h4 style={s.compactName}>{boon.name}</h4>
            <span style={{ ...s.compactRarity, color: rarity.color }}>
              {rarity.label}
            </span>
          </div>
          <p style={s.compactDesc}>{boon.description}</p>
        </div>

        {/* Hover tooltip */}
        {isHovering && (
          <div style={s.hoverTooltip}>
            <p style={s.tooltipDesc}>{boon.description}</p>
            {boon.flavour && <p style={s.tooltipFlavour}>{boon.flavour}</p>}
            {lane && (
              <div style={s.tooltipLane}>
                <span style={s.toLaneLabel}>{getLaneLabel()} Lane:</span>
                <span style={s.toLaneCount}>
                  {laneBoonsCount}/{laneLimit} slots
                </span>
              </div>
            )}
          </div>
        )}
      </div>
    )
  }

  // Full variant for BoonPickScreen
  return (
    <article
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => setIsHovering(false)}
      style={{
        ...s.card,
        borderColor: rarity.border,
        background: rarity.glow,
        position: 'relative',
      }}
    >
      {/* Top section: Icon and Rarity */}
      <div style={s.cardTop}>
        <span style={s.icon}>{boon.icon ?? '*'}</span>
        <div style={s.topRight}>
          <span style={{ ...s.rarity, color: rarity.color }}>{rarity.label}</span>
          {showLaneInfo && lane && (
            <div style={{ ...s.laneBadge, borderColor: rarity.color, color: rarity.color }}>
              {getLaneLabel()}
              {laneLimit && ` (${laneBoonsCount}/${laneLimit})`}
            </div>
          )}
        </div>
      </div>

      {/* Main content */}
      <h3 style={s.cardTitle}>{boon.name}</h3>
      <p style={s.copy}>{boon.description}</p>
      {boon.flavour && <p style={s.flavour}>{boon.flavour}</p>}

      {/* Lane full warning */}
      {laneIsFull && (
        <div style={s.laneFullWarning}>
          ⚠️ Lane full — choosing this will replace an existing boon
        </div>
      )}

      {/* Selection context */}
      {selectionReason && (
        <div style={s.selectionReason}>
          <strong>Why offered:</strong> {selectionReason}
        </div>
      )}

      {/* Action button */}
      {onSelect && (
        <button
          style={{ ...s.pickBtn, borderColor: rarity.border, opacity: laneIsFull ? 0.8 : 1 }}
          onClick={() => onSelect(boon)}
        >
          {laneIsFull ? 'Choose & Replace' : 'Choose Boon'}
        </button>
      )}

      {/* Hover details card */}
      {isHovering && (
        <div style={s.hoverCard}>
          <div style={s.hoverHeader}>
            <span style={s.hoverIcon}>{boon.icon ?? '*'}</span>
            <div>
              <div style={s.hoverTitle}>{boon.name}</div>
              <div style={{ ...s.hoverRarity, color: rarity.color }}>{rarity.label}</div>
            </div>
          </div>

          <div style={s.hoverBody}>
            <p style={s.hoverDesc}>{boon.description}</p>
            {boon.flavour && <p style={s.hoverFlavour}>{boon.flavour}</p>}

            {lane && (
              <div style={s.hoverLaneInfo}>
                <div style={s.laneLabel}>{getLaneLabel()} Lane</div>
                <div style={s.laneBar}>
                  {[...Array(laneLimit)].map((_, i) => (
                    <div
                      key={i}
                      style={{
                        ...s.laneSlot,
                        background: i < laneBoonsCount ? rarity.color : 'rgba(255,255,255,.1)',
                      }}
                    />
                  ))}
                </div>
                <div style={s.laneStatus}>
                  {laneBoonsCount}/{laneLimit} slots used
                  {laneIsFull && (
                    <span style={s.laneFull}> — FULL</span>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </article>
  )
}

const s = {
  // ── FULL VARIANT (BoonPickScreen) ──
  card: {
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 16,
    padding: 16,
    minHeight: 280,
    display: 'flex',
    flexDirection: 'column',
    gap: 10,
    position: 'relative',
    transition: 'all 200ms ease',
  },

  cardTop: {
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: 12,
  },

  topRight: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
    gap: 6,
  },

  icon: {
    fontSize: 32,
    display: 'flex',
    alignItems: 'center',
  },

  rarity: {
    fontSize: 11,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.12em',
  },

  laneBadge: {
    fontSize: 9,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.1em',
    border: '1px solid',
    borderRadius: 4,
    padding: '2px 6px',
    background: 'rgba(255,255,255,.04)',
  },

  cardTitle: {
    margin: 0,
    fontSize: 20,
    fontWeight: 700,
  },

  copy: {
    margin: 0,
    color: 'rgba(247,240,223,.68)',
    fontSize: 14,
    lineHeight: 1.6,
  },

  flavour: {
    margin: 'auto 0 0',
    color: 'rgba(247,240,223,.46)',
    fontSize: 12,
    lineHeight: 1.55,
    fontStyle: 'italic',
  },

  laneFullWarning: {
    marginTop: 6,
    padding: 8,
    background: 'rgba(239,68,68,.12)',
    border: '1px solid rgba(239,68,68,.25)',
    borderRadius: 8,
    fontSize: 12,
    color: '#fca5a5',
    lineHeight: 1.4,
  },

  selectionReason: {
    marginTop: 6,
    padding: 8,
    background: 'rgba(201,167,86,.1)',
    border: '1px solid rgba(201,167,86,.25)',
    borderRadius: 8,
    fontSize: 12,
    color: '#f0e7d8',
    lineHeight: 1.4,
  },

  pickBtn: {
    marginTop: 'auto',
    padding: '10px 14px',
    borderRadius: 10,
    border: '1px solid rgba(201,167,86,.45)',
    background: 'rgba(255,255,255,.07)',
    color: '#f7f0df',
    fontWeight: 900,
    cursor: 'pointer',
    fontFamily: 'inherit',
    transition: 'all 150ms ease',
  },

  // ── HOVER CARD ──
  hoverCard: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 100,
    background: 'rgba(10,14,24,.98)',
    border: '2px solid rgba(255,255,255,.2)',
    borderRadius: 16,
    padding: 16,
    boxShadow: '0 16px 48px rgba(0,0,0,.6)',
    minWidth: 280,
    animation: 'fadeInBoonHover 150ms ease',
  },

  hoverHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    marginBottom: 12,
    paddingBottom: 12,
    borderBottom: '1px solid rgba(255,255,255,.1)',
  },

  hoverIcon: {
    fontSize: 36,
    display: 'flex',
    alignItems: 'center',
  },

  hoverTitle: {
    fontSize: 16,
    fontWeight: 700,
    margin: 0,
    color: '#f7f0df',
  },

  hoverRarity: {
    fontSize: 11,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.1em',
    marginTop: 2,
  },

  hoverBody: {
    display: 'flex',
    flexDirection: 'column',
    gap: 10,
  },

  hoverDesc: {
    margin: 0,
    fontSize: 13,
    color: 'rgba(247,240,223,.78)',
    lineHeight: 1.6,
  },

  hoverFlavour: {
    margin: 0,
    fontSize: 12,
    color: 'rgba(247,240,223,.52)',
    lineHeight: 1.55,
    fontStyle: 'italic',
    paddingLeft: 10,
    borderLeft: '2px solid rgba(201,167,86,.3)',
  },

  hoverLaneInfo: {
    paddingTop: 8,
    borderTop: '1px solid rgba(255,255,255,.1)',
  },

  laneLabel: {
    fontSize: 11,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.1em',
    marginBottom: 6,
  },

  laneBar: {
    display: 'flex',
    gap: 4,
    marginBottom: 6,
  },

  laneSlot: {
    flex: 1,
    height: 8,
    borderRadius: 2,
    transition: 'all 200ms ease',
  },

  laneStatus: {
    fontSize: 12,
    color: 'rgba(247,240,223,.68)',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  laneFull: {
    color: '#fca5a5',
    fontWeight: 700,
  },

  // ── COMPACT VARIANT (Modal) ──
  compactCard: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 12,
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 12,
    padding: 12,
    transition: 'all 150ms ease',
    cursor: 'pointer',
    position: 'relative',
  },

  compactIcon: {
    fontSize: 24,
    display: 'flex',
    alignItems: 'center',
    flexShrink: 0,
  },

  compactContent: {
    flex: 1,
  },

  compactTop: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    marginBottom: 4,
  },

  compactName: {
    margin: 0,
    fontSize: 14,
    fontWeight: 700,
    color: '#f7f0df',
  },

  compactRarity: {
    fontSize: 10,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.1em',
  },

  compactDesc: {
    margin: 0,
    fontSize: 12,
    color: 'rgba(247,240,223,.6)',
    lineHeight: 1.4,
  },

  // ── HOVER TOOLTIP (for compact variant) ──
  hoverTooltip: {
    position: 'absolute',
    bottom: '100%',
    left: 0,
    right: 0,
    background: 'rgba(10,14,24,.98)',
    border: '1px solid rgba(255,255,255,.2)',
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    minWidth: 200,
    zIndex: 100,
    boxShadow: '0 8px 24px rgba(0,0,0,.5)',
  },

  tooltipDesc: {
    margin: 0,
    fontSize: 12,
    color: 'rgba(247,240,223,.78)',
    lineHeight: 1.5,
    marginBottom: 6,
  },

  tooltipFlavour: {
    margin: 0,
    fontSize: 11,
    color: 'rgba(247,240,223,.52)',
    lineHeight: 1.4,
    fontStyle: 'italic',
    marginBottom: 6,
  },

  tooltipLane: {
    paddingTop: 6,
    borderTop: '1px solid rgba(255,255,255,.1)',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  toLaneLabel: {
    fontSize: 10,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.08em',
  },

  toLaneCount: {
    fontSize: 11,
    color: 'rgba(247,240,223,.68)',
    fontWeight: 700,
  },
}

// Add animation keyframe
if (typeof window !== 'undefined') {
  const style = document.createElement('style')
  style.textContent = `
    @keyframes fadeInBoonHover {
      from { opacity: 0; transform: scale(0.95); }
      to { opacity: 1; transform: scale(1); }
    }
  `
  document.head.appendChild(style)
}
