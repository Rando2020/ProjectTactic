// RunMap.jsx — pathway screen for a 10-floor descent.
//
// FFT meets Slay-the-Spire: each floor has 1-3 nodes the player picks
// between. Brass hairlines suggest the route. The boss medallion sits
// alone on the final floor.
const { useState: useStateRM } = React;

// A fixed sample run plan — in production this would come from the
// upstream run generator (see /src/game/systems/floorGenerator.js).
const SAMPLE_PLAN = [
  { floor: 1, nodes: [{ type: 'regular', name: 'Foothill skirmish',  rewards: { jp: 18, gold: 60 } }] },
  { floor: 2, nodes: [{ type: 'regular', name: 'Stone bridge ambush', rewards: { jp: 22, gold: 80 } },
                      { type: 'wanderer', name: 'A pilgrim with a question', rewards: { item: 'Cost: 50g', secret: 'Maybe' } }] },
  { floor: 3, nodes: [{ type: 'boon', name: 'The Stewardess offers', rewards: { boon: 'Greed boon · pick 1 of 3' } },
                      { type: 'mystery', name: '— sealed —', rewards: { item: '?' } },
                      { type: 'regular', name: 'Patrol of three', rewards: { jp: 20, gold: 70 } }] },
  { floor: 4, nodes: [{ type: 'elite', name: 'A Knight, mid-arc', rewards: { jp: 48, gold: 180, item: 'Elite drop' } },
                      { type: 'regular', name: 'Soulless watchmen', rewards: { jp: 22, gold: 80 } }] },
  { floor: 5, nodes: [{ type: 'mystery', name: '— sealed —', rewards: { item: '?' } },
                      { type: 'wanderer', name: 'A familiar voice', rewards: { secret: 'Memory fragment' } }] },
  { floor: 6, nodes: [{ type: 'regular', name: 'Ascending corridor', rewards: { jp: 26, gold: 110 } },
                      { type: 'boon', name: 'The Cleric offers', rewards: { boon: 'Gluttony boon · pick 1 of 3' } },
                      { type: 'regular', name: 'Side passage', rewards: { jp: 24, gold: 100 } }] },
  { floor: 7, nodes: [{ type: 'elite', name: 'A Templar, refusing', rewards: { jp: 56, gold: 210, item: 'Elite drop' } }] },
  { floor: 8, nodes: [{ type: 'mystery', name: '— sealed —', rewards: { item: '?' } },
                      { type: 'regular', name: 'Final guard', rewards: { jp: 32, gold: 140 } }] },
  { floor: 9, nodes: [{ type: 'boon', name: 'The Mage offers', rewards: { boon: 'Sloth boon · pick 1 of 3' } }] },
  { floor: 10, nodes: [{ type: 'boss', name: 'The Keeper · Vashiel', rewards: { jp: 220, gold: 600, item: 'Boss key' } }], boss: true },
];

// Mark some floors as already cleared / current for the demo
const PROGRESS = { currentFloor: 5, currentIdx: 0 };

function NodeCell({ node, current, done, onSelect, size = 56 }) {
  return (
    <div className={`node-cell${current ? ' is-current' : ''}${done ? ' is-done' : ''}`}
         onClick={() => { window.Sfx?.play('select'); onSelect(node); }}>
      <Sigil type={node.type} size={size} current={current} completed={done} />
      <div className="nlabel">{SIGIL_TYPES[node.type]?.label || node.type}</div>
    </div>
  );
}

function Inspector({ node }) {
  if (!node) return (
    <div className="node-inspector">
      <p className="muted">Click a sigil to inspect the encounter.</p>
    </div>
  );
  const t = SIGIL_TYPES[node.type];
  return (
    <div className="node-inspector">
      <div className="head">
        <Sigil type={node.type} size={48} />
        <div>
          <div className="name" style={{ color: t.color }}>{t.label}</div>
          <div className="sub">{node.name}</div>
        </div>
      </div>
      <p>{t.desc}</p>
      <div style={{ marginTop: 4 }}>
        {node.rewards?.jp != null   && <div className="reward"><span>Job Points</span><span className="v">+{node.rewards.jp}</span></div>}
        {node.rewards?.gold != null && <div className="reward"><span>Gold</span><span className="v">+{node.rewards.gold}</span></div>}
        {node.rewards?.item         && <div className="reward"><span>Item</span><span className="v">{node.rewards.item}</span></div>}
        {node.rewards?.boon         && <div className="reward"><span>Boon</span><span className="v">{node.rewards.boon}</span></div>}
        {node.rewards?.secret       && <div className="reward"><span>Secret</span><span className="v">{node.rewards.secret}</span></div>}
      </div>
      <button className="btn btn-sacred" style={{ marginTop: 8 }}
              onClick={() => window.Sfx?.play('confirm')}>
        {node.type === 'boss' ? 'Confront the Keeper' : node.type === 'boon' ? 'Receive the gift' : 'Enter'}
      </button>
    </div>
  );
}

function RunMap() {
  const [selected, setSelected] = useStateRM(null);
  return (
    <div className="run-map-stage">
      <aside className="run-map-rail">
        <h3>Legend</h3>
        <div className="legend">
          {['regular','elite','mystery','boon','wanderer','boss'].map((id) => (
            <div className="legend-row" key={id}>
              <Sigil type={id} size={32} />
              <div>
                <div className="name" style={{ color: SIGIL_TYPES[id].color }}>{SIGIL_TYPES[id].label}</div>
                <div className="desc">{SIGIL_TYPES[id].desc}</div>
              </div>
            </div>
          ))}
        </div>
      </aside>

      <section className="path-stage">
        <div style={{ textAlign: 'center', marginBottom: 12 }}>
          <div className="eyebrow ash" style={{ fontSize: 11 }}>Descent · 10 floors</div>
          <h2 style={{ margin: '6px 0 0', fontSize: 22 }}>The Mountain Path</h2>
          <p className="muted" style={{ margin: '6px 0 0', fontSize: 13, fontStyle: 'italic' }}>
            Floor {PROGRESS.currentFloor} of 10. Each fork remembers what you took.
          </p>
        </div>
        {SAMPLE_PLAN.map((floor, fi) => {
          const isBoss = floor.boss;
          const done = floor.floor < PROGRESS.currentFloor;
          const onCurrent = floor.floor === PROGRESS.currentFloor;
          return (
            <div key={floor.floor} className={`floor-row${isBoss ? ' boss-floor' : ''}`}>
              <div className="floor-num">FL · {String(floor.floor).padStart(2, '0')}</div>
              <div className="nodes">
                {floor.nodes.map((node, ni) => {
                  const isCurrent = onCurrent && ni === PROGRESS.currentIdx;
                  return (
                    <NodeCell
                      key={ni}
                      node={node}
                      current={isCurrent}
                      done={done}
                      onSelect={setSelected}
                      size={isBoss ? 80 : 44}
                    />
                  );
                })}
              </div>
            </div>
          );
        })}
      </section>

      <aside>
        <Inspector node={selected} />
      </aside>
    </div>
  );
}

Object.assign(window, { RunMap });
