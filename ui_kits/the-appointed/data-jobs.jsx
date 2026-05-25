// data-jobs.jsx — expanded character / job data for the Roster screen.
//
// The eight jobs as ordered classes (Soldier is rank-0 starter, the rest
// branch off). Each character has a primary + secondary + a tree of
// unlocked / available / locked classes. Real game data would live in
// /src/game/data/classes.js — this is a faithful spec the upstream team
// can use as a template.

const JOBS = {
  soldier: { name: 'Soldier',  color: '#c8a96e', desc: 'Frontline infantry. Holds the line. Counterattack with shield brace.', stats: { atk: 14, def: 11, mag: 4,  res: 6,  spd: 9,  mv: 4 } },
  knight:  { name: 'Knight',   color: '#d4af37', desc: 'Heavy armour, lance reach. Cover allies on adjacent tiles.',           stats: { atk: 17, def: 16, mag: 3,  res: 8,  spd: 7,  mv: 3 } },
  archer:  { name: 'Archer',   color: '#4a8c6f', desc: 'Long-range. Pin enemies. High-ground bonuses.',                        stats: { atk: 13, def: 7,  mag: 4,  res: 6,  spd: 12, mv: 4 } },
  mage:    { name: 'Mage',     color: '#6b5b8a', desc: 'Elemental casts. Fire / ice / thunder reactions seed the grid.',       stats: { atk: 6,  def: 5,  mag: 17, res: 13, spd: 9,  mv: 3 } },
  cleric:  { name: 'Cleric',   color: '#e8d8c8', desc: 'Heal, cleanse, raise. Aoe mercy at the cost of own ether.',             stats: { atk: 5,  def: 6,  mag: 14, res: 14, spd: 10, mv: 4 } },
  templar: { name: 'Templar',  color: '#d4af37', desc: 'Holy zeal — strike, then bless adjacent ally. Two-step turns.',         stats: { atk: 14, def: 13, mag: 10, res: 11, spd: 8,  mv: 3 } },
  vagrant: { name: 'Vagrant',  color: '#8a7e6a', desc: 'Walks unseen. Backstab crit modifier, traps, lockpick costume-gates.',  stats: { atk: 11, def: 6,  mag: 5,  res: 7,  spd: 14, mv: 5 } },
  monk:    { name: 'Monk',     color: '#b8860b', desc: 'Unarmed bursts. Channels through costume rather than around it.',       stats: { atk: 15, def: 9,  mag: 8,  res: 12, spd: 11, mv: 4 } },
};

// One row per character — extends THE_SEVEN with full job-tree state.
// status: "primary" | "secondary" | "unlocked" | "available" | "locked"
// available means JP unlocked but not yet selected; locked is JP gated.
const CHAR_JOBS = {
  aeryn:   {
    primary: 'soldier', secondary: 'templar',
    tree: {
      soldier: { status: 'primary',   jp: 1080, max: 1080, mastered: true },
      knight:  { status: 'unlocked',  jp:  720, max: 1200 },
      templar: { status: 'secondary', jp:  920, max: 1200 },
      cleric:  { status: 'available', jp:    0, max: 1000 },
      archer:  { status: 'locked',    jp:    0, max:  800, requires: 'Soldier · 600' },
      mage:    { status: 'locked',    jp:    0, max: 1200, requires: 'Cleric · 400' },
      monk:    { status: 'locked',    jp:    0, max: 1000 },
      vagrant: { status: 'locked',    jp:    0, max:  800 },
    },
    abilities: [
      { id:'strike',   name:'Strike',         job:'soldier', desc:'A measured blow. Costs nothing.',           cost:0,  hit:92, equipped:true },
      { id:'shieldbrace', name:'Shield Brace', job:'soldier', desc:'Brace until next turn. +40% defence.',     cost:0,  hit:100, equipped:true },
      { id:'judgment', name:'Judgment Stroke', job:'templar', desc:'Marks the target. Front-hit verdict.',     cost:14, hit:78, equipped:true },
      { id:'lance',    name:'Lance of Light',  job:'templar', desc:'Pierces physical armour. Costs ether.',    cost:18, hit:84, equipped:true },
      { id:'mercy',    name:'Mercy',           job:'cleric',  desc:'Heal a wounded ally within 3 tiles.',      cost:12, hit:100, equipped:false },
      { id:'cover',    name:'Cover',           job:'knight',  desc:'Adjacent ally takes Aeryn\'s next hit.',   cost:0,  hit:100, equipped:false },
    ],
  },
  cael:    { primary:'archer', secondary:'vagrant',
    tree: { archer:{status:'primary',jp:980,max:1000,mastered:true}, vagrant:{status:'secondary',jp:540,max:800},
            soldier:{status:'unlocked',jp:420,max:1000}, mage:{status:'available',jp:0,max:1000},
            cleric:{status:'locked',jp:0,max:1000}, monk:{status:'locked',jp:0,max:800}, knight:{status:'locked',jp:0,max:1200}, templar:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'shot',name:'Shot',job:'archer',desc:'Single arrow. High-ground bonus.',cost:0,hit:88,equipped:true},
      {id:'pin',name:'Pin Arrow',job:'archer',desc:'Halves target Move next turn.',cost:6,hit:80,equipped:true},
      {id:'shadow',name:'Shadow Step',job:'vagrant',desc:'Reposition 3 tiles, no AoO.',cost:8,hit:100,equipped:true},
    ],
  },
  brennan: { primary:'soldier', secondary:'monk',
    tree: { soldier:{status:'primary',jp:1200,max:1200,mastered:true}, monk:{status:'secondary',jp:640,max:1000},
            knight:{status:'unlocked',jp:880,max:1200}, vagrant:{status:'available',jp:0,max:800},
            cleric:{status:'locked',jp:0,max:1000}, archer:{status:'locked',jp:0,max:800}, mage:{status:'locked',jp:0,max:1200}, templar:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'strike',name:'Strike',job:'soldier',desc:'A measured blow.',cost:0,hit:92,equipped:true},
      {id:'rage',name:'Holy Rage',job:'soldier',desc:'+50% atk, -30% def for 2 turns.',cost:10,hit:100,equipped:true},
      {id:'crush',name:'Crushing Blow',job:'monk',desc:'Stuns the target. Costs HP.',cost:0,hit:75,equipped:true},
    ],
  },
  solan:   { primary:'mage', secondary:'cleric',
    tree: { mage:{status:'primary',jp:1100,max:1200,mastered:false}, cleric:{status:'secondary',jp:720,max:1000},
            soldier:{status:'unlocked',jp:300,max:1000}, templar:{status:'available',jp:0,max:1200},
            monk:{status:'locked',jp:0,max:1000}, archer:{status:'locked',jp:0,max:800}, vagrant:{status:'locked',jp:0,max:800}, knight:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'fire',name:'Fire',job:'mage',desc:'AoE fire. Burns tiles.',cost:16,hit:84,equipped:true},
      {id:'ice',name:'Ice',job:'mage',desc:'Freezes wet tiles solid.',cost:18,hit:84,equipped:true},
      {id:'mercy',name:'Mercy',job:'cleric',desc:'Heal an ally.',cost:12,hit:100,equipped:true},
    ],
  },
  mira:    { primary:'vagrant', secondary:'archer',
    tree: { vagrant:{status:'primary',jp:1000,max:1000,mastered:true}, archer:{status:'secondary',jp:480,max:1000},
            soldier:{status:'unlocked',jp:520,max:1000}, monk:{status:'available',jp:0,max:1000},
            mage:{status:'locked',jp:0,max:1200}, cleric:{status:'locked',jp:0,max:1000}, templar:{status:'locked',jp:0,max:1200}, knight:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'backstab',name:'Backstab',job:'vagrant',desc:'+200% rear-hit crit.',cost:0,hit:78,equipped:true},
      {id:'lift',name:'Lift Trinket',job:'vagrant',desc:'Steal a token from the dead.',cost:4,hit:100,equipped:true},
      {id:'shot',name:'Shot',job:'archer',desc:'Single arrow.',cost:0,hit:88,equipped:true},
    ],
  },
  tobias:  { primary:'cleric', secondary:'monk',
    tree: { cleric:{status:'primary',jp:1180,max:1200,mastered:false}, monk:{status:'secondary',jp:600,max:1000},
            mage:{status:'unlocked',jp:340,max:1200}, templar:{status:'available',jp:0,max:1200},
            soldier:{status:'locked',jp:0,max:1000}, archer:{status:'locked',jp:0,max:800}, vagrant:{status:'locked',jp:0,max:800}, knight:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'mercy',name:'Mercy',job:'cleric',desc:'Heal an ally.',cost:12,hit:100,equipped:true},
      {id:'cleanse',name:'Cleanse',job:'cleric',desc:'Strip a debuff. Sanctifies the tile.',cost:14,hit:100,equipped:true},
      {id:'crush',name:'Crushing Blow',job:'monk',desc:'Stuns.',cost:0,hit:75,equipped:true},
    ],
  },
  seren:   { primary:'archer', secondary:'cleric',
    tree: { archer:{status:'primary',jp:920,max:1000,mastered:false}, cleric:{status:'secondary',jp:560,max:1000},
            vagrant:{status:'unlocked',jp:380,max:800}, soldier:{status:'available',jp:0,max:1000},
            mage:{status:'locked',jp:0,max:1200}, templar:{status:'locked',jp:0,max:1200}, monk:{status:'locked',jp:0,max:1000}, knight:{status:'locked',jp:0,max:1200} },
    abilities:[
      {id:'shot',name:'Shot',job:'archer',desc:'Single arrow.',cost:0,hit:88,equipped:true},
      {id:'pierce',name:'Pierce',job:'archer',desc:'Ignores 30% phys armour.',cost:6,hit:80,equipped:true},
      {id:'mercy',name:'Mercy',job:'cleric',desc:'Heal an ally.',cost:12,hit:100,equipped:true},
    ],
  },
};

Object.assign(window, { JOBS, CHAR_JOBS });
