export default function MainMenu({ hasSave, onNewGame, onContinue, onDeleteSave, onWorld }) {
  return (
    <main className="game-panel">
      <section style={{ maxWidth: 760 }}>
        <p className="eyebrow">Browser tactics RPG foundation</p>
        <h2>Build the playable vertical slice.</h2>
        <p>
          This shell turns the prototype into a campaign loop: Main Menu, World Map, Town,
          Battle, Results, Character Sheet, Job Tree, and local saves.
        </p>
        <div className="button-row">
          <button onClick={onNewGame}>New Game</button>
          <button onClick={onContinue} disabled={!hasSave}>Continue</button>
          <button onClick={onWorld}>World Map</button>
          <button onClick={onDeleteSave}>Delete Save</button>
        </div>
      </section>
    </main>
  )
}
