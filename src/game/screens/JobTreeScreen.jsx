import { useState } from 'react'
import { JOBS, getLockedJobRequirements, getJobLevelFromJp } from '../data/progression.js'

function requirementLabel(req) {
  if (req.type === 'characterLevel') return `Character Lv. ${req.current}/${req.required}`
  if (req.type === 'jobLevel') return `${JOBS[req.jobId]?.name ?? req.jobId} Lv. ${req.current}/${req.required}`
  if (req.type === 'flag') return `Story flag: ${req.flag}`
  return 'Unknown requirement'
}

function growthChart(growth) {
  const stats = [
    { label: 'HP', key: 'hp', color: '#2d9934' },
    { label: 'MP', key: 'mp', color: '#4a86e8' },
    { label: 'Temper', key: 'temper', color: '#f5b93d' },
    { label: 'Ether', key: 'ether', color: '#9f5edb' }
  ]

  const valueMap = { 'Low': 1, 'Medium': 2, 'High': 3, 'Very High': 4 }

  return (
    <div style={s.growthGrid}>
      {stats.map(stat => (
        <div key={stat.key} style={s.growthItem}>
          <div style={{ ...s.growthBar, backgroundColor: stat.color, width: `${(valueMap[growth[stat.key]] ?? 2) * 25}%` }} />
          <span style={s.growthLabel}>{stat.label}</span>
        </div>
      ))}
    </div>
  )
}

export default function JobTreeScreen({ gameState, setScreen }) {
  const [selectedCharacterId, setSelectedCharacterId] = useState(null)
  const [selectedJobId, setSelectedJobId] = useState(null)
  const [filterTier, setFilterTier] = useState('all')

  const characters = Object.values(gameState.roster ?? {})
  const selectedCharacter = selectedCharacterId
    ? characters.find(c => c.id === selectedCharacterId) ?? characters[0]
    : characters[0]

  const jobs = Object.values(JOBS)
  const baseTierJobs = jobs.filter(j => j.tier === 'Base')
  const advancedJobs = jobs.filter(j => j.tier === 'Advanced')
  const ascendedJobs = jobs.filter(j => j.tier === 'Ascended')

  const getDisplayedJobs = () => {
    if (filterTier === 'all') return jobs
    if (filterTier === 'base') return baseTierJobs
    if (filterTier === 'advanced') return advancedJobs
    if (filterTier === 'ascended') return ascendedJobs
    return jobs
  }

  const selectedJob = selectedJobId ? JOBS[selectedJobId] : null
  const displayedJobs = getDisplayedJobs()

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Class progression</p>
          <h2>Job Tree</h2>
          <p>Manage job progression for {selectedCharacter?.name ?? 'party'}.</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => setScreen('characterSheet')}>Character Sheets</button>
          <button onClick={() => setScreen('town')}>Back to Hub</button>
        </div>
      </div>

      {/* Character selector */}
      <div style={s.characterSelector}>
        <label style={{ marginRight: 12, fontWeight: 700 }}>Character:</label>
        <select
          value={selectedCharacterId || ''}
          onChange={(e) => setSelectedCharacterId(e.target.value)}
          style={s.selectInput}
        >
          {characters.map(char => (
            <option key={char.id} value={char.id}>{char.name}</option>
          ))}
        </select>

        <label style={{ marginLeft: 24, marginRight: 12, fontWeight: 700 }}>Filter:</label>
        <select
          value={filterTier}
          onChange={(e) => setFilterTier(e.target.value)}
          style={s.selectInput}
        >
          <option value="all">All Tiers</option>
          <option value="base">Base</option>
          <option value="advanced">Advanced</option>
          <option value="ascended">Ascended</option>
        </select>
      </div>

      {/* Main grid */}
      <div style={s.mainLayout}>
        {/* Job cards grid */}
        <div style={{ flex: 1 }}>
          <div className="card-grid job-grid">
            {displayedJobs.map((job) => {
              const unlocked = selectedCharacter?.unlockedJobs?.includes(job.id)
              const lockedRequirements = selectedCharacter ? getLockedJobRequirements(selectedCharacter, job.id) : []
              const jp = selectedCharacter?.jobJp?.[job.id] ?? 0
              const level = getJobLevelFromJp(jp)
              const isSelected = selectedJobId === job.id

              return (
                <article
                  key={job.id}
                  className={`content-card ${job.tier === 'Ascended' ? 'ascended-card' : ''}`}
                  onClick={() => setSelectedJobId(job.id)}
                  style={{
                    ...s.jobCard,
                    ...(isSelected ? s.jobCardSelected : {}),
                    cursor: 'pointer'
                  }}
                >
                  <p className="eyebrow">{job.tier} · {job.role}</p>
                  <h3>{job.name}</h3>

                  <div style={s.statusBadge}>
                    {unlocked ? (
                      <>
                        <span style={{ ...s.badge, background: '#2d9934' }}>UNLOCKED</span>
                        <span style={s.jpDisplay}>Lv.{level} · {jp}JP</span>
                      </>
                    ) : (
                      <span style={{ ...s.badge, background: '#c0392b' }}>LOCKED</span>
                    )}
                  </div>

                  {job.passive && <p><strong>Passive:</strong> {job.passive}</p>}
                  <p style={{ fontSize: 13, color: 'rgba(247,240,223,.6)' }}>{job.description}</p>
                </article>
              )
            })}
          </div>
        </div>

        {/* Detail panel */}
        {selectedJob && (
          <div style={s.detailPanel}>
            <div style={s.detailHeader}>
              <h2>{selectedJob.name}</h2>
              <button
                onClick={() => setSelectedJobId(null)}
                style={s.closeBtn}
              >✕</button>
            </div>

            <div style={s.detailContent}>
              <div style={s.detailSection}>
                <span style={s.sectionLabel}>ROLE</span>
                <p>{selectedJob.role}</p>
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>DESCRIPTION</span>
                <p>{selectedJob.description}</p>
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>GROWTH POTENTIAL</span>
                {growthChart(selectedJob.growth)}
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>ABILITIES</span>
                <ul style={s.abilityList}>
                  {selectedJob.abilities?.map((ability, idx) => (
                    <li key={idx}>{ability}</li>
                  ))}
                </ul>
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>REACTION</span>
                <p>{selectedJob.reaction}</p>
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>PASSIVE</span>
                <p>{selectedJob.passive}</p>
              </div>

              <div style={s.detailSection}>
                <span style={s.sectionLabel}>WEAPONS</span>
                <p>{selectedJob.weaponTypes?.join(', ')}</p>
              </div>

              {selectedJob.ascendsTo && (
                <div style={s.detailSection}>
                  <span style={s.sectionLabel}>ASCENDS TO</span>
                  <p style={{ color: '#c9a756' }}>{JOBS[selectedJob.ascendsTo]?.name ?? selectedJob.ascendsTo}</p>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </main>
  )
}

const s = {
  characterSelector: {
    display: 'flex',
    alignItems: 'center',
    padding: '16px 0',
    borderBottom: '1px solid rgba(255,255,255,.14)',
    marginBottom: 20,
    gap: 12,
  },
  selectInput: {
    padding: '8px 12px',
    borderRadius: 8,
    border: '1px solid rgba(255,255,255,.18)',
    background: 'rgba(255,255,255,.06)',
    color: '#f7f0df',
    fontWeight: 600,
    fontSize: 13,
    cursor: 'pointer',
  },
  mainLayout: {
    display: 'grid',
    gridTemplateColumns: '1fr 320px',
    gap: 24,
    alignItems: 'start',
  },
  jobCard: {
    transition: 'all 150ms ease',
    border: '1px solid rgba(255,255,255,.14)',
  },
  jobCardSelected: {
    borderColor: '#c9a756',
    background: 'rgba(201,167,86,.15)',
    boxShadow: '0 0 20px rgba(201,167,86,.25)',
  },
  statusBadge: {
    display: 'flex',
    gap: 8,
    margin: '12px 0',
    alignItems: 'center',
  },
  badge: {
    padding: '4px 8px',
    borderRadius: 4,
    fontSize: 10,
    fontWeight: 900,
    color: '#f7f0df',
    letterSpacing: '.08em',
  },
  jpDisplay: {
    fontSize: 12,
    color: '#c9a756',
    fontWeight: 700,
  },
  detailPanel: {
    background: 'rgba(10,14,24,.95)',
    border: '1px solid rgba(255,255,255,.14)',
    borderRadius: 12,
    padding: 16,
    maxHeight: 'calc(100vh - 320px)',
    overflowY: 'auto',
    position: 'sticky',
    top: 0,
  },
  detailHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
    paddingBottom: 12,
    borderBottom: '1px solid rgba(255,255,255,.14)',
  },
  closeBtn: {
    background: 'transparent',
    border: 'none',
    color: '#f7f0df',
    fontSize: 20,
    cursor: 'pointer',
    padding: 0,
    width: 24,
    height: 24,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  detailContent: {
    display: 'flex',
    flexDirection: 'column',
    gap: 16,
  },
  detailSection: {
    display: 'flex',
    flexDirection: 'column',
    gap: 6,
  },
  sectionLabel: {
    fontSize: 10,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.12em',
  },
  growthGrid: {
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
  },
  growthItem: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  growthBar: {
    height: 6,
    borderRadius: 3,
    flex: 1,
    opacity: 0.7,
  },
  growthLabel: {
    fontSize: 12,
    color: 'rgba(247,240,223,.7)',
    minWidth: 50,
  },
  abilityList: {
    margin: 0,
    paddingLeft: 16,
    display: 'flex',
    flexDirection: 'column',
    gap: 4,
  },
}
