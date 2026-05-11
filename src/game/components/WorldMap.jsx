import { TOWNS } from '../data/towns.js'

export default function WorldMap({ unlockedTownIds, currentTownId, onSelectTown, onOpenQuestLog }) {
  const unlocked = new Set(unlockedTownIds)

  return (
    <main style={styles.shell}>
      <header style={styles.header}>
        <div>
          <p style={styles.eyebrow}>World Map</p>
          <h1 style={styles.title}>Vaelthar Lowlands</h1>
          <p style={styles.copy}>Choose a town, follow the Guardian disturbance, and unlock the next route through story progress.</p>
        </div>
        <button style={styles.secondaryButton} onClick={onOpenQuestLog}>Quest Log</button>
      </header>

      <section style={styles.mapPanel}>
        <div style={styles.mapGlow} />
        {Object.values(TOWNS).map((town) => {
          const isUnlocked = unlocked.has(town.id)
          const isCurrent = town.id === currentTownId
          return (
            <button
              key={town.id}
              disabled={!isUnlocked}
              onClick={() => onSelectTown(town.id)}
              title={isUnlocked ? town.name : 'Locked'}
              style={{
                ...styles.townNode,
                left: `${town.mapPosition.x}%`,
                top: `${town.mapPosition.y}%`,
                opacity: isUnlocked ? 1 : 0.28,
                transform: `translate(-50%, -50%) scale(${isCurrent ? 1.12 : 1})`,
                borderColor: isCurrent ? '#ffd86b' : 'rgba(255,255,255,0.26)'
              }}
            >
              <span style={styles.nodeDot}>{isUnlocked ? '◆' : '◇'}</span>
              <span style={styles.nodeName}>{town.name}</span>
            </button>
          )
        })}
      </section>
    </main>
  )
}

const styles = {
  shell: {
    minHeight: '100vh',
    padding: 24,
    color: '#f8f5ff',
    background:
      'radial-gradient(circle at 22% 58%, rgba(9, 132, 227, 0.16), transparent 28%), radial-gradient(circle at 72% 32%, rgba(255, 216, 107, 0.14), transparent 28%), #050615'
  },
  header: {
    maxWidth: 1180,
    margin: '0 auto 20px',
    display: 'flex',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    gap: 20
  },
  eyebrow: {
    margin: 0,
    color: '#b8b3ff',
    textTransform: 'uppercase',
    letterSpacing: '0.18em',
    fontSize: 12,
    fontWeight: 800
  },
  title: {
    margin: '8px 0',
    fontSize: 'clamp(34px, 5vw, 64px)',
    lineHeight: 1
  },
  copy: {
    margin: 0,
    color: 'rgba(248,245,255,0.78)',
    maxWidth: 680,
    fontSize: 16
  },
  secondaryButton: {
    padding: '12px 18px',
    borderRadius: 999,
    border: '1px solid rgba(255,255,255,0.22)',
    background: 'rgba(255,255,255,0.08)',
    color: 'white',
    fontWeight: 800,
    cursor: 'pointer'
  },
  mapPanel: {
    position: 'relative',
    width: 'min(1180px, 100%)',
    height: 'min(68vh, 620px)',
    minHeight: 420,
    margin: '0 auto',
    overflow: 'hidden',
    borderRadius: 28,
    border: '1px solid rgba(255,255,255,0.14)',
    background:
      'linear-gradient(135deg, rgba(16,22,55,0.96), rgba(4,5,18,0.94)), repeating-linear-gradient(45deg, rgba(255,255,255,0.04) 0 1px, transparent 1px 18px)',
    boxShadow: '0 24px 80px rgba(0,0,0,0.44)'
  },
  mapGlow: {
    position: 'absolute',
    inset: '12% 8%',
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(143,99,255,0.22), transparent 68%)',
    filter: 'blur(20px)'
  },
  townNode: {
    position: 'absolute',
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '10px 14px',
    borderRadius: 999,
    border: '1px solid rgba(255,255,255,0.26)',
    background: 'rgba(8, 10, 28, 0.86)',
    color: 'white',
    fontWeight: 900,
    cursor: 'pointer',
    transition: 'transform 160ms ease, opacity 160ms ease, border-color 160ms ease'
  },
  nodeDot: {
    color: '#ffd86b'
  },
  nodeName: {
    whiteSpace: 'nowrap'
  }
}
