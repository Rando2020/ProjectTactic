import { useState } from 'react'
import { BOON_RARITIES } from '../data/boons.js'

/**
 * Modal that appears when picking a movement boon would exceed the cap.
 * Player must choose which existing movement boon to replace.
 */
export default function BoonReplacementModal({ incomingBoon, existingBoons, onConfirm, onCancel }) {
  const [selectedBoonId, setSelectedBoonId] = useState(
    existingBoons.length > 0 ? existingBoons[0].id : null
  )

  function handleConfirm() {
    if (selectedBoonId) {
      onConfirm(incomingBoon, selectedBoonId)
    }
  }

  const incomingRarity = BOON_RARITIES[incomingBoon.rarity] ?? BOON_RARITIES.common

  return (
    <div style={s.overlay}>
      <div style={s.modal}>
        <h2 style={s.title}>Movement Boon Limit Reached</h2>
        <p style={s.subtitle}>
          You already have {existingBoons.length} movement boon{existingBoons.length === 1 ? '' : 's'}.
          Choose one to replace with your new selection.
        </p>

        {/* New Boon Preview */}
        <section style={s.section}>
          <h3 style={s.sectionTitle}>New Boon</h3>
          <div style={{ ...s.boonCard, borderColor: incomingRarity.border, background: incomingRarity.glow }}>
            <div style={s.boonTop}>
              <span style={s.boonIcon}>{incomingBoon.icon ?? '*'}</span>
              <span style={{ ...s.boonRarity, color: incomingRarity.color }}>
                {incomingRarity.label}
              </span>
            </div>
            <h4 style={s.boonName}>{incomingBoon.name}</h4>
            <p style={s.boonDesc}>{incomingBoon.description}</p>
          </div>
        </section>

        {/* Existing Movement Boons - Pick one to replace */}
        <section style={s.section}>
          <h3 style={s.sectionTitle}>Replace One</h3>
          <div style={s.boonList}>
            {existingBoons.map((boon) => {
              const rarity = BOON_RARITIES[boon.rarity] ?? BOON_RARITIES.common
              const isSelected = boon.id === selectedBoonId
              return (
                <label key={boon.id} style={{ ...s.boonOption, borderColor: isSelected ? rarity.color : 'rgba(255,255,255,.14)', background: isSelected ? 'rgba(255,255,255,.06)' : 'rgba(255,255,255,.02)', cursor: 'pointer' }}>
                  <input
                    type="radio"
                    name="replace-boon"
                    value={boon.id}
                    checked={isSelected}
                    onChange={() => setSelectedBoonId(boon.id)}
                    style={s.radio}
                  />
                  <div style={s.optionContent}>
                    <div style={s.optionTop}>
                      <span style={s.optionIcon}>{boon.icon ?? '*'}</span>
                      <span style={{ ...s.optionRarity, color: rarity.color }}>
                        {rarity.label}
                      </span>
                    </div>
                    <h4 style={s.optionName}>{boon.name}</h4>
                    <p style={s.optionDesc}>{boon.description}</p>
                  </div>
                </label>
              )
            })}
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
    background: 'rgba(0,0,0,.6)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
    padding: 16,
  },
  modal: {
    background: 'rgba(10,14,24,.95)',
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 24,
    padding: 32,
    maxWidth: 600,
    width: '100%',
    maxHeight: '90vh',
    overflow: 'auto',
    boxShadow: '0 20px 60px rgba(0,0,0,.6)',
  },
  title: {
    fontSize: 24,
    fontWeight: 900,
    margin: '0 0 8px',
    color: '#f7f0df',
  },
  subtitle: {
    fontSize: 14,
    color: 'rgba(247,240,223,.68)',
    margin: '0 0 24px',
    lineHeight: 1.6,
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
  },
  boonCard: {
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 16,
    padding: 16,
    background: 'rgba(255,255,255,.04)',
  },
  boonTop: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
    marginBottom: 8,
  },
  boonIcon: {
    fontSize: 28,
  },
  boonRarity: {
    fontSize: 11,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.12em',
  },
  boonName: {
    margin: '0 0 8px',
    fontSize: 18,
    color: '#f7f0df',
  },
  boonDesc: {
    margin: 0,
    fontSize: 13,
    color: 'rgba(247,240,223,.68)',
    lineHeight: 1.5,
  },
  boonList: {
    display: 'flex',
    flexDirection: 'column',
    gap: 10,
  },
  boonOption: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 12,
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 12,
    padding: 12,
    transition: 'all 150ms ease',
  },
  radio: {
    marginTop: 4,
    cursor: 'pointer',
  },
  optionContent: {
    flex: 1,
  },
  optionTop: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    marginBottom: 4,
  },
  optionIcon: {
    fontSize: 20,
  },
  optionRarity: {
    fontSize: 10,
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '.1em',
  },
  optionName: {
    margin: '0 0 4px',
    fontSize: 14,
    fontWeight: 700,
    color: '#f7f0df',
  },
  optionDesc: {
    margin: 0,
    fontSize: 12,
    color: 'rgba(247,240,223,.6)',
    lineHeight: 1.4,
  },
  actions: {
    display: 'flex',
    gap: 12,
    marginTop: 24,
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
    border: '1px solid rgba(201,167,86,.6)',
    background: 'rgba(201,167,86,.2)',
    color: '#f7f0df',
    fontWeight: 700,
    fontSize: 14,
    cursor: 'pointer',
    transition: 'all 150ms ease',
  },
}
