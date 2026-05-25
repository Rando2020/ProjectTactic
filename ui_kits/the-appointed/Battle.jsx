// Battle.jsx — tactical battle screen
const { useState: useStateBT } = React;

const TILE_TYPE = { g: 'grass', s: 'stone', sh: 'shrine', w: 'water', x: 'wall' };

function Tile({ tile, units, sel, move, attack, onClick }) {
  const unit = units.find((u) => u.x === tile.x && u.y === tile.y);
  const isMove = move.has(`${tile.x},${tile.y}`) && !unit;
  const isAtk  = attack.has(`${tile.x},${tile.y}`) && unit && unit.team === 'enemy';
  const isSel  = sel && unit && unit.id === sel;
  const cls = `tile ${TILE_TYPE[tile.type]}${isMove ? ' move' : ''}${isAtk ? ' attack' : ''}${isSel ? ' selected' : ''}`;
  return (
    <div className={cls} onClick={() => onClick(tile, unit)}>
      {unit && (
        <div className={`unit ${unit.team}${unit.boss ? ' boss' : ''}`} style={{ borderColor: unit.color, color: unit.color, background: `${unit.color}22` }}>
          {unit.glyph}
          <div className="unit-hp" style={{ ['--hp']: `${(unit.hp / unit.hpMax) * 100}%` }} />
        </div>
      )}
    </div>
  );
}

function BattleGrid({ units, selectedId, move, attack, onSelect }) {
  const tiles = [];
  for (let y = 0; y < TILE_MAP.length; y++) {
    for (let x = 0; x < TILE_MAP[y].length; x++) {
      tiles.push({ x, y, type: TILE_MAP[y][x] });
    }
  }
  return (
    <div className="battle-grid-wrap">
      <div className="battle-grid">
        {tiles.map((t) => (
          <Tile key={`${t.x}-${t.y}`} tile={t} units={units} sel={selectedId} move={move} attack={attack} onClick={(_, u) => u && onSelect(u.id)} />
        ))}
      </div>
    </div>
  );
}

function CommandMenu({ unit, active, onPick }) {
  const cmds = [
    { id: 'move',    label: 'Move',    desc: 'Reposition within range', hot: 'M' },
    { id: 'attack',  label: 'Attack',  desc: 'Strike adjacent target',  hot: 'A' },
    { id: 'ability', label: 'Ability', desc: 'Job action — costs ETH', hot: 'B' },
    { id: 'item',    label: 'Item',    desc: 'Vitae Draught, etc',     hot: 'I' },
    { id: 'wait',    label: 'Wait',    desc: 'End turn, hold position',hot: 'W' },
  ];
  if (!unit) return <div className="command-menu"><div className="muted">No active unit.</div></div>;
  return (
    <div className="command-menu">
      <div className="head">
        <div className="name" style={{ color: unit.color }}>{unit.name.toUpperCase()}</div>
        <div className="job">{unit.team === 'player' ? 'Acting' : 'Enemy'}</div>
      </div>
      <div className="command-list">
        {cmds.map((c) => (
          <button key={c.id} className={`command-btn${active === c.id ? ' active' : ''}`} onClick={() => { window.Sfx?.play('tick'); onPick(c.id); }}>
            <div>
              <div className="lbl">{c.label}</div>
              <div className="desc">{c.desc}</div>
            </div>
            <div className="hot">[{c.hot}]</div>
          </button>
        ))}
      </div>
    </div>
  );
}

function UnitPane({ unit, label = 'Inspect' }) {
  if (!unit) {
    return (
      <div className="unit-pane">
        <div className="head"><div><div className="name">No selection</div><div className="meta">Click an enemy or ally.</div></div></div>
      </div>
    );
  }
  const tmp = unit.tmp || [50, 80];
  const eth = unit.eth || [30, 60];
  return (
    <div className="unit-pane">
      <div className="head">
        <div className="portrait-lg" style={{ color: unit.color, borderColor: unit.color, background: `${unit.color}22` }}>
          {unit.glyph}
        </div>
        <div style={{ minWidth: 0 }}>
          <div className="name">{unit.name}</div>
          <div className="meta">{unit.boss ? 'Fallen Angel' : unit.team === 'player' ? 'Ally · Lv 7' : 'Hostile · Lv 5'}</div>
        </div>
      </div>
      <div className="bars">
        <div className="bar-row">
          <span className="l hp">HP</span>
          <div className="bar-track"><div className="bar-fill" style={{ width: `${(unit.hp / unit.hpMax) * 100}%` }} /></div>
          <span className="v">{unit.hp}/{unit.hpMax}</span>
        </div>
        <div className="bar-row">
          <span className="l tmp">TMP</span>
          <div className="bar-track"><div className="bar-fill tmp" style={{ width: `${(tmp[0] / tmp[1]) * 100}%` }} /></div>
          <span className="v">{tmp[0]}/{tmp[1]}</span>
        </div>
        <div className="bar-row">
          <span className="l eth">ETH</span>
          <div className="bar-track"><div className="bar-fill eth" style={{ width: `${(eth[0] / eth[1]) * 100}%` }} /></div>
          <span className="v">{eth[0]}/{eth[1]}</span>
        </div>
      </div>
    </div>
  );
}

function ForecastHud({ attacker, target, ability }) {
  if (!attacker || !target || !ability) {
    return (
      <div className="forecast">
        <div className="forecast-pane"><div className="label">Acting</div><div className="muted">—</div></div>
        <div className="forecast-pane center">
          <div className="label">Intent</div>
          <div className="muted" style={{ textAlign: 'center', padding: '12px 0' }}>Select an attack target to preview the forecast.</div>
        </div>
        <div className="forecast-pane"><div className="label">Target</div><div className="muted">—</div></div>
      </div>
    );
  }
  return (
    <div className="forecast">
      <div className="forecast-pane">
        <div className="label">Acting</div>
        <div className="who">
          <div className="p" style={{ color: attacker.color, borderColor: attacker.color, background: `${attacker.color}22` }}>{attacker.glyph}</div>
          <div>
            <div className="n">{attacker.name}</div>
            <div className="m">Front-facing · Lv 7 Soldier</div>
          </div>
        </div>
      </div>
      <div className="forecast-pane center">
        <div className="label">Intent · {ability.element.toUpperCase()}</div>
        <div className="ability">{ability.name}<span className="ability-meta">{ability.desc}</span></div>
        <div className="big">{ability.power}<span className="lbl">Damage</span></div>
        <div className="odds">
          <div className="o"><div className="n">{ability.hit}%</div><span className="l">Hit</span></div>
          <div className="o"><div className="n">{ability.crit}%</div><span className="l">Crit</span></div>
          <div className="o"><div className="n">−18</div><span className="l">Temper</span></div>
        </div>
      </div>
      <div className="forecast-pane">
        <div className="label">Target</div>
        <div className="who">
          <div className="p" style={{ color: target.color, borderColor: target.color, background: `${target.color}22` }}>{target.glyph}</div>
          <div>
            <div className="n">{target.name}</div>
            <div className="m">HP after: <strong style={{ color: 'var(--crimson)' }}>{Math.max(0, target.hp - ability.power)}</strong> / {target.hpMax}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function TurnOrder({ units, activeId }) {
  // Static order for the demo
  const order = [
    units.find(u => u.id === 'u-aeryn'),
    units.find(u => u.id === 'e4'),
    units.find(u => u.id === 'u-brennan'),
    units.find(u => u.id === 'e2'),
    units.find(u => u.id === 'u-cael'),
    units.find(u => u.id === 'e1'),
    units.find(u => u.id === 'u-solan'),
  ].filter(Boolean);
  return (
    <div className="turn-order">
      <span className="turn-of">Turn order</span>
      {order.map((u, i) => (
        <div key={u.id} className={`turn-pip${u.id === activeId ? ' now' : ''}`}>
          <div className="tp-portrait" style={{ borderColor: u.color, color: u.color, background: `${u.color}22` }}>{u.glyph}</div>
          <div className="tp-name">{u.name.split(' ')[0]}</div>
        </div>
      ))}
    </div>
  );
}

function Battle({ tier }) {
  const [units] = useStateBT(BATTLE_UNITS);
  const [selectedId, setSelectedId] = useStateBT('u-aeryn');
  const [active, setActive] = useStateBT('ability');
  const selected = units.find((u) => u.id === selectedId);
  const acting = units.find((u) => u.id === 'u-aeryn');
  const target = units.find((u) => u.id === 'e4');
  const ability = ABILITIES[1]; // Judgment Stroke
  const move   = new Set(['1,4','2,4','3,4','1,3','3,3','2,3','1,5','3,5']);
  const attack = new Set(['9,5']);

  return (
    <div className="battle">
      <div className="battle-top">
        <span className="turn-of">Currently acting</span>
        <span className="acting">Aeryn</span>
        <span className="chip gold">FRONT</span>
        <span className="chip violet">CT 100</span>
        {tier >= 3 && <span className="chip crimson">The Wrathful watching · Tier {tier}</span>}
        <TurnOrder units={units} activeId="u-aeryn" />
      </div>
      <div className="battle-main">
        <BattleGrid units={units} selectedId={selectedId} move={move} attack={attack} onSelect={setSelectedId} />
        <div className="battle-side">
          <CommandMenu unit={acting} active={active} onPick={setActive} />
          <UnitPane unit={selected} />
        </div>
      </div>
      <ForecastHud attacker={acting} target={target} ability={ability} />
    </div>
  );
}

Object.assign(window, { Battle });
