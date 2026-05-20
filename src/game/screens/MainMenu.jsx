export default function MainMenu({ hasSave, onNewGame, onContinue, onDeleteSave, onWorld }) {
  return (
    <main className="game-panel">
      <section style={{ maxWidth: 760 }}>
        <p className="eyebrow">Browser tactics RPG foundation</p>
        <h2>Build the playable vertical slice.</h2>
        <p>
          Start from the hub, choose a stage route, descend ten floors, then bank the spoils or return after defeat.
        </p>
        <div className="button-row">
          <button onClick={onNewGame}>New Game</button>
          <button onClick={onContinue} disabled={!hasSave}>Continue</button>
          <button onClick={onWorld}>Stage Select</button>
          <button onClick={onDeleteSave}>Delete Save</button>
        </div>
      </section>
    </main>
  )
}
