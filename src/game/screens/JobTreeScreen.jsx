import { JOBS, getLockedJobRequirements, getJobLevelFromJp } from '../data/progression.js'

function requirementLabel(req) {
  if (req.type === 'characterLevel') return `Character Lv. ${req.current}/${req.required}`
  if (req.type === 'jobLevel') return `${JOBS[req.jobId]?.name ?? req.jobId} Lv. ${req.current}/${req.required}`
  if (req.type === 'flag') return `Story flag: ${req.flag}`
  return 'Unknown requirement'
}

export default function JobTreeScreen({ gameState, setScreen }) {
  const characters = Object.values(gameState.roster ?? {})
  const selectedCharacter = characters[0]
  const jobs = Object.values(JOBS)

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Class progression</p>
          <h2>Job Tree</h2>
          <p>Previewing unlock logic for {selectedCharacter?.name ?? 'party'}.</p>
        </div>
        <button onClick={() => setScreen('characterSheet')}>Character Sheets</button>
      </div>

      <div className="card-grid job-grid">
        {jobs.map((job) => {
          const unlocked = selectedCharacter?.unlockedJobs?.includes(job.id)
          const lockedRequirements = selectedCharacter ? getLockedJobRequirements(selectedCharacter, job.id) : []
          const jp = selectedCharacter?.jobJp?.[job.id] ?? 0
          const level = getJobLevelFromJp(jp)

          return (
            <article key={job.id} className={`content-card ${job.tier === 'ascended' ? 'ascended-card' : ''}`}>
              <p className="eyebrow">{job.tier} · {job.primaryArmor}</p>
              <h3>{job.name}</h3>
              <p>{job.archetype}</p>
              <p><strong>Status:</strong> {unlocked ? 'Unlocked' : 'Locked'}</p>
              <p><strong>Current:</strong> Lv. {level} · {jp} JP</p>
              {job.passive && <p><strong>Passive:</strong> {job.passive.description}</p>}
              {!unlocked && (
                <ul>
                  {lockedRequirements.map((req, index) => <li key={`${job.id}-${index}`}>{requirementLabel(req)}</li>)}
                </ul>
              )}
            </article>
          )
        })}
      </div>
    </main>
  )
}
