import { useState } from 'react'
import { getBattleMap } from '../data/maps.js'
import { getCurrentNode } from '../systems/floorGenerator.js'
import { MYSTERY_EVENT_TYPES } from '../data/mysteryEvents.js'

const NODE_LABELS = {
  battle: 'Battle',
  elite_battle: 'Elite',
  boss: 'Boss',
  boon_pick: 'Guardian Boon',
  wanderer: 'Wanderer',
  mystery: 'Mystery',
  event: 'Event',
}

function nodeTitle(node, showMysteryDetails = false) {
  if (!node) return 'Unknown'
  if (node.mapId) return getBattleMap(node.mapId)?.name ?? NODE_LABELS[node.type] ?? node.type
  if (node.wanderer) return node.wanderer.name
  if (node.type === 'mystery') {
    if (showMysteryDetails && node.eventId) {
      const event = MYSTERY_EVENT_TYPES[node.eventId]
      return event?.name ?? '?'
    }
    return '?'
  }
  return NODE_LABELS[node.type] ?? node.type
}

function nodeTone(node, isCurrent) {
  if (node?.completed) return s.doneNode
  if (isCurrent) return s.currentNode
  if (node?.type === 'boss') return s.bossNode
  if (node?.type === 'elite_battle') return s.eliteNode
  if (node?.type === 'boon_pick') return s.boonNode
  if (node?.type === 'wanderer') return s.wandererNode
  if (node?.type === 'mystery') return s.mysteryNode
  return s.node
}

export default function RunMapScreen({ gameState, onStartRun, onEnterRunNode, setScreen }) {
  const run = gameState.activeRun
  const currentNode = run ? getCurrentNode(run) : null
  const activeBoons = run?.activeBoons ?? []
  const [showMysteryDebug, setShowMysteryDebug] = useState(true) // Toggle to show event names during testing

  if (!run) {
    return (
      <main style={s.panel}>
        <div style={s.header}>
          <div>
            <p style={s.eyebrow}>Roguelike run</p>
            <h2 style={s.title}>Guardian Path</h2>
            <p style={s.copy}>Start a 10-floor route with battles, wanderers, loot, and Guardian boon choices.</p>
          </div>
          <button style={s.primaryBtn} onClick={onStartRun}>Start Run</button>
        </div>
      </main>
    )
  }

  return (
    <main style={s.panel}>
      <div style={s.header}>
        <div>
          <p style={s.eyebrow}>Guardian Path</p>
          <h2 style={s.title}>{run.stageName ?? 'Guardian Path'} - Floor {run.currentFloor} of {run.totalFloors}</h2>
          <p style={s.copy}>{run.completed ? 'Run complete. Claim your route rewards and return to camp.' : `Current node: ${nodeTitle(currentNode)}`}</p>
        </div>
        <div style={s.actions}>
          {!run.completed && <button style={s.primaryBtn} onClick={onEnterRunNode}>Enter Node</button>}
          {run.completed && <button style={s.primaryBtn} onClick={() => setScreen('results')}>View Results</button>}
          <button style={{ ...s.primaryBtn, background: showMysteryDebug ? 'rgba(168,85,247,.3)' : 'rgba(201,167,86,.2)' }} onClick={() => setShowMysteryDebug(!showMysteryDebug)}>
            {showMysteryDebug ? 'Mystery Debug ON' : 'Mystery Debug OFF'}
          </button>
        </div>
      </div>

      <section style={s.summaryGrid}>
        <article style={s.statCard}>
          <span style={s.statLabel}>Run gold</span>
          <strong>{run.runGold ?? 0}</strong>
        </article>
        <article style={s.statCard}>
          <span style={s.statLabel}>Elites slain</span>
          <strong>{run.elitesSlain ?? 0}</strong>
        </article>
        <article style={s.statCard}>
          <span style={s.statLabel}>Deaths</span>
          <strong>{run.deaths ?? 0}</strong>
        </article>
      </section>

      <section style={s.map}>
        {run.plan.map((floor) => (
          <article key={floor.floor} style={s.floor}>
            <div style={s.floorLabel}>Floor {floor.floor}</div>
            <div style={s.nodeRow}>
              {floor.nodes.map((node, index) => {
                const isCurrent = floor.floor === run.currentFloor && index === run.currentNodeIndex && !run.completed
                return (
                  <div key={`${floor.floor}-${index}`} style={nodeTone(node, isCurrent)}>
                    <span style={s.nodeType}>{NODE_LABELS[node.type] ?? node.type}</span>
                    <strong style={s.nodeName}>{nodeTitle(node, showMysteryDebug)}</strong>
                    {node.completed && <span style={s.nodeHint}>Complete</span>}
                    {isCurrent && <span style={s.nodeHint}>Ready</span>}
                  </div>
                )
              })}
            </div>
          </article>
        ))}
      </section>

      <section style={s.boonPanel}>
        <div>
          <p style={s.eyebrow}>Active boons</p>
          <h3 style={s.sectionTitle}>{activeBoons.length ? `${activeBoons.length} blessings active` : 'No boons yet'}</h3>
        </div>
        <div style={s.boonGrid}>
          {activeBoons.length === 0 && <p style={s.copy}>Boon nodes will add Guardian powers to the rest of this run.</p>}
          {activeBoons.map((boon) => (
            <article key={boon.id} style={s.boonCard}>
              <strong>{boon.name}</strong>
              <span style={s.nodeHint}>{boon.rarity}</span>
              <p style={s.smallCopy}>{boon.description}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}

const baseNode = {
  minWidth: 150,
  minHeight: 100,
  padding: 14,
  borderRadius: 14,
  border: '1px solid rgba(255,255,255,.14)',
  background: 'rgba(255,255,255,.055)',
  display: 'flex',
  flexDirection: 'column',
  gap: 6,
}

const s = {
  panel: { border: '1px solid rgba(255,255,255,.12)', background: 'rgba(10,14,24,.82)', borderRadius: 24, padding: 24 },
  header: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 18, marginBottom: 18, flexWrap: 'wrap' },
  eyebrow: { color: '#c9a756', fontSize: 12, fontWeight: 900, letterSpacing: '.18em', textTransform: 'uppercase', margin: 0 },
  title: { fontSize: 26, margin: '4px 0' },
  sectionTitle: { margin: '4px 0 0', fontSize: 18 },
  copy: { margin: 0, color: 'rgba(247,240,223,.68)', fontSize: 14, lineHeight: 1.6 },
  smallCopy: { margin: '4px 0 0', color: 'rgba(247,240,223,.62)', fontSize: 12, lineHeight: 1.5 },
  actions: { display: 'flex', gap: 8, flexWrap: 'wrap' },
  primaryBtn: { padding: '10px 16px', borderRadius: 10, border: '1px solid rgba(201,167,86,.58)', background: 'rgba(201,167,86,.2)', color: '#f7f0df', fontWeight: 900, cursor: 'pointer', fontFamily: 'inherit' },
  summaryGrid: { display: 'grid', gridTemplateColumns: 'repeat(3,minmax(0,1fr))', gap: 10, marginBottom: 18 },
  statCard: { border: '1px solid rgba(255,255,255,.1)', background: 'rgba(255,255,255,.045)', borderRadius: 12, padding: 12 },
  statLabel: { display: 'block', color: 'rgba(247,240,223,.48)', fontSize: 11, textTransform: 'uppercase', letterSpacing: '.08em', marginBottom: 4 },
  map: { display: 'grid', gap: 14 },
  floor: { border: '1px solid rgba(255,255,255,.09)', background: 'rgba(255,255,255,.035)', borderRadius: 16, padding: 14 },
  floorLabel: { color: '#c9a756', fontWeight: 900, fontSize: 12, marginBottom: 10, textTransform: 'uppercase', letterSpacing: '.12em' },
  nodeRow: { display: 'flex', gap: 10, flexWrap: 'wrap' },
  node: baseNode,
  currentNode: { ...baseNode, borderColor: 'rgba(201,167,86,.75)', background: 'rgba(201,167,86,.15)', boxShadow: '0 0 0 1px rgba(201,167,86,.18)' },
  doneNode: { ...baseNode, opacity: .52, background: 'rgba(134,239,172,.08)', borderColor: 'rgba(134,239,172,.25)' },
  bossNode: { ...baseNode, borderColor: 'rgba(248,113,113,.45)', background: 'rgba(248,113,113,.08)' },
  eliteNode: { ...baseNode, borderColor: 'rgba(251,191,36,.45)', background: 'rgba(251,191,36,.08)' },
  boonNode: { ...baseNode, borderColor: 'rgba(168,85,247,.5)', background: 'rgba(168,85,247,.1)' },
  wandererNode: { ...baseNode, borderColor: 'rgba(56,189,248,.45)', background: 'rgba(56,189,248,.08)' },
  mysteryNode: { ...baseNode, borderColor: 'rgba(168,85,247,.5)', background: 'rgba(168,85,247,.1)' },
  nodeType: { color: 'rgba(247,240,223,.48)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '.1em', fontWeight: 800 },
  nodeName: { fontSize: 13, lineHeight: 1.35 },
  nodeHint: { color: 'rgba(247,240,223,.5)', fontSize: 11 },
  boonPanel: { marginTop: 18, border: '1px solid rgba(255,255,255,.1)', background: 'rgba(255,255,255,.04)', borderRadius: 16, padding: 16 },
  boonGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(190px,1fr))', gap: 10, marginTop: 12 },
  boonCard: { border: '1px solid rgba(255,255,255,.1)', background: 'rgba(255,255,255,.045)', borderRadius: 12, padding: 12 },
}
