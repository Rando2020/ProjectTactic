import { useEffect, useMemo, useReducer } from 'react'
import TacticalGrid from '../components/TacticalGrid.jsx'
import CommandMenu from '../components/CommandMenu.jsx'
import TurnTimeline from '../components/TurnTimeline.jsx'
import DamagePreviewPanel from '../components/DamagePreviewPanel.jsx'
import { instantiatePlayerUnit } from '../data/units.js'
import { getObjectiveProgress, isObjectiveComplete, isPartyDefeated } from '../systems/objectives.js'
import { battleReducer, createBattleState } from '../systems/battle/battleReducer.js'

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
    hp: 120,
    mp: 35,
    temper: 80,
    ether: 60,
    stats: {
      hp: 120,
      mp: 35,
      move: 3,
      jump: 1,
      speed: spawn.unitId === 'storm_imp' ? 8 : 6,
      physical: spawn.unitId === 'null_drake' ? 48 : 34,
      magic: 24,
      temper: 80,
      ether: 60,
    },
    x: spawn.x,
    y: spawn.y,
    facing: spawn.facing || 'S',
    statuses: [],
    acted: false,
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

  const initialBattleState = useMemo(() => createBattleState({ map: activeMission, units: initialUnits }), [activeMission, initialUnits])
  const [battleState, dispatch] = useReducer(battleReducer, initialBattleState)

  const { units, activeUnitId, selectedUnitId, activeCommand, movementRange, damagePreview, battleLog, turnTimeline } = battleState
  const activeUnit = units.find((unit) => unit.id === activeUnitId && unit.hp > 0)
  const selectedUnit = units.find((unit) => unit.id === selectedUnitId && unit.hp > 0)
  const objectiveComplete = isObjectiveComplete(activeMission.objective, units)
  const partyDefeated = isPartyDefeated(units)
  const isPlayerTurn = activeUnit?.team === 'player'
  const disabledCommands = !isPlayerTurn
    ? ['move', 'attack', 'ability', 'item', 'wait']
    : [
        ...(activeUnit?.hasMoved ? ['move'] : []),
        ...(activeUnit?.hasActed ? ['attack', 'ability', 'item'] : []),
      ]

  useEffect(() => {
    dispatch({ type: 'reset', state: initialBattleState })
  }, [initialBattleState])

  useEffect(() => {
    if (activeUnit?.team === 'enemy' && !objectiveComplete && !partyDefeated) {
      const timeout = window.setTimeout(() => dispatch({ type: 'runEnemyTurn' }), 450)
      return () => window.clearTimeout(timeout)
    }
    return undefined
  }, [activeUnit?.id, activeUnit?.team, objectiveComplete, partyDefeated])

  function handleCommand(commandId) {
    dispatch({ type: 'selectCommand', commandId })
  }

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Tactical battle core</p>
          <h2>{activeMission.name}</h2>
          <p>{getObjectiveProgress(activeMission.objective, units)}</p>
          {activeUnit && <p className="muted">Active: <strong>{activeUnit.name}</strong> · {activeUnit.team} · CT {Math.round(activeUnit.ct ?? 0)}</p>}
          {partyDefeated && <p className="danger-text">Party defeated. Retreat and regroup.</p>}
        </div>
        <div className="button-row">
          <button onClick={() => setScreen('worldMap')}>Retreat</button>
          <button onClick={completeActiveMission} disabled={!objectiveComplete}>Claim Victory</button>
        </div>
      </div>

      <div className="battle-layout">
        <section className="content-card wide-card">
          <TacticalGrid
            map={activeMission}
            units={units}
            selectedUnitId={selectedUnitId}
            activeUnitId={activeUnitId}
            activeCommand={activeCommand}
            movementRange={movementRange}
            damagePreview={damagePreview}
            onSelectUnit={(unitId) => dispatch({ type: 'selectUnit', unitId })}
            onSelectMoveTile={(destination) => dispatch({ type: 'moveActiveUnit', destination })}
            onSelectAttackTarget={(targetId) => dispatch({ type: 'previewAttack', targetId })}
            showCoordinates={gameState.settings.showTileCoordinates}
          />
        </section>

        <aside className="battle-sidebar">
          <TurnTimeline entries={turnTimeline} activeUnitId={activeUnitId} />

          <CommandMenu
            selectedUnit={selectedUnit}
            activeCommand={activeCommand}
            disabledCommands={disabledCommands}
            onSelectCommand={handleCommand}
            onWait={() => dispatch({ type: 'selectCommand', commandId: 'wait' })}
          />

          <DamagePreviewPanel
            preview={damagePreview}
            onConfirm={() => dispatch({ type: 'confirmAttack' })}
            onCancel={() => dispatch({ type: 'cancelCommand' })}
          />

          <section className="content-card">
            <h3>Deployment</h3>
            <ul>
              {units.map((unit) => (
                <li key={unit.id} className={unit.hp <= 0 ? 'defeated-unit' : ''}>
                  <strong>{unit.name}</strong> [{unit.team}] HP {unit.hp} TMP {unit.temper} ETH {unit.ether} CT {Math.round(unit.ct ?? 0)} {unit.hasMoved ? '· moved' : ''} {unit.hasActed ? '· acted' : ''}
                </li>
              ))}
            </ul>
          </section>

          <section className="content-card">
            <h3>Battle Log</h3>
            <ul>
              {battleLog.map((entry, index) => <li key={`${entry}-${index}`}>{entry}</li>)}
            </ul>
          </section>
        </aside>
      </div>
    </main>
  )
}
