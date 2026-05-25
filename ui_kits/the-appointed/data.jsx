// data.jsx — fixture data for the prototype.
// Sourced from characters.js / hubCharacters.js / gameConfig.js in the real repo.

const THE_SEVEN = [
  { id:'aeryn',  name:'Aeryn',   trueName:'Luciel',     sin:'Pride',    costume:'Righteousness',      virtue:'Dignity',          job:'Soldier', glyph:'A', color:'#d4af37', integrity:84, hp:[74,98],  tmp:[60,72], eth:[42,55] },
  { id:'cael',   name:'Cael',    trueName:'Zaqiel',     sin:'Envy',     costume:'Righteous Advocacy', virtue:'Justice',          job:'Archer',  glyph:'C', color:'#4a8c6f', integrity:71, hp:[58,72],  tmp:[40,52], eth:[60,68] },
  { id:'brennan',name:'Brennan', trueName:'Camael',     sin:'Wrath',    costume:'Holy Zeal',          virtue:'Righteous Anger',  job:'Soldier', glyph:'B', color:'#9b2335', integrity:56, hp:[82,110], tmp:[78,90], eth:[28,40] },
  { id:'solan',  name:'Solan',   trueName:'Raziel',     sin:'Sloth',    costume:'Contemplation',      virtue:'Sacred Rest',      job:'Mage',    glyph:'S', color:'#6b5b8a', integrity:62, hp:[52,68],  tmp:[24,36], eth:[88,102] },
  { id:'mira',   name:'Mira',    trueName:'Sachiel',    sin:'Greed',    costume:'Stewardship',        virtue:'Provision',        job:'Vagrant', glyph:'M', color:'#b8860b', integrity:78, hp:[64,80],  tmp:[44,56], eth:[48,60] },
  { id:'tobias', name:'Tobias',  trueName:'Muriel',     sin:'Gluttony', costume:'Bodily Purity',      virtue:'Joy',              job:'Cleric',  glyph:'T', color:'#8a9a8a', integrity:92, hp:[68,84],  tmp:[36,48], eth:[72,88] },
  { id:'seren',  name:'Seren',   trueName:'Anael',      sin:'Lust',     costume:'Celibacy',           virtue:'Sacred Love',      job:'Archer',  glyph:'S', color:'#e8d8c8', integrity:65, hp:[60,76],  tmp:[42,54], eth:[54,68] },
];

// Hub characters in the Antechamber
const HUB_LOCATIONS = [
  { id:'dock',     name:'The Dock',         keeper:'Azrael',      tradition:'Hebrew / Islamic',  desc:'The angel of accompaniment stands by the still water. He never leaves.', tier:1, locked:false },
  { id:'garden',   name:'The Courtyard Garden', keeper:'Ereshkigal', tradition:'Sumerian',     desc:'Older than every theology that came after her. She tends a garden of things that should not grow here.', tier:1, locked:false },
  { id:'library',  name:'The Library Corner', keeper:'Casimir',   tradition:'Original — human',  desc:'A scholar who reads the same books in different orders, hoping for a different ending.', tier:1, locked:false },
  { id:'corners',  name:'The Dark Corners', keeper:'Lilith',      tradition:'Kabbalistic',       desc:'She is present, but distant. To approach her requires having seen something.', tier:3, locked:false },
  { id:'pool',     name:'The Deep Pool',    keeper:'Anamnesis',   tradition:'Greek / Liturgy',   desc:'Not a god. A sacred concept. The pool returns what was forgotten — when you are ready.', tier:3, locked:false },
  { id:'threshold',name:'The Threshold',    keeper:'Somnus',      tradition:'Roman',             desc:'Sealed until the loop slows enough to let night fall.', tier:5, locked:true },
];

const BOSSES = [
  { id:'righteous', title:'The Righteous One', trueName:'Sabriel',    mirrors:'Aeryn',  sin:'Pride',    color:'#d4af37', talkRequires:'Run 10+ · Aeryn costume ≤ 40' },
  { id:'keeper',    title:'The Keeper',        trueName:'Vashiel',    mirrors:'Solan',  sin:'Sloth',    color:'#6b5b8a', talkRequires:'Run 8+ · Solan costume ≤ 35' },
  { id:'devoted',   title:'The Devoted',       trueName:'Celestiel',  mirrors:'Tobias', sin:'Gluttony', color:'#8a9a8a', talkRequires:'Run 8+ · Tobias costume ≤ 30' },
  { id:'wrathful',  title:'The Wrathful',      trueName:'Arariel',    mirrors:'Brennan',sin:'Wrath',    color:'#9b2335', talkRequires:'Run 12+ · Brennan ≤ 25 · Moses met' },
  { id:'mirror',    title:'The Mirror',        trueName:'—',          mirrors:'You',    sin:'Variable', color:'#e8d8c8', talkRequires:'No talk path — fight only' },
];

const TIER_NAMES = ['', 'The War', 'The Cracks', 'The Fallen', 'The Pattern', 'The Ascent'];
const TIER_COLORS = ['', '#4a6fa5', '#7a5c8a', '#8a3a3a', '#c8a040', '#e8e0d0'];

const ABILITIES = [
  { id:'strike',   name:'Strike',         element:'physical', desc:'A measured blow. Costs nothing.',           hit:92, crit:8,  power:34 },
  { id:'judgment', name:'Judgment Stroke',element:'holy',     desc:'Aeryn marks the target. Front-hit verdict.', hit:78, crit:24, power:58 },
  { id:'lance',    name:'Lance of Light', element:'holy',     desc:'Costs 18 ether. Pierces armor.',             hit:84, crit:12, power:48 },
  { id:'mercy',    name:'Mercy',          element:'holy',     desc:'Heal a wounded ally within 3 tiles.',        hit:100,crit:0,  power:46 },
];

// Sample battle units laid out for the demo grid
const BATTLE_UNITS = [
  // players
  { id:'u-aeryn',   name:'Aeryn',   team:'player', glyph:'A', color:'#d4af37', x:2, y:5, hp:78,  hpMax:98 },
  { id:'u-cael',    name:'Cael',    team:'player', glyph:'C', color:'#4a8c6f', x:1, y:6, hp:64,  hpMax:72 },
  { id:'u-brennan', name:'Brennan', team:'player', glyph:'B', color:'#9b2335', x:3, y:6, hp:96,  hpMax:110 },
  { id:'u-solan',   name:'Solan',   team:'player', glyph:'S', color:'#6b5b8a', x:0, y:5, hp:52,  hpMax:68 },
  // enemies
  { id:'e1', name:'Fen Wraith',  team:'enemy', glyph:'w', color:'#7a6ca6', x:6, y:3, hp:38, hpMax:60 },
  { id:'e2', name:'Null Drake',  team:'enemy', glyph:'D', color:'#9b2335', x:7, y:4, hp:88, hpMax:120 },
  { id:'e3', name:'Storm Imp',   team:'enemy', glyph:'i', color:'#fde047', x:8, y:6, hp:22, hpMax:42 },
  { id:'e4', name:'Veriel',      team:'enemy', glyph:'V', color:'#d4af37', x:9, y:5, hp:140,hpMax:180, boss:true },
];

// 10×8 tile map: terrain codes
const TILE_MAP = [
  ['g','g','g','s','s','s','s','g','g','g'],
  ['g','g','s','s','sh','s','s','s','g','g'],
  ['g','g','s','w','w','w','s','s','g','g'],
  ['g','g','s','w','w','w','s','s','g','g'],
  ['g','g','g','s','s','s','s','s','g','g'],
  ['g','g','g','g','s','s','s','g','g','g'],
  ['g','g','g','g','g','g','g','g','g','g'],
  ['g','g','g','g','g','g','g','g','g','g'],
];

Object.assign(window, { THE_SEVEN, HUB_LOCATIONS, BOSSES, TIER_NAMES, TIER_COLORS, ABILITIES, BATTLE_UNITS, TILE_MAP });
