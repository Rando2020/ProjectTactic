import { useState } from 'react'
import { BOON_RARITIES, getBoonLane, BOON_LANE_LIMITS } from '../data/boons.js'
import BoonCard from '../components/BoonCard.jsx'

/**
 * Modal that appears when picking a movement boon would exceed the cap.
 * Player must choose which existing movement boon to replace.
 */
export default function BoonReplacementModal({ incomingBoon, existingBoons, onConfirm, onCancel }) {
  const [selectedBoonId, setSelectedBoonId] = useState(
    existingBoons.length > 0 ? existingBoons[0].id : null
  )
  const lane = getBoonLane(incomingBoon)
  const laneLimit = BOON_LANE_LIMITS[lane] ?? 999
  const getLaneLabel = () => {
    if (!lane) return ''
    if (lane === 'movement') return 'Movement'
    return lane.charAt(0).toUpperCase() + lane.slice(1)
  }

  function handleConfirm() {
    if (selectedBoonId) {
      onConfirm(incomingBoon, selectedBoonId)
    }
  }

  const incomingRarity = BOON_RARITIES[incomingBoon.rarity] ?? BOON_RARITIES.common

  return (
    <div style={s.overlay}>
      <div style={s.modal}>
        <h2 style={s.title}>
          <span style={s.titleIcon}>⚠️</span>
          {getLaneLabel()} Lane is Full
        </h2>
        <div style={s.subtitle}>
          <p style={s.subtitleMain}>
            You can carry a maximum of <strong>{laneLimit}</strong> {getLaneLabel().toLowerCase()} boon{laneLimit > 1 ? 's' : ''} in a single run.
          </p>
          <p style={s.subtitleSecondary}>
            Choose one of your existing boons to replace with this new blessing.
          </p>
        </div>

        {/* Lane Visualization */}
        <section style={s.laneVisualization}>
          <div style={s.laneVisHeader}>
            <span style={s.laneVisLabel}>{getLaneLabel()} Lane Status</span>
            <span style={s.laneVisCount}>{existingBoons.length}/{laneLimit} (FULL)</span>
          </div>
          <div style={s.laneVisBar}>
            {[...Array(laneLimit)].map((_, i) => (
              <div
                key={i}
                style={{
                  ...s.laneVisSlot,
                  background: i < existingBoons.length ? incomingRarity.color : 'rgba(255,255,255,.08)',
                  opacity: i < existingBoons.length ? 0.7 : 1,
                }}
              />
            ))}
          </div>
        </section>

        {/* New Boon Preview */}
        <section style={s.section}>
          <h3 style={s.sectionTitle}>
            <span style={s.sectionIcon}>+</span>
            Incoming Blessing
          </h3>
          <BoonCard
            boon={incomingBoon}
            activeBoons={existingBoons}
            variant="compact"
            showLaneInfo={false}
          />
        </section>

        {/* Existing Movement Boons - Pick one to replace */}
        <section style={s.section}>
          <h3 style={s.sectionTitle}>
            <span style={s.sectionIcon}>→</span>
            Choose One to Replace
          </h3>
          <div style={s.boonList}>
            {existingBoons.map((boon) => (
              <label key={boon.id} style={s.radioLabel}>
                <input
                  type="radio"
                  name="replace-boon"
                  value={boon.id}
                  checked={boon.id === selectedBoonId}
                  onChange={() => setSelectedBoonId(boon.id)}
                  style={s.radio}
                />
                <BoonCard
                  boon={boon}
                  isSelected={boon.id === selectedBoonId}
                  variant="compact"
                  showLaneInfo={false}
                />
              </label>
            ))}
          </div>
        </section>

        {/* Action Buttons */}
        <div style={s.actions}>
          <button style={s.cancelBtn} onClick={onCancel}>
            Cancel
          </button>
          <button style={s.confirmBtn} onClick={handleConfirm}>
            Confirm Replacement
          </button>
        </div>
      </div>
    </div>
  )
}

const s = {
  overlay: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: 'rgba(0,0,0,.7)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
    padding: 16,
  },
  modal: {
    background: 'rgba(10,14,24,.98)',
    border: '2px solid rgba(239,68,68,.4)',
    borderRadius: 24,
    padding: 32,
    maxWidth: 620,
    width: '100%',
    maxHeight: '90vh',
    overflow: 'auto',
    boxShadow: '0 25px 60px rgba(0,0,0,.8), 0 0 40px rgba(239,68,68,.15)',
  },

  title: {
    fontSize: 24,
    fontWeight: 900,
    margin: '0 0 12px',
    color: '#f7f0df',
    display: 'flex',
    alignItems: 'center',
    gap: 12,
  },

  titleIcon: {
    fontSize: 28,
  },

  subtitle: {
    margin: '0 0 24px',
  },

  subtitleMain: {
    margin: 0,
    fontSize: 14,
    color: 'rgba(247,240,223,.78)',
    lineHeight: 1.6,
    marginBottom: 8,
  },

  subtitleSecondary: {
    margin: 0,
    fontSize: 13,
    color: 'rgba(247,240,223,.6)',
    lineHeight: 1.5,
  },

  laneVisualization: {
    marginBottom: 24,
    padding: 16,
    background: 'rgba(239,68,68,.08)',
    border: '1px solid rgba(239,68,68,.2)',
    borderRadius: 12,
  },

  laneVisHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },

  laneVisLabel: {
    fontSize: 11,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.1em',
  },

  laneVisCount: {
    fontSize: 12,
    fontWeight: 900,
    color: '#fca5a5',
  },

  laneVisBar: {
    display: 'flex',
    gap: 6,
  },

  laneVisSlot: {
    flex: 1,
    height: 12,
    borderRadius: 4,
    transition: 'all 200ms ease',
  },

  section: {
    marginBottom: 24,
  },

  sectionTitle: {
    fontSize: 12,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.12em',
    margin: '0 0 12px',
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },

  sectionIcon: {
    fontSize: 14,
  },

  boonList: {
    display: 'flex',
    flexDirection: 'column',
    gap: 10,
  },

  radioLabel: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 12,
    cursor: 'pointer',
  },

  radio: {
    marginTop: 10,
    cursor: 'pointer',
    minWidth: 20,
    minHeight: 20,
    accentColor: '#c9a756',
  },

  actions: {
    display: 'flex',
    gap: 12,
    marginTop: 28,
  },

  cancelBtn: {
    flex: 1,
    padding: '12px 16px',
    borderRadius: 10,
    border: '1px solid rgba(255,255,255,.18)',
    background: 'rgba(255,255,255,.06)',
    color: '#f7f0df',
    fontWeight: 700,
    fontSize: 14,
    cursor: 'pointer',
    transition: 'all 150ms ease',
  },

  confirmBtn: {
    flex: 1,
    padding: '12px 16px',
    borderRadius: 10,
    border: '2px solid rgba(239,68,68,.4)',
    background: 'rgba(239,68,68,.15)',
    color: '#f7f0df',
    fontWeight: 700,
    fontSize: 14,
    cursor: 'pointer',
    transition: 'all 150ms ease',
  },
}
