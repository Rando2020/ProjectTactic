import { useEffect, useMemo, useState } from 'react'
import TacticalGrid from '../components/TacticalGrid.jsx'
import CommandMenu from '../components/CommandMenu.jsx'
import { instantiatePlayerUnit } from '../data/units.js'
import { getAbility } from '../data/abilities.js'
import { buildGrid, getFacingAfterMove } from '../systems/grid.js'
import { chooseEnemyAction } from '../systems/aiController.js'
import { getObjectiveProgress, isObjectiveComplete, isPartyDefeated } from '../systems/objectives.js'

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
    move: 3,
    jump: 1,
    abilities: ['basic_attack'],
    x: spawn.x,
    y: spawn.y,
    facing: spawn.facing || 'S',
    statuses: [],
    acted: false,
  }
}

function applyDamage(unit, amount) {
  const armorBreak = Math.min(unit.temper ?? 0, Math.round(amount * 0.35))
  const hpDamage = Math.max(1, amount - Math.round(armorBreak * 0.25))

  return {
    ...unit,
    temper: Math.max(0, (unit.temper ?? 0) - armorBreak),
    hp: Math.max(0, unit.hp - hpDamage),
  }
}

export default function BattleScreen({ gameState, activeMission, completeActiveMission, setScreen }) {
  const initialUnits = useMemo(() => {
    const players = activeMission.playerSpawns
      .map((spawn) => instantiatePlayerUnit(spawn.unitId, spawn))
      .filter(Boolean)
      .map((unit) => ({ ...unit, acted: false }))
    const enemies = activeMission.enemySpawns.map(instantiateEnemy)
    return [...players, ...enemies]
  }, [activeMission])

  const grid = useMemo(() => buildGrid(activeMission), [activeMission])

  const [units, setUnits] = useState(initialUnits)
  const [selectedUnitId, setSelectedUnitId] = useState(null)
  const [activeCommand, setActiveCommand] = useState(null)
  const [battleLog, setBattleLog] = useState(['Battle started. Select a unit and choose a command.'])
  const [enemyPhase, setEnemyPhase] = useState(false)

  const selectedUnit = units.find((unit) => unit.id === selectedUnitId && unit.hp > 0)
  const objectiveComplete = isObjectiveComplete(activeMission.objective, units)
  const partyDefeated = isPartyDefeated(units)
  const disabledCommands = enemyPhase || selectedUnit?.team !== 'player' || selectedUnit?.acted
    ? ['move', 'attack', 'ability', 'item', 'wait']
    : []

  useEffect(() => {
    setUnits(initialUnits)
    setSelectedUnitId(null)
    setActiveCommand(null)
    setBattleLog(['Battle started. Select a unit and choose a command.'])
  }, [initialUnits])

  useEffect(() => {
    if (objectiveComplete) {
      setBattleLog((current) => ['Objective complete. Rewards ready.', ...current])
    }
  }, [objectiveComplete])

  // Transition to enemy phase when all living players have acted
  useEffect(() => {
    if (enemyPhase || objectiveComplete || partyDefeated) return
    const livingPlayers = units.filter((u) => u.team === 'player' && u.hp > 0)
    const livingEnemies = units.filter((u) => u.team === 'enemy' && u.hp > 0)
    if (livingPlayers.length > 0 && livingPlayers.every((u) => u.acted) && livingEnemies.length > 0) {
      setEnemyPhase(true)
      setBattleLog((current) => ['— Enemy phase —', ...current].slice(0, 8))
    }
  }, [units, enemyPhase, objectiveComplete, partyDefeated])

  // Process one enemy action per tick with a delay for readability
  useEffect(() => {
    if (!enemyPhase || objectiveComplete || partyDefeated) return

    const livingEnemies = units.filter((u) => u.team === 'enemy' && u.hp > 0 && !u.acted)

    if (livingEnemies.length === 0) {
      setUnits((current) => current.map((u) => ({ ...u, acted: false })))
      setEnemyPhase(false)
      setSelectedUnitId(null)
      setBattleLog((current) => ['— Player phase — Choose your next move.', ...current].slice(0, 8))
      return
    }

    const enemy = livingEnemies[0]
    const timer = setTimeout(() => {
      const action = chooseEnemyAction({ map: activeMission, grid, units, unit: enemy })

      if (action.type === 'move') {
        setUnits((current) => current.map((u) =>
          u.id === enemy.id
            ? { ...u, x: action.to.x, y: action.to.y, facing: getFacingAfterMove(u, action.to), acted: true }
            : u
        ))
        setBattleLog((current) => [`${enemy.name} advances to ${action.to.x},${action.to.y}.`, ...current].slice(0, 8))

      } else if (action.type === 'ability') {
        const ability = getAbility(action.abilityId)
        const damage = Math.max(10, Math.round(ability.power * (0.75 + Math.random() * 0.4)))
        setUnits((current) => current.map((u) => {
          if (u.id === action.targetUnitId) return applyDamage(u, damage)
          if (u.id === enemy.id) return { ...u, acted: true }
          return u
        }))
        const targetName = units.find((u) => u.id === action.targetUnitId)?.name ?? 'target'
        setBattleLog((current) => [`${enemy.name} used ${ability.name} on ${targetName} for ${damage} pressure.`, ...current].slice(0, 8))

      } else {
        setUnits((current) => current.map((u) => u.id === enemy.id ? { ...u, acted: true } : u))
        setBattleLog((current) => [`${enemy.name} holds position.`, ...current].slice(0, 8))
      }
    }, 700)

    return () => clearTimeout(timer)
  }, [enemyPhase, units, activeMission, grid, objectiveComplete, partyDefeated])

  function addLog(message) {
    setBattleLog((current) => [message, ...current].slice(0, 8))
  }

  function selectUnit(unitId) {
    const unit = units.find((candidate) => candidate.id === unitId)
    setSelectedUnitId(unitId)
    setActiveCommand(unit?.team === 'player' && !unit.acted ? 'move' : null)
  }

  function updateUnit(unitId, updater) {
    setUnits((current) => current.map((unit) => unit.id === unitId ? updater(unit) : unit))
  }

  function markActed(unitId) {
    updateUnit(unitId, (unit) => ({ ...unit, acted: true }))
    setActiveCommand(null)
  }

  function moveUnit(destination) {
    if (!selectedUnit || selectedUnit.team !== 'player' || selectedUnit.acted) return

    setUnits((current) => current.map((unit) => {
      if (unit.id !== selectedUnit.id) return unit
      return {
        ...unit,
        facing: getFacingAfterMove(unit, destination),
        x: destination.x,
        y: destination.y,
        acted: true,
      }
    }))
    addLog(`${selectedUnit.name} moved to ${destination.x},${destination.y}.`)
    setActiveCommand(null)
  }

  function attackTarget(targetId) {
    if (!selectedUnit || selectedUnit.team !== 'player' || selectedUnit.acted) return
    const target = units.find((unit) => unit.id === targetId)
    if (!target || target.team !== 'enemy') return

    const damage = Math.max(28, Math.round((selectedUnit.stats?.physical ?? 44) * 1.2))
    setUnits((current) => current.map((unit) => {
      if (unit.id === targetId) return applyDamage(unit, damage)
      if (unit.id === selectedUnit.id) return { ...unit, acted: true }
      return unit
    }))
    addLog(`${selectedUnit.name} attacked ${target.name} for ${damage} pressure.`)
    setActiveCommand(null)
  }

  function useItem() {
    if (!selectedUnit || selectedUnit.team !== 'player' || selectedUnit.acted) return
    updateUnit(selectedUnit.id, (unit) => ({
      ...unit,
      hp: Math.min(unit.stats?.hp ?? unit.hp, unit.hp + 120),
      acted: true,
    }))
    addLog(`${selectedUnit.name} used a Vitae Draught placeholder.`)
    setActiveCommand(null)
  }

  function useAbility() {
    if (!selectedUnit || selectedUnit.team !== 'player' || selectedUnit.acted) return
    addLog(`${selectedUnit.name} readies a job ability. Ability targeting is the next implementation layer.`)
    markActed(selectedUnit.id)
  }

  function waitUnit() {
    if (!selectedUnit || selectedUnit.team !== 'player' || selectedUnit.acted) return
    addLog(`${selectedUnit.name} waits and holds position.`)
    markActed(selectedUnit.id)
  }

  function handleCommand(commandId) {
    if (commandId === 'item') {
      useItem()
      return
    }
    if (commandId === 'ability') {
      useAbility()
      return
    }
    setActiveCommand(commandId)
  }

  return (
    <main className="game-panel">
      <div className="screen-header">
        <div>
          <p className="eyebrow">Tactical battle MVP</p>
          <h2>{activeMission.name}</h2>
          <p>{getObjectiveProgress(activeMission.objective, units)}</p>
          {enemyPhase && !objectiveComplete && <p className="eyebrow">Enemy phase — wait…</p>}
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
            activeCommand={activeCommand}
            onSelectUnit={selectUnit}
            onSelectMoveTile={moveUnit}
            onSelectAttackTarget={attackTarget}
            showCoordinates={gameState.settings.showTileCoordinates}
          />
        </section>

        <aside className="battle-sidebar">
          <CommandMenu
            selectedUnit={selectedUnit}
            activeCommand={activeCommand}
            disabledCommands={disabledCommands}
            onSelectCommand={handleCommand}
            onWait={waitUnit}
          />

          <section className="content-card">
            <h3>Deployment</h3>
            <ul>
              {units.map((unit) => (
                <li key={unit.id} className={unit.hp <= 0 ? 'defeated-unit' : ''}>
                  <strong>{unit.name}</strong> [{unit.team}] HP {unit.hp} TMP {unit.temper} ETH {unit.ether} {unit.acted ? '· acted' : ''}
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
