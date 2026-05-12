export default function Toast({ message }) {
  if (!message) return null

  return (
    <div role="status" aria-live="polite" style={styles.toast}>
      {message}
    </div>
  )
}

const styles = {
  toast: {
    position: 'fixed',
    right: 18,
    bottom: 18,
    zIndex: 30,
    maxWidth: 360,
    padding: '14px 16px',
    borderRadius: 16,
    border: '1px solid rgba(255,255,255,0.16)',
    background: 'rgba(8, 10, 28, 0.96)',
    color: 'white',
    boxShadow: '0 18px 60px rgba(0,0,0,0.42)',
    fontWeight: 800
  }
}
