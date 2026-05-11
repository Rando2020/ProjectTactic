export default function StoryScene({ chapter, beatIndex, onNext }) {
  const beat = chapter?.beats?.[beatIndex]
  const isLastBeat = beatIndex >= (chapter?.beats?.length || 1) - 1

  if (!chapter || !beat) {
    return (
      <main style={styles.shell}>
        <section style={styles.card}>
          <p style={styles.eyebrow}>Story unavailable</p>
          <h1 style={styles.title}>No scene loaded</h1>
          <button style={styles.primaryButton} onClick={onNext}>Continue</button>
        </section>
      </main>
    )
  }

  return (
    <main style={styles.shell}>
      <section style={styles.card}>
        <p style={styles.eyebrow}>Chapter</p>
        <h1 style={styles.title}>{chapter.title}</h1>
        <div style={styles.dialogueBox}>
          <p style={styles.speaker}>{beat.speaker}</p>
          <p style={styles.dialogue}>{beat.text}</p>
        </div>
        <button style={styles.primaryButton} onClick={onNext}>
          {isLastBeat ? 'Enter World' : 'Continue'}
        </button>
      </section>
    </main>
  )
}

const styles = {
  shell: {
    minHeight: '100vh',
    display: 'grid',
    placeItems: 'center',
    padding: 24,
    color: '#f8f5ff',
    background:
      'radial-gradient(circle at 20% 20%, rgba(123, 73, 255, 0.24), transparent 32%), radial-gradient(circle at 80% 60%, rgba(255, 107, 53, 0.16), transparent 34%), #050615'
  },
  card: {
    width: 'min(920px, 100%)',
    padding: 32,
    border: '1px solid rgba(255,255,255,0.14)',
    borderRadius: 24,
    background: 'rgba(9, 10, 28, 0.86)',
    boxShadow: '0 24px 80px rgba(0,0,0,0.42)',
    backdropFilter: 'blur(14px)'
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
    margin: '10px 0 28px',
    fontSize: 'clamp(36px, 6vw, 72px)',
    lineHeight: 0.95
  },
  dialogueBox: {
    padding: 24,
    borderRadius: 18,
    background: 'linear-gradient(135deg, rgba(255,255,255,0.09), rgba(255,255,255,0.03))',
    border: '1px solid rgba(255,255,255,0.12)',
    minHeight: 190
  },
  speaker: {
    margin: 0,
    color: '#ffd86b',
    fontWeight: 900,
    textTransform: 'uppercase',
    letterSpacing: '0.08em'
  },
  dialogue: {
    margin: '16px 0 0',
    fontSize: 'clamp(22px, 3vw, 34px)',
    lineHeight: 1.28
  },
  primaryButton: {
    marginTop: 24,
    padding: '14px 22px',
    borderRadius: 999,
    border: '1px solid rgba(255,255,255,0.24)',
    background: 'linear-gradient(135deg, #8f63ff, #ff6b35)',
    color: 'white',
    fontWeight: 900,
    fontSize: 16,
    cursor: 'pointer'
  }
}
