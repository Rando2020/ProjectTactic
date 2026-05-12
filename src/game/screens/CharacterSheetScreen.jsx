import { JOBS, getJobLevelFromJp } from '../data/progression.js'

export default function CharacterSheetScreen({ gameState, setScreen }) {
  const characters = Object.values(gameState.roster ?? {})

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Roster and armor</p>
          <h2>Character Sheets</h2>
        </div>
        <button onClick={() => setScreen('jobTree')}>Open Job Tree</button>
      </div>

      <div className="card-grid">
        {characters.map((character) => {
          const unit = gameState.party.find((partyUnit) => partyUnit.id === character.id)
          const currentJob = JOBS[character.currentJobId]

          return (
            <article key={character.id} className="content-card">
              <p className="eyebrow">{currentJob?.name ?? character.currentJobId}</p>
              <h3>{character.name}</h3>
              <p>Level {character.level} · XP {character.xp}</p>
              <div className="stat-grid">
                <span>HP {unit?.hp ?? 'n/a'}</span>
                <span>MP {unit?.mp ?? 'n/a'}</span>
                <span>TMP {unit?.temper ?? 'n/a'}</span>
                <span>ETH {unit?.ether ?? 'n/a'}</span>
              </div>
              <h4>Job JP</h4>
              <ul>
                {Object.entries(character.jobJp ?? {}).map(([jobId, jp]) => (
                  <li key={jobId}>{JOBS[jobId]?.name ?? jobId}: Lv. {getJobLevelFromJp(jp)} · {jp} JP</li>
                ))}
              </ul>
              <h4>Unlocked Jobs</h4>
              <p>{(character.unlockedJobs ?? []).map((jobId) => JOBS[jobId]?.name ?? jobId).join(', ')}</p>
            </article>
          )
        })}
      </div>
    </main>
  )
}
