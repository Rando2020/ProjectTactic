import { ONBOARDING_STEPS } from '../data/onboarding.js'

export default function OnboardingOverlay({ stepIndex, onNext, onSkip }) {
  const step = ONBOARDING_STEPS[stepIndex] || ONBOARDING_STEPS[0]
  const isLast = stepIndex >= ONBOARDING_STEPS.length - 1

  return (
    <div role="dialog" aria-modal="true" aria-labelledby="onboarding-title" style={styles.backdrop}>
      <section className="v-card" style={styles.card}>
        <p className="v-eyebrow">New player guide</p>
        <h2 id="onboarding-title" style={{ margin: '8px 0 10px', fontSize: 34 }}>{step.title}</h2>
        <p className="v-copy" style={{ marginTop: 0 }}>{step.body}</p>
        <p className="v-pill">Step {stepIndex + 1} of {ONBOARDING_STEPS.length}</p>
        <div className="v-btn-row" style={{ marginTop: 20 }}>
          <button className="v-btn v-btn-primary" onClick={onNext}>{isLast ? 'Finish guide' : 'Next tip'}</button>
          <button className="v-btn" onClick={onSkip}>Skip</button>
        </div>
      </section>
    </div>
  )
}

const styles = {
  backdrop: {
    position: 'fixed',
    inset: 0,
    zIndex: 20,
    display: 'grid',
    placeItems: 'center',
    padding: 18,
    background: 'rgba(0,0,0,0.66)',
    backdropFilter: 'blur(10px)'
  },
  card: {
    maxWidth: 640,
    margin: 0
  }
}
