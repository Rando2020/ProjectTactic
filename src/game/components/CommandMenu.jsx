const COMMANDS = [
  { id: 'move', label: 'Move', description: 'Reposition to an adjacent open tile.' },
  { id: 'attack', label: 'Attack', description: 'Strike an adjacent enemy.' },
  { id: 'ability', label: 'Ability', description: 'Placeholder for job abilities.' },
  { id: 'item', label: 'Item', description: 'Use a simple Vitae Draught from inventory.' },
  { id: 'wait', label: 'Wait', description: 'End this unit action for now.' },
]

export default function CommandMenu({ selectedUnit, activeCommand, onSelectCommand, onWait, disabledCommands = [] }) {
  if (!selectedUnit) {
    return (
      <section className="content-card">
        <h3>Command Menu</h3>
        <p className="muted">Select a player unit on the tactical grid to issue a command.</p>
      </section>
    )
  }

  return (
    <section className="content-card">
      <p className="eyebrow">Active Unit</p>
      <h3>{selectedUnit.name}</h3>
      <p className="muted">HP {selectedUnit.hp} · TMP {selectedUnit.temper} · ETH {selectedUnit.ether}</p>
      <div className="command-list">
        {COMMANDS.map((command) => {
          const disabled = disabledCommands.includes(command.id)
          const isActive = activeCommand === command.id
          return (
            <button
              key={command.id}
              type="button"
              className={`command-button ${isActive ? 'is-active' : ''}`}
              disabled={disabled}
              onClick={() => command.id === 'wait' ? onWait?.() : onSelectCommand(command.id)}
            >
              <strong>{command.label}</strong>
              <span>{command.description}</span>
            </button>
          )
        })}
      </div>
    </section>
  )
}
