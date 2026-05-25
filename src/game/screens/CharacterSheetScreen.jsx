import { useState } from 'react'
import { JOBS, getJobLevelFromJp } from '../data/progression.js'

export default function CharacterSheetScreen({ gameState, setGameState, setScreen }) {
  const [expandedChar, setExpandedChar] = useState(null)
  const characters = Object.values(gameState.roster ?? {})

  const handleJobSwitch = (characterId, newJobId) => {
    setGameState(g => ({
      ...g,
      roster: {
        ...g.roster,
        [characterId]: {
          ...g.roster[characterId],
          currentJobId: newJobId,
        }
      }
    }))
  }

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Roster management</p>
          <h2>Character Sheets</h2>
          <p>Review stats, switch jobs, and track progression for your party.</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => setScreen('jobTree')}>Job Tree</button>
          <button onClick={() => setScreen('town')}>Back to Hub</button>
        </div>
      </div>

      <div className="card-grid">
        {characters.map((character) => {
          const unit = gameState.party.find((partyUnit) => partyUnit.id === character.id)
          const currentJob = JOBS[character.currentJobId]
          const unlockedJobs = (character.unlockedJobs ?? []).map(id => JOBS[id]).filter(Boolean)
          const isExpanded = expandedChar === character.id

          return (
            <article key={character.id} className="content-card" style={s.characterCard}>
              <div style={s.cardHeader}>
                <div>
                  <p className="eyebrow" style={{ color: '#c9a756' }}>{currentJob?.name ?? 'Unknown Job'}</p>
                  <h3 style={s.characterName}>{character.name}</h3>
                  <p style={s.characterLevel}>Level {character.level} · {character.xp} XP</p>
                </div>
                <button
                  onClick={() => setExpandedChar(isExpanded ? null : character.id)}
                  style={s.expandBtn}
                >
                  {isExpanded ? '▼' : '▶'}
                </button>
              </div>

              {/* Stats Grid */}
              <div style={s.statsGrid}>
                <div style={s.statItem}>
                  <span style={s.statLabel}>HP</span>
                  <span style={s.statValue}>{unit?.hp ?? 'n/a'}</span>
                </div>
                <div style={s.statItem}>
                  <span style={s.statLabel}>MP</span>
                  <span style={s.statValue}>{unit?.mp ?? 'n/a'}</span>
                </div>
                <div style={s.statItem}>
                  <span style={s.statLabel}>Temper</span>
                  <span style={s.statValue}>{unit?.temper ?? 'n/a'}</span>
                </div>
                <div style={s.statItem}>
                  <span style={s.statLabel}>Ether</span>
                  <span style={s.statValue}>{unit?.ether ?? 'n/a'}</span>
                </div>
              </div>

              {/* Job Progression */}
              <div style={s.jobProgression}>
                <h4 style={s.sectionTitle}>Current Job Progress</h4>
                <div style={s.progressBar}>
                  {(() => {
                    const jp = character.jobJp?.[character.currentJobId] ?? 0
                    const level = getJobLevelFromJp(jp)
                    const nextLevelJp = (level + 1) * 100
                    const progress = (jp % 100) / 100
                    return (
                      <>
                        <div
                          style={{
                            ...s.progressFill,
                            width: `${progress * 100}%`,
                          }}
                        />
                        <span style={s.progressText}>Lv. {level} · {jp} JP</span>
                      </>
                    )
                  })()}
                </div>
              </div>

              {/* Expandable Details */}
              {isExpanded && (
                <div style={s.expandedContent}>
                  {/* All Job Progression */}
                  <div style={s.detailSection}>
                    <h4 style={s.sectionTitle}>All Job Progression</h4>
                    <ul style={s.jobList}>
                      {Object.entries(character.jobJp ?? {})
                        .sort((a, b) => (b[1] ?? 0) - (a[1] ?? 0))
                        .map(([jobId, jp]) => {
                          const job = JOBS[jobId]
                          const level = getJobLevelFromJp(jp)
                          return (
                            <li key={jobId} style={s.jobListItem}>
                              <span style={s.jobName}>{job?.name ?? jobId}</span>
                              <span style={s.jobMeta}>Lv. {level} · {jp} JP</span>
                            </li>
                          )
                        })}
                    </ul>
                  </div>

                  {/* Unlocked Jobs */}
                  {unlockedJobs.length > 0 && (
                    <div style={s.detailSection}>
                      <h4 style={s.sectionTitle}>Available Jobs ({unlockedJobs.length})</h4>
                      <div style={s.jobButtons}>
                        {unlockedJobs.map((job) => (
                          <button
                            key={job.id}
                            onClick={() => handleJobSwitch(character.id, job.id)}
                            style={{
                              ...s.jobButton,
                              ...(character.currentJobId === job.id ? s.jobButtonActive : {})
                            }}
                          >
                            {job.name}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Job Details */}
                  {currentJob && (
                    <div style={s.detailSection}>
                      <h4 style={s.sectionTitle}>Active Job Details</h4>
                      <div style={s.jobDetails}>
                        <div>
                          <strong>Role:</strong> {currentJob.role}
                        </div>
                        <div>
                          <strong>Passive:</strong> {currentJob.passive}
                        </div>
                        <div>
                          <strong>Reaction:</strong> {currentJob.reaction}
                        </div>
                        {currentJob.abilities && currentJob.abilities.length > 0 && (
                          <div>
                            <strong>Abilities:</strong>
                            <ul style={{ margin: '4px 0 0 16px', paddingLeft: 0 }}>
                              {currentJob.abilities.map((ability, idx) => (
                                <li key={idx} style={{ fontSize: 13 }}>{ability}</li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </article>
          )
        })}
      </div>
    </main>
  )
}

const s = {
  characterCard: {
    transition: 'all 150ms ease',
  },
  cardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
    paddingBottom: 12,
    borderBottom: '1px solid rgba(255,255,255,.14)',
  },
  characterName: {
    margin: '4px 0 4px',
    fontSize: 20,
  },
  characterLevel: {
    fontSize: 13,
    color: 'rgba(247,240,223,.68)',
    margin: 0,
  },
  expandBtn: {
    background: 'transparent',
    border: 'none',
    color: '#c9a756',
    fontSize: 16,
    cursor: 'pointer',
    padding: 0,
    width: 24,
    height: 24,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'transform 150ms ease',
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 8,
    marginBottom: 16,
  },
  statItem: {
    display: 'flex',
    flexDirection: 'column',
    padding: '8px 10px',
    background: 'rgba(255,255,255,.04)',
    borderRadius: 6,
    border: '1px solid rgba(255,255,255,.1)',
  },
  statLabel: {
    fontSize: 10,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.08em',
    marginBottom: 2,
  },
  statValue: {
    fontSize: 14,
    fontWeight: 700,
    color: '#f7f0df',
  },
  jobProgression: {
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: 900,
    color: '#c9a756',
    textTransform: 'uppercase',
    letterSpacing: '.12em',
    margin: '0 0 8px',
  },
  progressBar: {
    position: 'relative',
    height: 24,
    background: 'rgba(0,0,0,.3)',
    borderRadius: 6,
    overflow: 'hidden',
    display: 'flex',
    alignItems: 'center',
  },
  progressFill: {
    position: 'absolute',
    height: '100%',
    background: 'rgba(201,167,86,.5)',
    transition: 'width 150ms ease',
  },
  progressText: {
    position: 'relative',
    fontSize: 11,
    fontWeight: 700,
    color: '#f7f0df',
    zIndex: 1,
    marginLeft: 8,
  },
  expandedContent: {
    paddingTop: 16,
    borderTop: '1px solid rgba(255,255,255,.14)',
    marginTop: 16,
  },
  detailSection: {
    marginBottom: 12,
  },
  jobList: {
    margin: 0,
    padding: 0,
    display: 'flex',
    flexDirection: 'column',
    gap: 6,
    listStyle: 'none',
  },
  jobListItem: {
    display: 'flex',
    justifyContent: 'space-between',
    fontSize: 13,
    padding: '6px 0',
  },
  jobName: {
    fontWeight: 600,
    color: '#f7f0df',
  },
  jobMeta: {
    fontSize: 11,
    color: 'rgba(247,240,223,.6)',
  },
  jobButtons: {
    display: 'flex',
    gap: 6,
    flexWrap: 'wrap',
  },
  jobButton: {
    padding: '8px 12px',
    borderRadius: 6,
    border: '1px solid rgba(255,255,255,.18)',
    background: 'rgba(255,255,255,.06)',
    color: '#f7f0df',
    fontSize: 12,
    fontWeight: 600,
    cursor: 'pointer',
    transition: 'all 150ms ease',
  },
  jobButtonActive: {
    borderColor: '#c9a756',
    background: 'rgba(201,167,86,.25)',
    color: '#c9a756',
  },
  jobDetails: {
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
    fontSize: 13,
    lineHeight: 1.5,
  },
}
