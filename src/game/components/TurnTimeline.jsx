export default function TurnTimeline({ entries = [], activeUnitId }) {
  return (
    <section className="content-card turn-timeline-card">
      <p className="eyebrow">CT Timeline</p>
      <h3>Upcoming Turns</h3>
      {entries.length === 0 ? (
        <p className="muted">CT is charging.</p>
      ) : (
        <ol className="turn-timeline">
          {entries.map((entry, index) => (
            <li key={`${entry.id}-${index}`} className={entry.id === activeUnitId ? 'is-active-turn' : ''}>
              <span className={`timeline-token ${entry.team}`}>{entry.team === 'player' ? '◆' : '◇'}</span>
              <span>
                <strong>{entry.name}</strong>
                <small>{entry.team} · CT {Math.round(entry.ct)} · SPD {entry.speed}</small>
              </span>
            </li>
          ))}
        </ol>
      )}
    </section>
  )
}
