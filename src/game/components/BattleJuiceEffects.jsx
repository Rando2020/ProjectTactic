import { useState, useEffect } from 'react'

/**
 * BattleJuiceEffects provides visual feedback for combat actions:
 * - Hit pauses (brief pause on impact)
 * - Target flashes (white/red flash on hit)
 * - Camera nudges (subtle screenshake)
 * - Impact wobble (slight zoom/scale effect)
 *
 * This gives the battle system FFT/Disgaea-style polish.
 */

export const useHitPause = () => {
  const [isPaused, setIsPaused] = useState(false)

  const triggerPause = (duration = 80) => {
    setIsPaused(true)
    setTimeout(() => setIsPaused(false), duration)
  }

  return { isPaused, triggerPause }
}

export const useTargetFlash = () => {
  const [flashingUnitIds, setFlashingUnitIds] = useState(new Set())

  const triggerFlash = (unitIds, duration = 300) => {
    const idSet = Array.isArray(unitIds) ? new Set(unitIds) : new Set([unitIds])
    setFlashingUnitIds(idSet)
    setTimeout(() => setFlashingUnitIds(new Set()), duration)
  }

  return { flashingUnitIds, triggerFlash }
}

export const useCameraShake = () => {
  const [shake, setShake] = useState({ x: 0, y: 0 })

  const triggerShake = (intensity = 4, duration = 150) => {
    const shakes = []
    const steps = Math.ceil(duration / 30)

    for (let i = 0; i < steps; i++) {
      const progress = i / steps
      const damping = 1 - progress
      const offsetX = (Math.random() - 0.5) * intensity * damping
      const offsetY = (Math.random() - 0.5) * intensity * damping

      shakes.push(
        new Promise(resolve => {
          setTimeout(() => {
            setShake({ x: offsetX, y: offsetY })
            resolve()
          }, i * 30)
        })
      )
    }

    Promise.all(shakes).then(() => setShake({ x: 0, y: 0 }))
  }

  return { shake, triggerShake }
}

export const useImpactWobble = () => {
  const [wobble, setWobble] = useState({ scale: 1, angle: 0 })

  const triggerWobble = (targetUnitId, duration = 200) => {
    const startTime = performance.now()

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // Quick compress then expand bounce
      const curve = Math.sin(progress * Math.PI * 2.5) * (1 - progress)
      const scale = 1 + curve * 0.15
      const angle = curve * 3

      setWobble({ scale, angle })

      if (progress < 1) {
        requestAnimationFrame(animate)
      } else {
        setWobble({ scale: 1, angle: 0 })
      }
    }

    requestAnimationFrame(animate)
  }

  return { wobble, triggerWobble }
}

/**
 * Higher-level hook that triggers all effects together for a hit
 */
export const useHitEffect = () => {
  const hitPause = useHitPause()
  const targetFlash = useTargetFlash()
  const cameraShake = useCameraShake()
  const impactWobble = useImpactWobble()

  const triggerHit = ({
    targetUnitIds = [],
    intensity = 'normal',
    pauseDuration = 80,
    flashDuration = 300,
    shakeDuration = 150,
  } = {}) => {
    // Intensity presets
    const intensityMap = {
      light: { shake: 2, wobble: 0.1 },
      normal: { shake: 4, wobble: 0.15 },
      heavy: { shake: 6, wobble: 0.2 },
      critical: { shake: 8, wobble: 0.25 },
    }

    const preset = intensityMap[intensity] || intensityMap.normal

    // Trigger pause first (time freeze effect)
    hitPause.triggerPause(pauseDuration)

    // Flash target
    targetFlash.triggerFlash(targetUnitIds, flashDuration)

    // Camera shake
    cameraShake.triggerShake(preset.shake, shakeDuration)

    // Impact wobble (per target)
    Array.isArray(targetUnitIds) ? targetUnitIds : [targetUnitIds].forEach(id => {
      impactWobble.triggerWobble(id, shakeDuration)
    })
  }

  return {
    triggerHit,
    isPaused: hitPause.isPaused,
    flashingUnitIds: targetFlash.flashingUnitIds,
    cameraShake: cameraShake.shake,
    wobbleMap: new Map(), // Per-unit wobbles could be tracked here if needed
  }
}

/**
 * Component wrapper for camera shake effect
 */
export function BattleShakeCam({ shake, children }) {
  return (
    <div
      style={{
        transform: `translate(${shake.x}px, ${shake.y}px)`,
        transition: 'transform 30ms linear',
      }}
    >
      {children}
    </div>
  )
}

/**
 * Wrapper to apply visual hit effects to a unit
 */
export function HitEffectUnit({ unitId, isFlashing, wobble, children }) {
  const flashOpacity = isFlashing ? 0.9 : 1
  const flashFilter = isFlashing
    ? 'drop-shadow(0 0 6px rgba(255,255,150,.6)) brightness(1.3)'
    : 'none'

  return (
    <div
      style={{
        filter: flashFilter,
        transform: `scale(${wobble?.scale || 1}) rotate(${wobble?.angle || 0}deg)`,
        transition: 'filter 30ms ease, transform 30ms ease',
        opacity: flashOpacity,
      }}
    >
      {children}
    </div>
  )
}
