import { useMemo, useState } from 'react'
import TacticalGrid from '../components/TacticalGrid.jsx'
import { instantiatePlayerUnit } from '../data/units.js'
import { getFacingAfterMove } from '../systems/grid.js'

const ENEMY_NAMES = {
  null_drake: 'Null Drake',
  storm_imp: 'Storm Imp',
  fen_wraith: 'Fen Wraith',
}

function instantiateEnemy(spawn) {
  return {
    id: `${spawn.unitId}-${spawn.x}-${spawn.y}`,
    templateId: spawn.unitId,
    name: ENEMY_NAMES[spawn.unitId] || spawn.unitId,
    team: 'enemy',
    hp: 220,
    mp: 35,
    temper: 80,
    ether: 60,
    x: spawn.x,
    y: spawn.y,
    facing: spawn.facing || 'S',
    statuses: [],
  }
}

export default function BattleScreen({ gameState, activeMission, completeActiveMission, setScreen }) {
  const initialUnits = useMemo(() => {
    const players = activeMission.playerSpawns
      .map((spawn) => instantiatePlayerUnit(spawn.unitId, spawn))
      .filter(Boolean)
    const enemies = activeMission.enemySpawns.map(instantiateEnemy)
    return [...players, ...enemies]
  }, [activeMission])

  const [units, setUnits] = useState(initialUnits)

  function moveUnit(unitId, destination) {
    setUnits((current) => current.map((unit) => {
      if (unit.id !== unitId) return unit
      return {
        ...unit,
        facing: getFacingAfterMove(unit, destination),
        x: destination.x,
        y: destination.y,
      }
    }))
  }

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Tactical battle MVP</p>
          <h2>{activeMission.name}</h2>
          <p>{activeMission.objective.label}</p>
        </div>
        <div className="button-row">
          <button onClick={() => setScreen('worldMap')}>Retreat</button>
          <button onClick={completeActiveMission}>Debug Win Battle</button>
        </div>
      </div>

      <div className="battle-layout">
        <section className="content-card wide-card">
          <TacticalGrid
            map={activeMission}
            units={units}
            onMoveUnit={moveUnit}
            showCoordinates={gameState.settings.showTileCoordinates}
          />
        </section>

        <aside className="content-card">
          <h3>Deployment</h3>
          <ul>
            {units.map((unit) => (
              <li key={unit.id}>
                <strong>{unit.name}</strong> [{unit.team}] HP {unit.hp} TMP {unit.temper} ETH {unit.ether}
              </li>
            ))}
          </ul>
          <p className="muted">Next upgrade: movement range, attacks, action menu, CT timeline, and AI turns.</p>
        </aside>
      </div>
    </main>
  )
}
