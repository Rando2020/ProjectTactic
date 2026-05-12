import { useMemo, useState } from 'react'
import { PARTY_ROSTER } from '../../game/data/roster.js'
import {
  ARMOR_SYSTEMS,
  JOBS,
  getAscendedJobs,
  getJobProgress,
  getJobRequirementSummary,
  getJobUnlockPreview,
  getUnlockedJobs,
  getXpForNextLevel,
} from '../../game/data/progression.js'
import temperIcon from '../../assets/ui/temper-icon.svg'
import magicArmorIcon from '../../assets/ui/magic-armor-icon.svg'
import jobSeal from '../../assets/ui/job-seal.svg'
import ascendedSeal from '../../assets/ui/ascended-seal.svg'
import './character-compendium.css'

const JOB_ORDER = [
  'warder', 'arcanist', 'resonant', 'luminary', 'skywarden', 'chronist', 'oathbound', 'voidcaller', 'nullResonant',
  'nullBreaker', 'etherweaver', 'primalBinder', 'seraph', 'drakeAscendant', 'timeSovereign', 'aegisVow', 'abyssalMagister', 'eclipseHarbinger',
]

function clampPercent(value, max) {
  if (!max) return 0
  return Math.max(0, Math.min(100, Math.round((value / max) * 100)))
}

function CharacterPortrait({ name }) {
  const initials = name.split(' ').map(part => part[0]).join('').slice(0, 2).toUpperCase()
  return (
    <div className="vc-portrait" aria-hidden="true">
      <div className="vc-portrait-ring" />
      <div className="vc-portrait-core">{initials}</div>
    </div>
  )
}

function StatusPill({ tone = 'neutral', children }) {
  return <span className={`vc-pill vc-pill-${tone}`}>{children}</span>
}

function Meter({ label, value, max, colorClass, icon, subtitle }) {
  const pct = clampPercent(value, max)
  return (
    <div className="vc-meter-card">
      <div className="vc-meter-head">
        <div className="vc-meter-title-wrap">
          <img src={icon} alt="" className="vc-meter-icon" />
          <div>
            <div className="vc-meter-title">{label}</div>
            <div className="vc-meter-subtitle">{subtitle}</div>
          </div>
        </div>
        <div className="vc-meter-value">{value} / {max}</div>
      </div>
      <div className="vc-meter-track">
        <div className={`vc-meter-fill ${colorClass}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  )
}

function StatGrid({ character }) {
  const stats = [
    ['HP', character.hp], ['MP', character.mp], ['STR', character.strength], ['MND', character.mind], ['SPD', character.speed],
    ['BRV', character.bravery], ['FTH', character.faith], ['CT', character.ct], ['LIMIT', `${character.limitGauge}%`], ['RESONANCE', `${character.resonance}%`],
  ]
  return (
    <div className="vc-stat-grid">
      {stats.map(([label, value]) => (
        <div className="vc-stat-card" key={label}>
          <div className="vc-stat-label">{label}</div>
          <div className="vc-stat-value">{value}</div>
        </div>
      ))}
    </div>
  )
}

function JobProgressCard({ character, jobId }) {
  const job = JOBS[jobId]
  const progress = getJobProgress(character, jobId)
  const xpToNext = getXpForNextLevel(character.xp)
  return (
    <div className="vc-panel">
      <div className="vc-panel-title-row">
        <h3>Progression</h3>
        <StatusPill tone="gold">{job?.name}</StatusPill>
      </div>
      <div className="vc-progress-stack">
        <div className="vc-progress-item">
          <div className="vc-progress-label">Character Lv. {character.level}<span>{xpToNext} XP to next level</span></div>
          <div className="vc-progress-bar"><div className="vc-progress-fill vc-progress-fill-blue" style={{ width: '74%' }} /></div>
        </div>
        <div className="vc-progress-item">
          <div className="vc-progress-label">{progress.jobName} Lv. {progress.level} · {progress.title}<span>{progress.jp} JP · {progress.jpToNextLevel} JP to next</span></div>
          <div className="vc-progress-bar"><div className="vc-progress-fill vc-progress-fill-gold" style={{ width: '68%' }} /></div>
        </div>
      </div>
      <div className="vc-inline-note"><strong>Current unlock tier:</strong> {progress.unlocksAtCurrentLevel?.length ? progress.unlocksAtCurrentLevel.join(' · ') : 'No bonus unlock text'}</div>
    </div>
  )
}

function JobBoard({ character, selectedJobId, onSelectJob }) {
  const unlockedJobs = new Set(getUnlockedJobs(character))
  const ascendedJobs = new Set(getAscendedJobs(character))
  return (
    <div className="vc-panel">
      <div className="vc-panel-title-row"><h3>Job Board</h3><StatusPill tone="neutral">{unlockedJobs.size} unlocked</StatusPill></div>
      <div className="vc-job-grid">
        {JOB_ORDER.map(jobId => {
          const job = JOBS[jobId]
          if (!job) return null
          const isUnlocked = unlockedJobs.has(jobId)
          const isAscended = job.tier === 'ascended'
          const isEquipped = character.currentJobId === jobId
          const progress = getJobProgress(character, jobId)
          return (
            <button key={jobId} className={`vc-job-card ${selectedJobId === jobId ? 'is-selected' : ''} ${isUnlocked ? 'is-unlocked' : 'is-locked'}`} onClick={() => onSelectJob(jobId)} type="button">
              <div className="vc-job-top">
                <img src={isAscended ? ascendedSeal : jobSeal} alt="" className="vc-job-seal" />
                <div className="vc-job-copy"><div className="vc-job-name">{job.name}</div><div className="vc-job-role">{job.archetype}</div></div>
              </div>
              <div className="vc-job-meta"><span>Lv. {progress.level}</span><span>{progress.jp} JP</span></div>
              <div className="vc-job-status-row">
                {isEquipped && <StatusPill tone="blue">Equipped</StatusPill>}
                {isAscended && <StatusPill tone="purple">Ascended</StatusPill>}
                {!isEquipped && isUnlocked && !isAscended && <StatusPill tone="green">Ready</StatusPill>}
                {!isUnlocked && <StatusPill tone="red">Locked</StatusPill>}
                {ascendedJobs.has(jobId) && <StatusPill tone="gold">Unlocked</StatusPill>}
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}

function RequirementBlock({ summary }) {
  if (!summary) return null
  return (
    <div className="vc-panel">
      <div className="vc-panel-title-row"><h3>{summary.jobName}</h3><StatusPill tone={summary.canUnlock ? 'green' : 'red'}>{summary.canUnlock ? 'Ready to Unlock' : 'Locked'}</StatusPill></div>
      <div className="vc-detail-copy"><div><strong>Tier:</strong> {summary.tier}</div><div><strong>Character Level Required:</strong> {summary.requiredCharacterLevel}</div></div>
      <div className="vc-requirements-list">
        {summary.requiredJobLevels.length ? summary.requiredJobLevels.map(req => {
          const met = req.currentLevel >= req.requiredLevel
          return (
            <div className={`vc-req-row ${met ? 'met' : 'missing'}`} key={req.jobId}>
              <div className="vc-req-main"><span className="vc-req-job">{req.jobName}</span><span>Lv. {req.currentLevel} / {req.requiredLevel}</span></div>
              <div className="vc-req-sub">{met ? 'Requirement met' : `${req.jpToRequiredLevel} JP still needed`}</div>
            </div>
          )
        }) : <div className="vc-inline-note">No related-job requirements.</div>}
      </div>
      {!!summary.requiredFlags?.length && <div className="vc-inline-note"><strong>Story flags:</strong> {summary.requiredFlags.join(', ')}</div>}
    </div>
  )
}

function UnlockPreview({ character, currentJobId }) {
  const preview = getJobUnlockPreview(character, currentJobId)
  return (
    <div className="vc-panel">
      <div className="vc-panel-title-row"><h3>Unlock Preview</h3><StatusPill tone="neutral">Training path</StatusPill></div>
      {preview.length ? <div className="vc-preview-stack">{preview.map(item => (
        <div className="vc-preview-card" key={item.unlocksJobId}>
          <div className="vc-preview-title"><span>{item.unlocksJobName}</span><StatusPill tone={item.isRequirementMet ? 'green' : 'red'}>requires {item.requiredLevel}</StatusPill></div>
          <div className="vc-preview-sub">Needs {JOBS[currentJobId]?.name} Lv. {item.requiredLevel} · Character Lv. {item.characterLevel}</div>
        </div>
      ))}</div> : <div className="vc-inline-note">No downstream job unlocks are currently tied to this job.</div>}
    </div>
  )
}

export default function CharacterCompendium() {
  const [selectedCharacterId, setSelectedCharacterId] = useState(PARTY_ROSTER[0].id)
  const [selectedJobId, setSelectedJobId] = useState(PARTY_ROSTER[0].currentJobId)
  const character = useMemo(() => PARTY_ROSTER.find(unit => unit.id === selectedCharacterId) ?? PARTY_ROSTER[0], [selectedCharacterId])
  const requirementSummary = useMemo(() => getJobRequirementSummary(character, selectedJobId), [character, selectedJobId])
  const unlockedJobs = getUnlockedJobs(character)
  const ascendedJobs = getAscendedJobs(character)

  return (
    <div className="vc-shell">
      <aside className="vc-sidebar">
        <div className="vc-sidebar-head"><div className="vc-kicker">Vaelthar Codex</div><h2>Character Compendium</h2><p>Track levels, Temper, Ether, jobs, and ascended paths.</p></div>
        <div className="vc-roster-list">
          {PARTY_ROSTER.map(unit => (
            <button key={unit.id} type="button" className={`vc-roster-button ${unit.id === character.id ? 'is-active' : ''}`} onClick={() => { setSelectedCharacterId(unit.id); setSelectedJobId(unit.currentJobId) }}>
              <CharacterPortrait name={unit.name} />
              <div className="vc-roster-copy"><div className="vc-roster-name">{unit.name}</div><div className="vc-roster-role">{unit.storyRole}</div><div className="vc-roster-meta">Lv. {unit.level} · {JOBS[unit.currentJobId]?.name}</div></div>
            </button>
          ))}
        </div>
      </aside>
      <main className="vc-main">
        <section className="vc-hero">
          <div className="vc-hero-left"><CharacterPortrait name={character.name} /><div><div className="vc-kicker">Active Unit</div><h1>{character.name}</h1><p>{character.storyRole}</p><div className="vc-tag-row"><StatusPill tone="blue">Lv. {character.level}</StatusPill><StatusPill tone="gold">{JOBS[character.currentJobId]?.name}</StatusPill><StatusPill tone="purple">{ascendedJobs.length} ascended-ready</StatusPill></div></div></div>
          <div className="vc-hero-right"><div className="vc-summary-chip"><strong>Unlocked Jobs</strong><span>{unlockedJobs.length}</span></div><div className="vc-summary-chip"><strong>Known Guardians</strong><span>{character.knownGuardians.length}</span></div><div className="vc-summary-chip"><strong>Limit</strong><span>{character.limitGauge}%</span></div></div>
        </section>
        <section className="vc-two-col">
          <div className="vc-left-stack">
            <Meter label={ARMOR_SYSTEMS.temper.label} value={character.temper} max={character.maxTemper} colorClass="vc-meter-temper" icon={temperIcon} subtitle="Physical armor and status resistance" />
            <Meter label={ARMOR_SYSTEMS.ether.label} value={character.ether} max={character.maxEther} colorClass="vc-meter-ether" icon={magicArmorIcon} subtitle="Magical armor and spell pressure resistance" />
            <StatGrid character={character} />
            <JobProgressCard character={character} jobId={character.currentJobId} />
          </div>
          <div className="vc-right-stack"><RequirementBlock summary={requirementSummary} /><UnlockPreview character={character} currentJobId={selectedJobId} /></div>
        </section>
        <JobBoard character={character} selectedJobId={selectedJobId} onSelectJob={setSelectedJobId} />
      </main>
    </div>
  )
}
