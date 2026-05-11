import { useState, useEffect, useRef } from 'react'

/* ═══════════════════════════════════════════════════════════
   VAELTHAR: EIDOLON CHRONICLES
   ─────────────────────────────────────────────────────────
   Systems:
   · ATB real-time combat  · Temper (physical armor) / Ether (magic armor)
   · SURGE timing attack   · DEFLECT timing defense
   · Multi-hit elemental rhythm (Thunder=4 fast, Ice=1 slow, etc.)
   · 2-way + 3-way elemental combo chains
   · Elemental surface reactions
   · 32 Guardians (8 elements × 4 tiers) with Resonant-level unlock
   · Elemental weaknesses / resistances
   · Floating damage numbers · Critical hits
   · Limit Break gauge per character
   · Resonance Window (save corrupted Guardians)
   · Item system (Vaelthar-named)
   · Base + Ascended job classes with passives
   · Smart enemy targeting
═══════════════════════════════════════════════════════════ */

// ─── ELEMENT COLORS & ICONS ───────────────────────────────
const EC = {
  fire:'#ff6b35', ice:'#74b9ff', thunder:'#ffd700', wind:'#00cec9',
  earth:'#a29bfe', water:'#0984e3', holy:'#ffeaa7', dark:'#9b59b6',
  none:'#b2bec3', guard:'#5dade2', cure:'#2ecc71',
  steam:'#dfe6e9', plasma:'#fd79a8',
}
const EI = { fire:'🔥', ice:'❄', thunder:'⚡', wind:'🌀', earth:'🪨', water:'🌊', holy:'✨', dark:'🌑' }

// ─── ELEMENTAL TIMING PROFILES ────────────────────────────
// Each element has a unique combat rhythm — this IS the gameplay
const ET = {
  fire:    { hits:3, winMs:360, gapMs:230, col:'#ff6b35', label:'IGNITE!'  },
  ice:     { hits:1, winMs:650, gapMs:0,   col:'#74b9ff', label:'SHATTER!' },
  thunder: { hits:4, winMs:210, gapMs:120, col:'#ffd700', label:'SURGE!'   },
  water:   { hits:2, winMs:400, gapMs:270, col:'#0984e3', label:'WAVE!'    },
  earth:   { hits:1, winMs:540, gapMs:0,   col:'#a29bfe', label:'CRUSH!'   },
  wind:    { hits:3, winMs:185, gapMs:120, col:'#00cec9', label:'GUST!'    },
  holy:    { hits:1, winMs:460, gapMs:0,   col:'#ffeaa7', label:'PURIFY!'  },
  dark:    { hits:2, winMs:420, gapMs:250, col:'#9b59b6', label:'DRAIN!'   },
  none:    { hits:1, winMs:440, gapMs:0,   col:'#e55039', label:'STRIKE!'  },
}

// ─── STATUS DEFINITIONS ───────────────────────────────────
// mag:1 = checks Ether  |  mag:0 = checks Temper
const SD = {
  burning:  { ico:'🔥', mag:1, dot:18, col:'#ff6b35', d:'Fire DoT. Extinguish with Water/Ice.' },
  wet:      { ico:'💧', mag:0, col:'#0984e3', d:'Amplifies Ice (×2.5) and Thunder (×2.0).' },
  chilled:  { ico:'🌨', mag:1, slow:.70, col:'#74b9ff', d:'ATB slowed by cold.' },
  frozen:   { ico:'🧊', mag:1, skip:1, col:'#00cec9', d:'Cannot act! Shatter with Thunder ×1.75.' },
  stun:     { ico:'⚡', mag:1, skip:1, col:'#ffd700', d:'Cannot act! 1 turn.' },
  bleed:    { ico:'🩸', mag:0, dot:14, col:'#e74c3c', d:'Physical DoT.' },
  slow:     { ico:'🐢', mag:0, slow:.50, col:'#a29bfe', d:'ATB speed halved.' },
  silence:  { ico:'🤫', mag:1, noMp:1, col:'#b2bec3', d:'Cannot use MP skills.' },
  blind:    { ico:'👁', mag:1, miss:.50, col:'#6c5ce7', d:'50% miss chance.' },
  cursed:   { ico:'💜', mag:1, dot:10, col:'#8e44ad', d:'Null DoT. Holy Purge ×1.6 + heals!' },
  blessed:  { ico:'✨', mag:1, col:'#ffeaa7', d:'Dark Corrupt ×1.6 + drains Ether!' },
  knockdown:{ ico:'⬇', mag:0, skip:1, col:'#fd9644', d:'Skip turn.' },
  weaken:   { ico:'💔', mag:0, dmgMult:.75, col:'#e74c3c', d:'25% less outgoing damage.' },
  berserk:  { ico:'🔴', mag:0, col:'#c0392b', dmgBoost:1.5, d:'BERSERK — +50% dmg, no control.' },
  regen:    { ico:'💚', mag:1, healPct:.07, col:'#2ecc71', d:'Recover 7% HP per turn.' },
  shielded: { ico:'🛡', mag:0, col:'#5dade2', d:'Phase shifted — physical misses.' },
}

// ─── SURFACE REACTIONS ────────────────────────────────────
const REACT = {
  'wet+ice':      { name:'❄ FREEZE REACTION',  bonus:1.35, sts:{t:'frozen',turns:2,ch:.88}, aF:.45, clear:'wet',     msg:'💧+❄ Wetness freezes!' },
  'wet+thunder':  { name:'⚡ ELECTRIFY',        bonus:1.45, sts:{t:'stun',turns:1,ch:.85},   aF:.45, clear:'wet',     msg:'💧+⚡ Ether conducts!' },
  'chilled+ice':  { name:'❄ DEEP FREEZE',       bonus:1.15, sts:{t:'frozen',turns:2,ch:.70}, aF:.60, clear:'chilled', msg:'🌨+❄ Chill freezes solid!' },
  'burning+water':{ name:'💧 EXTINGUISH',        bonus:.90,  applyWet:1,                      clear:'burning',        msg:'💧 Fire doused! Drenched!' },
  'burning+ice':  { name:'❄ CRYO-DOUSE',        bonus:1.0,  sts:{t:'chilled',turns:2,ch:.75},aF:.70, clear:'burning', msg:'❄ Flames frozen!' },
  'bleed+fire':   { name:'🔥 CAUTERIZE',         bonus:.85,  clear:'bleed',                                            msg:'🔥 Bleed seared shut!' },
  'frozen+thunder':{ name:'⚡ SHATTER',          bonus:1.75, clear:'frozen', shatterArmor:.35,                         msg:'⚡+🧊 FROZEN ETHER SHATTERS!' },
  'frozen+fire':  { name:'🔥 MELT',              bonus:1.10, applyWet:1, clear:'frozen',                               msg:'🔥 Ice melts! Drenched!' },
  'cursed+holy':  { name:'✨ HOLY PURGE',         bonus:1.60, clear:'cursed', healParty:55,                             msg:'✨ Null PURGED! Party healed!' },
  'blessed+dark': { name:'🌑 NULL CORRUPT',       bonus:1.60, clear:'blessed', drainEther:45,                          msg:'🌑 Blessing DEVOURED!' },
  'wet+earth':    { name:'🪨 MUDSLIDE',            bonus:1.20, sts:{t:'slow',turns:2,ch:.65},  aF:.60, clear:'wet',    msg:'💧+🪨 Mud engulfs!' },
}

// ─── COMBO TABLES ────────────────────────────────────────
const C2 = {
  'fire|ice':     { name:'Steam Burst',    p:200, e:'steam',  all:1, heal:0,   d:'Scalding vapor engulfs all!' },
  'fire|thunder': { name:'Plasma Nova',    p:285, e:'plasma', all:0, heal:0,   d:'Superheated Ether-plasma!' },
  'fire|wind':    { name:'Firestorm',      p:245, e:'fire',   all:1, heal:0,   d:'Cyclone of scorching flame!' },
  'fire|earth':   { name:'Magma Burst',    p:250, e:'fire',   all:1, heal:0,   d:'Lava erupts beneath all!' },
  'fire|dark':    { name:'Null Blaze',     p:270, e:'dark',   all:1, heal:0,   d:'Null-fire consumes all!' },
  'ice|thunder':  { name:'Frozen Bolt',    p:275, e:'thunder',all:0, heal:0,   d:'Cryo-electric discharge!' },
  'ice|wind':     { name:'Arctic Gale',    p:225, e:'ice',    all:1, heal:0,   d:'Polar winds freeze all!' },
  'ice|water':    { name:'Glacial Wave',   p:230, e:'ice',    all:1, heal:0,   d:'Freezing tidal surge!' },
  'ice|cure':     { name:'Mending Frost',  p:0,   e:'holy',   all:1, heal:110, d:'Cool Ether mist soothes!' },
  'thunder|earth':{ name:'Quake Storm',    p:235, e:'earth',  all:1, heal:0,   d:'Earth erupts with lightning!' },
  'thunder|water':{ name:'Electro Wave',   p:240, e:'thunder',all:1, heal:0,   d:'Ether conducts through flood!' },
  'thunder|dark': { name:'Null Lightning', p:280, e:'dark',   all:0, heal:0,   d:'Null and thunder fuse!' },
  'wind|earth':   { name:'Dust Storm',     p:200, e:'earth',  all:1, heal:0,   d:'Razor sand blasts all!' },
  'wind|water':   { name:'Maelstrom',      p:220, e:'water',  all:1, heal:0,   d:'Ether-vortex engulfs all!' },
  'earth|water':  { name:'Mudslide',       p:210, e:'earth',  all:1, heal:0,   d:'Null-mud buries all!' },
  'holy|fire':    { name:'Sacred Flame',   p:260, e:'holy',   all:1, heal:0,   d:'Holy Ether burns Null!' },
  'holy|ice':     { name:'Blessed Frost',  p:250, e:'holy',   all:1, heal:55,  d:'Sacred ice heals and smites!' },
  'holy|dark':    { name:'Twilight Clash', p:295, e:'holy',   all:1, heal:0,   d:'Pure and Null Ether collide!' },
  'guard|cure':   { name:'Ether Bastion',  p:0,   e:'holy',   all:1, heal:165, d:'Restored Ether washes all!' },
}
const C3 = {
  'fire|ice|thunder':  { name:'TRI-ELEMENTAL NOVA',  p:660, e:'plasma',  d:'Three Primals fuse — cataclysm!' },
  'earth|fire|wind':   { name:'VOLCANO STORM',       p:620, e:'fire',    d:'Volcanic Ether storm!' },
  'earth|water|wind':  { name:'ANCIENT CYCLE',       p:580, e:'water',   d:'The ancient Ether triangle!' },
  'fire|thunder|wind': { name:'SKY INFERNO',         p:630, e:'fire',    d:'Lightning-fueled sky fire!' },
  'ice|water|wind':    { name:'GLACIAL STORM',       p:585, e:'ice',     d:'Cataclysmic blizzard-hurricane!' },
  'earth|thunder|wind':{ name:'STORM TITAN',         p:595, e:'thunder', d:'Vaelthar itself rumbles!' },
  'dark|holy|thunder': { name:'DIVINE APOCALYPSE',   p:705, e:'dark',    d:'Pure and Null Ether detonate!' },
  'dark|fire|thunder': { name:'NULL INFERNO',        p:680, e:'dark',    d:'Null-fire and lightning!' },
  'holy|ice|water':    { name:'CELESTIAL TIDE',      p:605, e:'holy',    d:'Sacred Ether washes clean!' },
  'fire|ice|water':    { name:'PRIMORDIAL STEAM',    p:565, e:'steam',   d:'Raw Ether in three forms!' },
}
const getC2 = (a, b) => C2[[a,b].sort().join('|')]
const getC3 = (a, b, c) => C3[[a,b,c].sort().join('|')]
const CELS = new Set(['fire','ice','thunder','wind','earth','water','holy','dark','guard','cure'])

// ─── 32 GUARDIANS (8 elements × 4 tiers) ─────────────────
// Tiers: [0]=Shard (T4), [1]=Echo (T3), [2]=Aspect (T2), [3]=Primal Guardian (T1)
export const EID = {
  fire: [
    { t:4, tl:'SHARD',          name:'Slagwing',  sub:'Ember Shard of Ignareth',     mp:20, p:105, all:0, heal:0, eff:null,         ico:'🦎', d:'Searing claw strike.' },
    { t:3, tl:'ECHO',           name:'Embral',    sub:'Flame Echo of Ignareth',      mp:35, p:188, all:1, heal:0, eff:null,         ico:'💥', sts:{t:'burning',ch:.38,turns:2,dot:16}, d:'Flame Burst — may BURN all!' },
    { t:2, tl:'ASPECT',         name:'Cindara',   sub:'Magma Aspect of Ignareth',    mp:55, p:298, all:1, heal:0, eff:'burn',       ico:'🌋', sts:{t:'burning',ch:.58,turns:3,dot:20}, d:'Magma Rain — Burns all with DoT!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Ignareth',  sub:'The Eternal Flame',           mp:80, p:480, all:1, heal:0, eff:'field_fire', ico:'🔥', sts:{t:'burning',ch:.82,turns:3,dot:26}, d:'HELLFIRE — scorches all existence! Field ignites!' },
  ],
  ice: [
    { t:4, tl:'SHARD',          name:'Rimeling',  sub:'Ice Shard of Glacielle',      mp:20, p:95,  all:0, heal:0, eff:null,         ico:'🌨', d:'Chilling touch.' },
    { t:3, tl:'ECHO',           name:'Crystara',  sub:'Frost Echo of Glacielle',     mp:35, p:180, all:0, heal:0, eff:null,         ico:'💎', sts:{t:'chilled',ch:.50,turns:2}, d:'Crystal Shatter — may Chill!' },
    { t:2, tl:'ASPECT',         name:'Frosthelm', sub:'Blizzard Aspect of Glacielle',mp:55, p:288, all:1, heal:0, eff:'slow',       ico:'🧊', sts:{t:'chilled',ch:.68,turns:2}, d:'Blizzard Storm — Chills all!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Glacielle', sub:'The Still North',             mp:80, p:448, all:1, heal:0, eff:'field_ice',  ico:'❄', sts:{t:'frozen',ch:.72,turns:2}, d:'DIAMOND DUST — Freezes all! Ice field!' },
  ],
  thunder: [
    { t:4, tl:'SHARD',          name:'Cracklit',  sub:'Storm Shard of Torvahk',      mp:20, p:90,  all:0, heal:0, eff:null,           ico:'💫', d:'Static shock.' },
    { t:3, tl:'ECHO',           name:'Volthing',  sub:'Lightning Echo of Torvahk',   mp:35, p:175, all:0, heal:0, eff:null,           ico:'⚡', sts:{t:'stun',ch:.30,turns:1}, d:'Bolt Strike — may Stun!' },
    { t:2, tl:'ASPECT',         name:'Galstrike', sub:'Thunder Aspect of Torvahk',   mp:55, p:270, all:0, heal:0, eff:'stun',         ico:'🌩', sts:{t:'stun',ch:.62,turns:1}, d:'Thunderclap — high Stun chance!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Torvahk',   sub:'The Storm Father',            mp:80, p:438, all:1, heal:0, eff:'field_thunder', ico:'⛈', sts:{t:'stun',ch:.58,turns:1}, d:'JUDGMENT BOLT — Stuns all! Thunder field!' },
  ],
  water: [
    { t:4, tl:'SHARD',          name:'Tricklet',  sub:'Water Shard of Nerevan',      mp:20, p:92,  all:0, heal:0, eff:null,          ico:'💦', d:'Splash attack.' },
    { t:3, tl:'ECHO',           name:'Riplen',    sub:'Current Echo of Nerevan',     mp:35, p:172, all:0, heal:0, eff:null,          ico:'🌊', sts:{t:'wet',ch:.62,turns:2}, d:'Riptide — may apply Wet!' },
    { t:2, tl:'ASPECT',         name:'Undarra',   sub:'Tide Aspect of Nerevan',      mp:55, p:282, all:1, heal:0, eff:'wet',         ico:'🌀', sts:{t:'wet',ch:.88,turns:3}, d:'Whirlpool — soaks ALL! Sets up Ice/Thunder!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Nerevan',   sub:'The Tide Eternal',            mp:80, p:460, all:1, heal:0, eff:'field_water',  ico:'🐍', sts:{t:'wet',ch:1.0,turns:3}, d:'TIDAL WAVE — ALL enemies Wet! Perfect combo setup!' },
  ],
  earth: [
    { t:4, tl:'SHARD',          name:'Peblon',    sub:'Stone Shard of Gorveth',      mp:20, p:88,  all:0, heal:0, eff:null,          ico:'⛏', d:'Rock throw.' },
    { t:3, tl:'ECHO',           name:'Cragg',     sub:'Quake Echo of Gorveth',       mp:35, p:172, all:0, heal:0, eff:null,          ico:'🌍', sts:{t:'knockdown',ch:.35,turns:1}, d:'Tremor — may Knockdown!' },
    { t:2, tl:'ASPECT',         name:'Stonecall', sub:'Earth Aspect of Gorveth',     mp:55, p:275, all:1, heal:0, eff:'defense',     ico:'🪨', stripTemper:60, d:'Stone Wall — strips enemy Temper!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Gorveth',   sub:'The Mountain\'s Will',        mp:80, p:428, all:1, heal:0, eff:'field_earth',  ico:'🏔', sts:{t:'slow',ch:.72,turns:3}, d:'GAIA\'S WRATH — Slows all! Earth field!' },
  ],
  wind: [
    { t:4, tl:'SHARD',          name:'Zephlin',   sub:'Wind Shard of Sylvara',       mp:20, p:85,  all:0, heal:0, eff:null,          ico:'🌬', d:'Breezy strike.' },
    { t:3, tl:'ECHO',           name:'Rustwhip',  sub:'Gale Echo of Sylvara',        mp:35, p:168, all:0, heal:0, eff:null,          ico:'🍃', sts:{t:'blind',ch:.35,turns:2}, d:'Razor Gust — may Blind!' },
    { t:2, tl:'ASPECT',         name:'Galewind',  sub:'Storm Aspect of Sylvara',     mp:55, p:265, all:1, heal:0, eff:'knockback',   ico:'💨', sts:{t:'knockdown',ch:.58,turns:1}, d:'Tempest — Knockdown chance on all!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Sylvara',   sub:'The Sky\'s Voice',            mp:80, p:420, all:1, heal:0, eff:'field_wind',   ico:'🌪', sts:{t:'blind',ch:.68,turns:2}, d:'HURRICANE — Blinds all! Wind field!' },
  ],
  holy: [
    { t:4, tl:'SHARD',          name:'Brightlet', sub:'Light Shard of Luminarch',    mp:20, p:84,  all:0, heal:38, eff:null,          ico:'👼', d:'Blessed touch — heals caster.' },
    { t:3, tl:'ECHO',           name:'Lumikin',   sub:'Holy Echo of Luminarch',      mp:35, p:0,   all:1, heal:120, eff:null,         ico:'💫', sts:{t:'blessed',ch:.50,turns:2}, d:'Light Burst — heals all, may Bless!' },
    { t:2, tl:'ASPECT',         name:'Seraveil',  sub:'Sacred Aspect of Luminarch',  mp:55, p:300, all:1, heal:90,  eff:'protect',    ico:'😇', restoreEther:60, d:'Holy Rain — heals + restores Ether!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Luminarch', sub:'The Sacred Light',            mp:80, p:500, all:1, heal:140, eff:'field_holy',  ico:'🏰', restoreEther:120, purgeAll:1, d:'DIVINE JUDGMENT — heals all, purges Null, Ether restored!' },
  ],
  dark: [
    { t:4, tl:'SHARD',          name:'Shadewraith',sub:'Void Shard of Vaelthorn',    mp:20, p:95,  all:0, heal:0, eff:null,           ico:'👤', d:'Shadow claw.' },
    { t:3, tl:'ECHO',           name:'Umbral',    sub:'Dark Echo of Vaelthorn',      mp:35, p:190, all:0, heal:0, eff:'drain',        ico:'🌑', drainEther:35, d:'Null Pulse — drains HP and Ether!' },
    { t:2, tl:'ASPECT',         name:'Morvath',   sub:'Shadow Aspect of Vaelthorn',  mp:55, p:315, all:0, heal:0, eff:'zantetsuken',  ico:'⚔', sts:{t:'cursed',ch:.45,turns:2,dot:12}, d:'ZANTETSUKEN — 35% instant death! May Curse!' },
    { t:1, tl:'PRIMAL GUARDIAN',name:'Vaelthorn', sub:'The Shadow That Was',         mp:80, p:550, all:1, heal:0, eff:'field_dark',   ico:'🐉', sts:{t:'cursed',ch:.88,turns:3,dot:20}, d:'MEGAFLARE — Curses all survivors! The Dragon King!' },
  ],
}

const SUMMON_REQ = {
  fire:[1,2,3,5], ice:[1,2,4,4], thunder:[2,3,4,5], water:[3,4,5,6],
  earth:[1,3,4,5], wind:[3,3,5,6], holy:[4,4,5,6], dark:[4,4,5,7],
}
const SLV_JP = [0,30,80,165,280,430,620,920]
const sLv = jp => { for (let i=SLV_JP.length-1; i>=0; i--) if (jp>=SLV_JP[i]) return i; return 0 }

// ─── JOB CLASSES ─────────────────────────────────────────
// passive.key is checked in dealDmg and other places
export const JOBS = {
  // ── BASE CLASSES ──
  knight: { name:'Warder',       ico:'⚔',  col:'#e55039', tier:1, jpReq:0,
    passive:null,
    desc:'Sunder strips Temper. Bleed on Slash. Physical specialist.',
    sk:[
      { id:'slash',  n:'Power Slash',   mp:0,  el:'none',  t:'phys',  p:88,  tgt:'e', ico:'⚔', sts:{t:'bleed',ch:.28,turns:2,dot:14} },
      { id:'sunder', n:'Sunder Strike', mp:8,  el:'none',  t:'phys',  p:58,  tgt:'e', ico:'🔨', sunTemper:52 },
      { id:'cover',  n:'Cover',         mp:10, el:'guard', t:'buff',  p:0,   tgt:'a', ico:'🛡', cover:1 },
      { id:'dive',   n:'Lancer Dive',   mp:24, el:'none',  t:'phys',  p:162, tgt:'e', ico:'🌟', sts:{t:'knockdown',ch:.35,turns:1} },
    ]},
  blackmage: { name:'Arcanist',  ico:'🔮', col:'#8e44ad', tier:1, jpReq:0,
    passive:null,
    desc:'Elemental spells. Strips Ether. Core combo engine.',
    sk:[
      { id:'fire',    n:'Firaga',    mp:20, el:'fire',    t:'magic', p:118, tgt:'e', ico:'🔥', sts:{t:'burning',ch:.38,turns:2,dot:18} },
      { id:'ice',     n:'Blizzaga',  mp:20, el:'ice',     t:'magic', p:128, tgt:'e', ico:'❄', sts:{t:'chilled',ch:.42,turns:2} },
      { id:'thunder', n:'Thundaga',  mp:20, el:'thunder', t:'magic', p:108, tgt:'e', ico:'⚡', sts:{t:'stun',ch:.32,turns:1} },
      { id:'flare',   n:'Flare',     mp:44, el:'none',    t:'magic', p:218, tgt:'e', ico:'☀' },
    ]},
  summoner: { name:'Resonant',   ico:'📖', col:'#ffd700', tier:1, jpReq:0,
    passive:null,
    desc:'Bonds with freed Guardians. Summons feed combo chains. Resonate to save corrupted Guardians.',
    sk:[
      { id:'summon',   n:'Summon',     mp:0,  el:'none', t:'summon',  p:0,  tgt:'e', ico:'📖' },
      { id:'aura',     n:'Aura',       mp:18, el:'holy', t:'buff',    p:0,  tgt:'s', ico:'🌟', aura:1 },
      { id:'manaflow', n:'Mana Flow',  mp:0,  el:'cure', t:'special', p:0,  tgt:'s', ico:'💧', manaFlow:1 },
      { id:'echo',     n:'Null Echo',  mp:18, el:'dark', t:'magic',   p:68, tgt:'e', ico:'🔮', sts:{t:'silence',ch:.28,turns:1} },
    ]},
  whitemage: { name:'Luminary',  ico:'💚', col:'#2ecc71', tier:1, jpReq:0,
    passive:null,
    desc:'Restores Temper (Bulwark) and Ether (Veil). Raise revives allies.',
    sk:[
      { id:'curaga',  n:'Curaga',   mp:28, el:'cure',  t:'heal', p:138, tgt:'a', ico:'💚' },
      { id:'protect', n:'Bulwark',  mp:15, el:'guard', t:'buff', p:0,   tgt:'a', ico:'🛡', restoreTemper:60 },
      { id:'shell',   n:'Veil',     mp:15, el:'holy',  t:'buff', p:0,   tgt:'a', ico:'💠', restoreEther:60 },
      { id:'raise',   n:'Raise',    mp:40, el:'holy',  t:'heal', p:0,   tgt:'a', ico:'✨', revive:1 },
    ]},
  dragoon: { name:'Skywarden',   ico:'🐲', col:'#e84393', tier:2, jpReq:200,
    passive:null,
    desc:'Dragon fire strips Ether. Bleed on Fang. Aerial specialist.',
    sk:[
      { id:'djump',   n:'Dragon Jump',    mp:0,  el:'none', t:'phys',  p:175, tgt:'e',   ico:'🐲', sts:{t:'weaken',ch:.40,turns:2} },
      { id:'lancet',  n:'Lancet',         mp:8,  el:'none', t:'phys',  p:90,  tgt:'e',   ico:'🗡', drain:1 },
      { id:'dfang',   n:'Dragon Fang',    mp:18, el:'fire', t:'phys',  p:140, tgt:'e',   ico:'🔥', sts:{t:'bleed',ch:.40,turns:2,dot:16} },
      { id:'dbreath', n:'Dragon Breath',  mp:30, el:'fire', t:'magic', p:220, tgt:'all', ico:'🐉', sts:{t:'burning',ch:.62,turns:2,dot:22} },
    ]},
  timemage: { name:'Chronist',   ico:'⏳', col:'#a29bfe', tier:2, jpReq:200,
    passive:null,
    desc:'Haste, Slow, Stop. Meteor devastates. Bends the Ether of time.',
    sk:[
      { id:'haste',  n:'Haste',  mp:18, el:'wind',  t:'buff',   p:0,   tgt:'a',   ico:'⏩', haste:1 },
      { id:'slow',   n:'Slow',   mp:15, el:'earth', t:'debuff', p:0,   tgt:'e',   ico:'⏱', slow:1 },
      { id:'stop',   n:'Stop',   mp:28, el:'earth', t:'debuff', p:0,   tgt:'e',   ico:'⏸', stop:1 },
      { id:'meteor', n:'Meteor', mp:46, el:'none',  t:'magic',  p:248, tgt:'all', ico:'☄' },
    ]},
  paladin: { name:'Oathbound',   ico:'⚜', col:'#fdcb6e', tier:3, jpReq:450,
    passive:null,
    desc:'Aegis restores Temper and Ether. Dispel purges Null. Holy warrior.',
    sk:[
      { id:'holybld',  n:'Holy Blade', mp:22, el:'holy', t:'magic',   p:158, tgt:'e',   ico:'⚜', sts:{t:'blind',ch:.35,turns:2} },
      { id:'aegis',    n:'Aegis',      mp:16, el:'guard',t:'buff',    p:0,   tgt:'s',   ico:'🛡', restoreTemper:45, restoreEther:45 },
      { id:'judgment', n:'Judgment',   mp:40, el:'holy', t:'magic',   p:238, tgt:'all', ico:'☀' },
      { id:'dispel',   n:'Dispel',     mp:22, el:'holy', t:'special', p:0,   tgt:'a',   ico:'🌟', dispel:1 },
    ]},
  necromancer: { name:'Voidcaller', ico:'💀', col:'#9b59b6', tier:3, jpReq:450,
    passive:null,
    desc:'Drains Ether. Spreads Null Curse. Mirrors the Null Conclave\'s arts.',
    sk:[
      { id:'darkwave', n:'Null Wave',   mp:20, el:'dark', t:'magic', p:138, tgt:'all', ico:'🌑', sts:{t:'cursed',ch:.42,turns:2,dot:12} },
      { id:'drain',    n:'Ether Drain', mp:12, el:'dark', t:'magic', p:98,  tgt:'e',   ico:'💀', drain:1, drainEther:28 },
      { id:'death',    n:'Death',       mp:40, el:'dark', t:'magic', p:0,   tgt:'e',   ico:'☠', instakill:1 },
      { id:'darkArmy', n:'Null Army',   mp:50, el:'dark', t:'magic', p:188, tgt:'all', ico:'🦴', sts:{t:'weaken',ch:.50,turns:2} },
    ]},
  darksummoner: { name:'Null Resonant', ico:'🐉', col:'#c0392b', tier:4, jpReq:800,
    passive:null,
    desc:'Void-touched apex class. Channels Null through Guardian bonds. Path to Vaelthorn.',
    sk:[
      { id:'dsummon', n:'Null Summon',  mp:0,  el:'dark', t:'summon', p:0,   tgt:'e',   ico:'🐉' },
      { id:'megaura', n:'Null Aura',    mp:25, el:'dark', t:'buff',   p:0,   tgt:'s',   ico:'🌑', aura:1 },
      { id:'decho',   n:'Null Echo',    mp:18, el:'dark', t:'magic',  p:88,  tgt:'e',   ico:'💀', drainEther:38, sts:{t:'cursed',ch:.45,turns:2,dot:12} },
      { id:'void',    n:'Void Burst',   mp:55, el:'dark', t:'magic',  p:288, tgt:'all', ico:'🌌', sts:{t:'silence',ch:.55,turns:2} },
    ]},

  // ── ASCENDED CLASSES (800-1200 JP) ──
  nullbreaker: { name:'Null Breaker',    ico:'💀', col:'#ff4757', tier:5, jpReq:800,  base:'knight',
    passive:{ key:'tempStrip', val:18, desc:'All physical hits strip 18 extra Temper.' },
    desc:'Mastered Temper. Every hit cracks armor further. Physical ailments land freely.',
    sk:[
      { id:'slash',   n:'Void Slash',    mp:0,  el:'none',  t:'phys', p:100, tgt:'e',   ico:'⚔', sts:{t:'bleed',ch:.38,turns:2,dot:18} },
      { id:'sunder',  n:'Void Sunder',   mp:8,  el:'none',  t:'phys', p:65,  tgt:'e',   ico:'🔨', sunTemper:80 },
      { id:'cover',   n:'Iron Cover',    mp:10, el:'guard', t:'buff', p:0,   tgt:'a',   ico:'🛡', cover:1 },
      { id:'dive',    n:'Null Dive',     mp:24, el:'none',  t:'phys', p:180, tgt:'e',   ico:'🌟', sts:{t:'knockdown',ch:.50,turns:1} },
      { id:'shatter', n:'Shatter Break', mp:30, el:'earth', t:'phys', p:200, tgt:'e',   ico:'💔', sunTemper:100, sts:{t:'knockdown',ch:.90,turns:1} },
      { id:'tmrwave', n:'Temper Wave',   mp:35, el:'none',  t:'phys', p:85,  tgt:'all', ico:'🌊', sunTemper:40 },
    ]},
  etherweaver: { name:'Etherweaver',     ico:'🌈', col:'#5dade2', tier:5, jpReq:800,  base:'blackmage',
    passive:{ key:'chainExtend', val:3000, desc:'Combo chains last 3 seconds longer (10s total).' },
    desc:'Mastered Ether. Weaves elements into unstoppable chains.',
    sk:[
      { id:'fire',    n:'Firaga+',       mp:20, el:'fire',    t:'magic', p:132, tgt:'e',   ico:'🔥', sts:{t:'burning',ch:.45,turns:2,dot:20} },
      { id:'ice',     n:'Blizzaga+',     mp:20, el:'ice',     t:'magic', p:142, tgt:'e',   ico:'❄', sts:{t:'chilled',ch:.50,turns:2} },
      { id:'thunder', n:'Thundaga+',     mp:20, el:'thunder', t:'magic', p:122, tgt:'e',   ico:'⚡', sts:{t:'stun',ch:.40,turns:1} },
      { id:'flare',   n:'Flare+',        mp:44, el:'none',    t:'magic', p:250, tgt:'e',   ico:'☀' },
      { id:'nullstorm',n:'Null Storm',   mp:55, el:'fire',    t:'magic', p:155, tgt:'all', ico:'🌈', chainHit:1 },
      { id:'thread',  n:'Ether Thread',  mp:18, el:'none',    t:'special',p:0,  tgt:'s',   ico:'🧵', etherThread:1 },
    ]},
  primalbinder: { name:'Primal Binder',  ico:'⭐', col:'#ffd700', tier:5, jpReq:800,  base:'summoner',
    passive:{ key:'summonBoost', val:0.20, desc:'All summon damage +20% permanently.' },
    desc:'True bond with Guardians. Grand Summon calls two at once.',
    sk:[
      { id:'summon',     n:'Summon',       mp:0,  el:'none', t:'summon',  p:0, tgt:'e', ico:'📖' },
      { id:'grandsummon',n:'Grand Summon', mp:0,  el:'none', t:'summon',  p:0, tgt:'e', ico:'⭐', grandSummon:1 },
      { id:'aura',       n:'Primal Aura',  mp:18, el:'holy', t:'buff',    p:0, tgt:'s', ico:'🌟', aura:1 },
      { id:'bondoath',   n:'Bond Oath',    mp:28, el:'holy', t:'buff',    p:0, tgt:'party', ico:'🤝', partyAura:1 },
      { id:'manaflow',   n:'Mana Flow',    mp:0,  el:'cure', t:'special', p:0, tgt:'s', ico:'💧', manaFlow:1 },
      { id:'echo',       n:'Null Echo',    mp:18, el:'dark', t:'magic',   p:80,tgt:'e', ico:'🔮', sts:{t:'silence',ch:.35,turns:1} },
    ]},
  seraph: { name:'Seraph',               ico:'😇', col:'#ffeaa7', tier:5, jpReq:800,  base:'whitemage',
    passive:{ key:'healTemper', val:35, desc:'All healing also restores 35 Temper to the target.' },
    desc:'Every cure also fortifies Temper. Sanctuary grants party phase-shield.',
    sk:[
      { id:'curaga',    n:'Mega Curaga',    mp:28, el:'cure',  t:'heal', p:200, tgt:'a',     ico:'💚' },
      { id:'holynova',  n:'Holy Nova',      mp:35, el:'holy',  t:'heal', p:100, tgt:'party', ico:'✨', healAll:1 },
      { id:'protect',   n:'Grand Bulwark',  mp:15, el:'guard', t:'buff', p:0,   tgt:'a',     ico:'🛡', restoreTemper:90 },
      { id:'shell',     n:'Grand Veil',     mp:15, el:'holy',  t:'buff', p:0,   tgt:'a',     ico:'💠', restoreEther:90 },
      { id:'raise',     n:'Rebirth',        mp:40, el:'holy',  t:'heal', p:0,   tgt:'a',     ico:'✨', revive:1, fullRevive:1 },
      { id:'sanctuary', n:'Sanctuary',      mp:50, el:'holy',  t:'buff', p:0,   tgt:'party', ico:'🏰', sanctuary:1 },
    ]},
  skysovereign: { name:'Sky Sovereign',  ico:'🐲', col:'#e84393', tier:5, jpReq:900,  base:'dragoon',
    passive:{ key:'critBoost', val:0.20, desc:'Physical critical hit chance +20%.' },
    desc:'Dragon king. Sky Chain hits five times. Dragonscale hardens the party.',
    sk:[
      { id:'djump',      n:'Sovereign Jump', mp:0,  el:'none',  t:'phys',  p:195, tgt:'e',     ico:'🐲', sts:{t:'weaken',ch:.50,turns:2} },
      { id:'lancet',     n:'Lancet+',        mp:8,  el:'none',  t:'phys',  p:108, tgt:'e',     ico:'🗡', drain:1 },
      { id:'dfang',      n:'Dragon Fang+',   mp:18, el:'fire',  t:'phys',  p:155, tgt:'e',     ico:'🔥', sts:{t:'bleed',ch:.50,turns:2,dot:18} },
      { id:'dbreath',    n:'Dragon Roar',    mp:30, el:'fire',  t:'magic', p:242, tgt:'all',   ico:'🐉', sts:{t:'burning',ch:.70,turns:3,dot:24} },
      { id:'skychain',   n:'Sky Chain',      mp:40, el:'wind',  t:'phys',  p:80,  tgt:'e',     ico:'💨', skyChain:5 },
      { id:'dragonscale',n:'Dragonscale',    mp:22, el:'earth', t:'buff',  p:0,   tgt:'party', ico:'🛡', partyTemper:55 },
    ]},
  nullchrono: { name:'Null Chronomancer',ico:'⏳', col:'#a29bfe', tier:5, jpReq:900,  base:'timemage',
    passive:{ key:'startHaste', val:1, desc:'Party begins every wave with Haste active.' },
    desc:'Time is a weapon. Timestop freezes all 4 turns. Phase Shift makes ally untargetable.',
    sk:[
      { id:'haste',    n:'Null Haste',   mp:18, el:'wind',  t:'buff',   p:0,   tgt:'a',   ico:'⏩', haste:1 },
      { id:'slow',     n:'Null Slow',    mp:15, el:'earth', t:'debuff', p:0,   tgt:'e',   ico:'⏱', slow:1 },
      { id:'stop',     n:'Null Stop',    mp:28, el:'earth', t:'debuff', p:0,   tgt:'e',   ico:'⏸', stop:1 },
      { id:'meteor',   n:'Null Meteor',  mp:46, el:'none',  t:'magic',  p:275, tgt:'all', ico:'☄' },
      { id:'timestop', n:'Timestop',     mp:55, el:'earth', t:'debuff', p:0,   tgt:'all', ico:'⌛', timestop:1 },
      { id:'pshift',   n:'Phase Shift',  mp:32, el:'wind',  t:'buff',   p:0,   tgt:'a',   ico:'👁', phaseShift:1 },
    ]},
  radiantkeeper: { name:'Radiant Keeper',ico:'⚜', col:'#fdcb6e', tier:5, jpReq:950, base:'paladin',
    passive:{ key:'holyEtherRestore', val:18, desc:'Holy hits restore 18 Ether to self.' },
    desc:'Sanctum creates a holy field. Radiant Edge smites all. Divine guardian.',
    sk:[
      { id:'holybld',  n:'Radiant Blade',  mp:22, el:'holy', t:'magic',   p:178, tgt:'e',     ico:'⚜', sts:{t:'blind',ch:.45,turns:2} },
      { id:'aegis',    n:'Grand Aegis',    mp:16, el:'guard', t:'buff',   p:0,   tgt:'s',     ico:'🛡', restoreTemper:70, restoreEther:70 },
      { id:'judgment', n:'Grand Judgment', mp:40, el:'holy', t:'magic',   p:268, tgt:'all',   ico:'☀' },
      { id:'dispel',   n:'Null Purge',     mp:22, el:'holy', t:'special', p:0,   tgt:'party', ico:'🌟', dispelAll:1 },
      { id:'radedge',  n:'Radiant Edge',   mp:48, el:'holy', t:'magic',   p:188, tgt:'all',   ico:'✨', holyHeal:50 },
      { id:'sanctum',  n:'Sanctum',        mp:35, el:'holy', t:'special', p:0,   tgt:'s',     ico:'🏰', setField:'holy' },
    ]},
  nullarchon: { name:'Null Archon',      ico:'💀', col:'#9b59b6', tier:5, jpReq:950, base:'necromancer',
    passive:{ key:'darkEtherDrain', val:22, desc:'All dark magic hits drain 22 Ether automatically.' },
    desc:'Master of Null. Void Shackle applies 3 debuffs. Archon\'s Mark amplifies all damage.',
    sk:[
      { id:'darkwave', n:'Archon\'s Wave', mp:20, el:'dark', t:'magic',   p:158, tgt:'all', ico:'🌑', sts:{t:'cursed',ch:.52,turns:2,dot:15} },
      { id:'drain',    n:'Soul Drain',     mp:12, el:'dark', t:'magic',   p:112, tgt:'e',   ico:'💀', drain:1, drainEther:40 },
      { id:'death',    n:'Null Death',     mp:40, el:'dark', t:'magic',   p:0,   tgt:'e',   ico:'☠', instakill:1 },
      { id:'darkArmy', n:'Archon\'s Army', mp:50, el:'dark', t:'magic',   p:208, tgt:'all', ico:'🦴', sts:{t:'weaken',ch:.60,turns:2} },
      { id:'shackle',  n:'Void Shackle',   mp:38, el:'dark', t:'special', p:0,   tgt:'e',   ico:'⛓', voidShackle:1 },
      { id:'mark',     n:'Archon\'s Mark', mp:30, el:'dark', t:'special', p:0,   tgt:'e',   ico:'🎯', archonMark:1 },
    ]},
  vaelthornsvoice: { name:'Vaelthorn\'s Voice', ico:'🐉', col:'#c0392b', tier:5, jpReq:1200, base:'darksummoner',
    passive:{ key:'darkSummonBoost', val:0.40, desc:'Dark Guardian summons deal +40% damage.' },
    desc:'Vaelthorn speaks through this vessel. Calls all dark Guardians simultaneously.',
    sk:[
      { id:'dsummon', n:'Void Summon',         mp:0,  el:'dark', t:'summon', p:0,   tgt:'e',   ico:'🐉' },
      { id:'megaura', n:'Void Aura',           mp:25, el:'dark', t:'buff',   p:0,   tgt:'s',   ico:'🌑', aura:1 },
      { id:'darkgate',n:'Dark Gate',           mp:35, el:'dark', t:'special',p:0,   tgt:'s',   ico:'🚪', setField:'dark' },
      { id:'vbreath', n:'Vaelthorn\'s Breath', mp:55, el:'dark', t:'magic',  p:320, tgt:'all', ico:'🌑', sts:{t:'cursed',ch:.65,turns:3,dot:22} },
      { id:'soulrend',n:'Soul Rend',           mp:48, el:'dark', t:'magic',  p:0,   tgt:'e',   ico:'💀', instakill:1, curseSurvivors:1 },
      { id:'void',    n:'Void Burst+',         mp:55, el:'dark', t:'magic',  p:320, tgt:'all', ico:'🌌', sts:{t:'silence',ch:.65,turns:2} },
    ]},
}

// ─── LIMIT BREAK DATA ────────────────────────────────────
export const LB = {
  knight:          { n:'TEMPER BREAK',          ico:'🔥', col:'#e55039', desc:'3 strikes on all, each strips 45 Temper!' },
  blackmage:       { n:'ELEMENTAL MAELSTROM',   ico:'🌈', col:'#8e44ad', desc:'Fire+Ice+Thunder → auto-forces TRI-NOVA!' },
  summoner:        { n:'GRAND RESONANCE',       ico:'⭐', col:'#ffd700', desc:'Call the strongest available Guardian, no MP!' },
  whitemage:       { n:'ASTRAL LIGHT',          ico:'✨', col:'#2ecc71', desc:'Full HP, max Ether, ailments purged, Blessed!' },
  dragoon:         { n:'DRAGON KING\'S WRATH',  ico:'🐉', col:'#e84393', desc:'5 dragon fire hits on all enemies!' },
  timemage:        { n:'CHRONOSTASIS',          ico:'⏸', col:'#a29bfe', desc:'Stop ALL enemies 3 turns + Haste party!' },
  paladin:         { n:'SACRED JUDGMENT',       ico:'⚜', col:'#fdcb6e', desc:'Triple Judgment + full Temper/Ether + Blessed!' },
  necromancer:     { n:'NULL FLOOD',            ico:'💀', col:'#9b59b6', desc:'Drain all enemy Ether → restore party, curse all!' },
  darksummoner:    { n:'VAELTHORN\'S CALL',     ico:'🐉', col:'#c0392b', desc:'Summon Vaelthorn regardless of Resonant level!' },
  nullbreaker:     { n:'TOTAL SHATTER',         ico:'💔', col:'#ff4757', desc:'Strip ALL enemy Temper to 0, then 4 heavy hits!' },
  etherweaver:     { n:'ARCANE MAELSTROM',      ico:'🌈', col:'#5dade2', desc:'All 8 elements hit all enemies — every combo fires!' },
  primalbinder:    { n:'PRIMAL CONVERGENCE',    ico:'⭐', col:'#ffd700', desc:'All unlocked T1 Guardians strike simultaneously!' },
  seraph:          { n:'ASCENSION',             ico:'✨', col:'#ffeaa7', desc:'Full HP+Temper+Ether, purge all, Blessed, Regen 3t!' },
  skysovereign:    { n:'WYRM KING',             ico:'🐲', col:'#e84393', desc:'7 dragon hits + fire field + party Dragonscale!' },
  nullchrono:      { n:'TEMPORAL COLLAPSE',     ico:'⌛', col:'#a29bfe', desc:'Stop all 4 turns + party double ATB speed!' },
  radiantkeeper:   { n:'DIVINE SANCTUM',        ico:'⚜', col:'#fdcb6e', desc:'Holy field 4t + triple Temper/Ether + Blind all!' },
  nullarchon:      { n:'NULL APOCALYPSE',       ico:'💀', col:'#9b59b6', desc:'Void Shackle all + drain all Ether + max party Ether!' },
  vaelthornsvoice: { n:'NULL GENESIS',          ico:'🐉', col:'#c0392b', desc:'Vaelthorn + all dark Guardians strike simultaneously!' },
}

// ─── ITEMS (Vaelthar vocabulary) ────────────────────────
const ITEM_DEFS = {
  vitaedraught:  { name:'Vitae Draught',   ico:'🧪', col:'#2ecc71', desc:'Restore 200 HP to one ally.',        tgt:'a' },
  resonphial:    { name:'Resonance Phial', ico:'💠', col:'#9b59b6', desc:'Restore 90 Ether to one ally.',      tgt:'a' },
  ironcoreshard: { name:'Ironcore Shard',  ico:'🟧', col:'#fd9644', desc:'Restore 90 Temper to one ally.',     tgt:'a' },
  soulmber:      { name:'Soul Ember',      ico:'🔮', col:'#ff6b35', desc:'Revive KO\'d ally at 60% HP.',        tgt:'a_ko' },
  nullbane:      { name:'Null Bane',       ico:'✨', col:'#ffd700', desc:'Cleanse ALL statuses from one ally.', tgt:'a' },
}

// ─── ENEMY WAVES ────────────────────────────────────────
// Waves 1-2: Null-corrupted creatures
// Waves 3-4: Named corrupted Guardians (Resonance Window available)
// Wave 5:    Omega Null — crystallized Ether, the source weapon
const WAVES = [
  [{ id:'e0', name:'Null Drake',    mhp:680,  hp:680,  temper:55,  mtemper:55,  ether:70,  mether:70,
     weakTo:['holy','wind'], resistTo:['dark'],
     atb:0, spd:.50, str:52, mag:40, def:28, col:'#8e44ad', rwd:35, jp:18, statuses:[], floats:[],
     sk:[{ n:'Shadow Bite', p:78,  t:'phys',  a:0, sts:{t:'bleed',  ch:.30,turns:2,dot:12} },
         { n:'Null Breath', p:98,  t:'magic', a:1, sts:{t:'silence',ch:.35,turns:2} }] }],

  [{ id:'e0', name:'Void Golem',    mhp:560,  hp:560,  temper:95,  mtemper:95,  ether:38,  mether:38,
     weakTo:['fire','thunder'], resistTo:['ice','earth'],
     atb:0, spd:.40, str:65, mag:30, def:50, col:'#74b9ff', rwd:28, jp:14, statuses:[], floats:[],
     sk:[{ n:'Frost Crush', p:90, t:'phys',  a:0, sts:{t:'chilled',ch:.45,turns:2} },
         { n:'Chill Aura',  p:55, t:'magic', a:1, sts:{t:'slow',   ch:.50,turns:2} }] },
   { id:'e1', name:'Storm Imp',     mhp:390,  hp:390,  temper:22,  mtemper:22,  ether:82,  mether:82,
     weakTo:['earth','ice'], resistTo:['thunder'],
     atb:30, spd:.90, str:35, mag:62, def:18, col:'#fdcb6e', rwd:22, jp:12, statuses:[], floats:[],
     sk:[{ n:'Bolt Strike', p:85, t:'magic', a:0, sts:{t:'stun', ch:.32,turns:1} },
         { n:'Wet Shock',   p:50, t:'magic', a:1, applyWet:1, sts:{t:'blind',ch:.38,turns:2} }] }],

  [{ id:'e0', name:'Ignareth [ENRAGED]', isGuardian:1,
     mhp:1020, hp:1020, temper:88, mtemper:88, ether:72, mether:72,
     weakTo:['water','ice'], resistTo:['fire','earth'],
     lore:'The fire Guardian. A Void Anchor drives pain through its every thought.',
     atb:0, spd:.45, str:75, mag:62, def:46, col:'#ff6b35', rwd:55, jp:28, statuses:[], floats:[],
     sk:[{ n:'Hellfire Strike', p:102, t:'phys',  a:0, sts:{t:'bleed',  ch:.35,turns:2,dot:16} },
         { n:'Null Eruption',   p:118, t:'magic', a:1, sts:{t:'burning',ch:.58,turns:2,dot:22} }] },
   { id:'e1', name:'Null Shade',    mhp:680,  hp:680,  temper:38,  mtemper:38,  ether:90,  mether:90,
     weakTo:['holy','thunder'], resistTo:['dark'],
     atb:10, spd:.70, str:55, mag:80, def:30, col:'#6c5ce7', rwd:38, jp:18, statuses:[], floats:[],
     sk:[{ n:'Ether Drain', p:80,  t:'magic', a:0, drain:1, drainEther:30, sts:{t:'weaken',ch:.40,turns:2} },
         { n:'Null Pulse',  p:102, t:'magic', a:1, sts:{t:'silence',ch:.42,turns:2} }] }],

  [{ id:'e0', name:'Nerevan [ENRAGED]', isGuardian:1,
     mhp:880, hp:880, temper:72, mtemper:72, ether:88, mether:88,
     weakTo:['thunder','wind'], resistTo:['fire','water'],
     lore:'The tide Guardian. Its Void Anchor floods its domain with Null-water.',
     atb:0, spd:.55, str:62, mag:74, def:36, col:'#0984e3', rwd:52, jp:28, statuses:[], floats:[],
     sk:[{ n:'Tidal Crash', p:92,  t:'phys',  a:0, applyWet:1 },
         { n:'Null Tide',   p:118, t:'magic', a:1, sts:{t:'slow',ch:.52,turns:2} }] },
   { id:'e1', name:'Sylvara [ENRAGED]', isGuardian:1,
     mhp:720, hp:720, temper:42, mtemper:42, ether:78, mether:78,
     weakTo:['ice','earth'], resistTo:['wind'],
     lore:'The sky Guardian. Its screams create Null-winds that blind everything.',
     atb:20, spd:.80, str:46, mag:84, def:22, col:'#00cec9', rwd:45, jp:24, statuses:[], floats:[],
     sk:[{ n:'Null Gale',    p:88,  t:'magic', a:0, sts:{t:'blind',    ch:.40,turns:2} },
         { n:'Storm Pulse',  p:102, t:'magic', a:1, sts:{t:'knockdown',ch:.44,turns:1} }] },
   { id:'e2', name:'Luminarch [CORRUPTED]', isGuardian:1,
     mhp:640, hp:640, temper:65, mtemper:65, ether:92, mether:92,
     weakTo:['dark','fire'], resistTo:['holy'],
     lore:'The sacred Guardian. Corrupting holy Ether was the Null Conclave\'s cruelest act.',
     atb:10, spd:.65, str:52, mag:70, def:42, col:'#ffeaa7', rwd:42, jp:22, statuses:[], floats:[],
     sk:[{ n:'Null Light',    p:92,  t:'magic', a:0, sts:{t:'cursed',ch:.42,turns:2,dot:14} },
         { n:'Null Judgment', p:112, t:'magic', a:1, sts:{t:'weaken',ch:.48,turns:2} }] }],

  [{ id:'e0', name:'OMEGA NULL',
     mhp:4000, hp:4000, temper:188, mtemper:188, ether:188, mether:188,
     weakTo:['holy'], resistTo:['dark','fire'],
     atb:0, spd:.58, str:92, mag:94, def:58, col:'#c0392b', rwd:280, jp:150,
     statuses:[], floats:[], regenEther:14,
     sk:[
       { n:'Omega Ray',     p:138, t:'magic', a:1, stripEther:55,  sts:{t:'burning',ch:.70,turns:3,dot:22} },
       { n:'Gravity Well',  p:115, t:'phys',  a:1, stripTemper:55, sts:{t:'slow',   ch:.75,turns:3} },
       { n:'Temporal Crush',p:100, t:'phys',  a:0, sts:{t:'stun',  ch:.62,turns:2} },
       { n:'Null Surge',    p:80,  t:'magic', a:1, stripEther:40,  sts:{t:'silence',ch:.65,turns:2} },
       { n:'Null Embrace',  p:90,  t:'magic', a:0, drain:1, drainEther:55, sts:{t:'cursed',ch:.58,turns:2,dot:18} },
     ]}],
]

// ─── INITIAL STATE ────────────────────────────────────────
function mkParty() {
  return [
    { id:'kael', name:'Kael', job:'knight',    hp:395, mhp:395, mp:95,  mmp:95,  temper:112, mtemper:112, ether:52,  mether:52,  limit:0, atb:20, spd:.65, str:52, mag:24, def:38, col:'#e55039', guard:0, haste:0, aura:0, statuses:[], floats:[] },
    { id:'lyra', name:'Lyra', job:'blackmage', hp:248, mhp:248, mp:188, mmp:188, temper:42,  mtemper:42,  ether:118, mether:118, limit:0, atb:40, spd:1.0, str:18, mag:78, def:18, col:'#5dade2', guard:0, haste:0, aura:0, statuses:[], floats:[] },
    { id:'zane', name:'Zane', job:'summoner',  hp:312, mhp:312, mp:132, mmp:132, temper:62,  mtemper:62,  ether:88,  mether:88,  limit:0, atb:60, spd:1.2, str:42, mag:42, def:24, col:'#ffd700', guard:0, haste:0, aura:0, statuses:[], floats:[] },
    { id:'nova', name:'Nova', job:'whitemage', hp:268, mhp:268, mp:208, mmp:208, temper:48,  mtemper:48,  ether:108, mether:108, limit:0, atb:50, spd:.95, str:16, mag:70, def:20, col:'#2ecc71', guard:0, haste:0, aura:0, statuses:[], floats:[] },
  ]
}

function freshState() {
  return {
    party: mkParty(),
    enemies: JSON.parse(JSON.stringify(WAVES[0])),
    wave: 0, gold: 0, totalJP: 0,
    items: { vitaedraught:3, resonphial:2, ironcoreshard:2, soulmber:2, nullbane:1 },
    log: [
      '⚔ Battle begins! Null Drake approaches!',
      '🟧 TEMPER = physical defense | 🟪 ETHER = magic defense',
      '⚡ SURGE: click the button when it flashes to boost your hits!',
      '🛡 DEFLECT: click before enemy hits to halve their damage!',
      '⚡ Thunder=4 fast hits | ❄ Ice=1 big hit | 🔥 Fire=3 medium',
    ],
    phase: 'battle',
    activeChar: null, pendingSkill: null, itemMode: false,
    comboChain: [], comboResult: null,
    summonAnim: null, fieldEffect: null,
    resonanceWindow: null,
    enemyActing: 0, summonTab: 'fire', jobScreenChar: null,
    // Timing system
    surgeWin: null,      // { type, deadline, duration, col, label, hitNum, totalHits, charId, clicked }
    _postHitFn: null,    // called after all hits resolve
    _deflecting: false,  // deflect was clicked?
  }
}

// ─── SMALL COMPONENTS ────────────────────────────────────
const Bar = ({ v, m, h=7, col }) => {
  const pct = Math.max(0, Math.min(100, m > 0 ? v/m*100 : 0))
  const c = col === 'hp' ? (pct > 50 ? '#2ecc71' : pct > 25 ? '#f39c12' : '#e74c3c') : col
  return (
    <div style={{ background:'#0a0a1a', height:h, overflow:'hidden' }}>
      <div style={{ width:`${pct}%`, height:'100%', background:c, transition:'width .22s' }} />
    </div>
  )
}

const StatusIcons = ({ statuses=[] }) => {
  if (!statuses.length) return null
  return (
    <div style={{ display:'flex', gap:2, flexWrap:'wrap', marginTop:2 }}>
      {statuses.map((s, i) => {
        const d = SD[s.type] || { ico:'?', col:'#888' }
        return <span key={i} style={{ fontSize:9, color:d.col }}>{d.ico}<span style={{ fontSize:5, color:'#555' }}>{s.turnsLeft}</span></span>
      })}
    </div>
  )
}

const TEBars = ({ temper, mtemper, ether, mether }) => (
  <div style={{ display:'flex', gap:3, marginTop:2 }}>
    <div style={{ flex:1 }}>
      <div style={{ fontSize:4, color:'#fd9644' }}>TMP {temper}</div>
      <div style={{ background:'#0a0a1a', height:4 }}>
        <div style={{ width:`${mtemper > 0 ? Math.max(0, temper/mtemper*100) : 0}%`, height:'100%', background:'#fd9644', transition:'width .2s' }} />
      </div>
    </div>
    <div style={{ flex:1 }}>
      <div style={{ fontSize:4, color:'#9b59b6' }}>ETH {ether}</div>
      <div style={{ background:'#0a0a1a', height:4 }}>
        <div style={{ width:`${mether > 0 ? Math.max(0, ether/mether*100) : 0}%`, height:'100%', background:'#9b59b6', transition:'width .2s' }} />
      </div>
    </div>
  </div>
)

function CharSprite({ col, isDead, isReady, isActive, guard, aura }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', position:'relative',
      opacity: isDead ? .18 : 1,
      filter: aura ? `drop-shadow(0 0 8px #ffd700)` : isActive ? `drop-shadow(0 0 12px ${col})` : 'none',
      transition:'all .3s' }}>
      <div style={{ width:16, height:16, background:col, border:'2px solid rgba(255,255,255,.2)' }} />
      <div style={{ width:22, height:20, background:col, marginTop:2, clipPath:'polygon(18% 0%,82% 0%,100% 100%,0% 100%)', filter:'brightness(.8)' }} />
      <div style={{ display:'flex', gap:3, marginTop:2 }}>
        <div style={{ width:9, height:14, background:`${col}bb` }} />
        <div style={{ width:9, height:14, background:`${col}bb` }} />
      </div>
      {guard && <div style={{ position:'absolute', right:-10, top:8, fontSize:11 }}>🛡</div>}
      {isReady && !isDead && <div style={{ fontSize:5, color:'#ffd700', animation:'blink .6s steps(1) infinite', fontFamily:"'Press Start 2P',monospace" }}>▶</div>}
    </div>
  )
}

// ═══════════════════════════════════════════════════════════
// MAIN GAME COMPONENT
// ═══════════════════════════════════════════════════════════
export default function VaeltharChronicles() {
  const gs = useRef(freshState())
  const [, setT] = useState(0)
  const render = () => setT(t => t + 1)

  // ── STATUS HELPERS ──
  const hasS = (e, t) => (e.statuses || []).some(s => s.type === t && s.turnsLeft > 0)
  const remS = (e, t) => { e.statuses = (e.statuses || []).filter(s => s.type !== t) }
  const addS = (e, type, turns, extra={}) => { remS(e, type); e.statuses = [...(e.statuses || []), { type, turnsLeft: turns, ...extra }] }

  function tryS(target, type, baseChance, turns=2, aF=1) {
    const def = SD[type]; if (!def) return false
    const armor = def.mag ? (target.ether||0) : (target.temper||0)
    const maxA  = def.mag ? (target.mether||1) : (target.mtemper||1)
    if (Math.random() < baseChance * (1 - armor/maxA * 0.85) * aF) {
      addS(target, type, turns, { dot: def.dot }); return true
    }
    return false
  }

  function doLog(msg) { const g = gs.current; g.log = [...g.log.slice(-24), msg] }

  function addFloat(entity, text, col, size=11) {
    if (!entity) return
    const id = `${Date.now()}_${Math.random().toString(36).slice(2)}`
    entity.floats = [...(entity.floats || []), { id, text, col, size }]
    setTimeout(() => { if (entity.floats) entity.floats = entity.floats.filter(f => f.id !== id); render() }, 1600)
  }

  function stripArmorF(target, dmg, isMag) {
    const strip = Math.max(4, Math.floor(dmg * 0.22))
    const k = isMag ? 'ether' : 'temper'
    const was = target[k] || 0
    target[k] = Math.max(0, was - strip)
    return was > 0 && target[k] === 0 ? k : null
  }

  function checkReact(target, element) {
    for (const s of target.statuses || []) {
      const k = `${s.type}+${element}`; if (REACT[k]) return { ...REACT[k], _ct: s.type }
    }
    return null
  }

  function tickStatuses(entity) {
    if (!entity.statuses) return
    entity.statuses = entity.statuses.map(s => {
      const def = SD[s.type] || {}
      if ((s.dot || def.dot || 0) > 0) {
        const d = s.dot || def.dot || 0; entity.hp = Math.max(0, entity.hp - d)
        addFloat(entity, `-${d}`, def.col || '#e74c3c', 9)
      }
      if (def.healPct) { const h = Math.floor(entity.mhp * (def.healPct||0)); entity.hp = Math.min(entity.mhp, entity.hp + h) }
      return { ...s, turnsLeft: s.turnsLeft - 1 }
    }).filter(s => s.turnsLeft > 0)
  }

  function checkResonanceWindow(target) {
    const g = gs.current
    if (!target.isGuardian || target.hp <= 0 || g.resonanceWindow) return
    if (target.hp / target.mhp <= 0.20) {
      g.resonanceWindow = { guardianId: target.id, attempts: 0 }
      doLog(`💜 VOID ANCHOR EXPOSED! ${target.name}'s true Ether shines through!`)
      doLog(`📖 RESONATE to free them! Resonant job: 82% | Aura boosts success!`)
    }
  }

  // ── SURGE CLICK ──
  function handleSurge() {
    const g = gs.current; if (!g.surgeWin || g.surgeWin.clicked) return
    g.surgeWin.clicked = true
    if (g.surgeWin.type === 'deflect') {
      const t = g.party.find(p => p.hp > 0); if (t) addFloat(t, 'DEFLECT!', '#5dade2', 13)
    } else {
      const m = g.party.find(p => p.id === g.surgeWin.charId); if (m) addFloat(m, 'SURGE!', '#ffd700', 13)
    }
    render()
  }

  // ── CORE DAMAGE ENGINE ──────────────────────────────────
  function dealDmg(attacker, power, type, target, element, skillSts, extraMult=1) {
    const isMag = type === 'magic'
    if (hasS(attacker, 'blind') && Math.random() < .50) { addFloat(attacker, 'MISS!', '#888', 9); doLog(`👁 ${attacker.name} missed!`); return 0 }
    const base = isMag ? attacker.mag : attacker.str
    let dmg = Math.max(1, Math.floor((power + base*1.5 - (target.def||20)*.7) * (.85 + Math.random()*.3)))
    if (hasS(attacker, 'weaken')) dmg = Math.floor(dmg * .75)
    if (hasS(attacker, 'berserk')) dmg = Math.floor(dmg * 1.5)

    // Crit
    const job = JOBS[attacker.job]
    let critChance = 0.15 + (attacker.spd||0) * 0.005
    if (job?.passive?.key === 'critBoost') critChance += job.passive.val
    const isCrit = Math.random() < critChance
    if (isCrit) dmg = Math.floor(dmg * 1.55)

    // Weakness / Resist / Absorb
    let weakStr = ''
    if (element !== 'none' && element !== 'guard' && element !== 'cure') {
      if (target.absorbEl?.includes(element)) { target.hp = Math.min(target.mhp, target.hp + dmg); addFloat(target, `+${dmg} ABS!`, '#2ecc71'); doLog(`   ✦ ${target.name} ABSORBS ${element}!`); return 0 }
      if (target.weakTo?.includes(element))   { dmg = Math.floor(dmg * 1.60); weakStr = 'WEAK!' }
      else if (target.resistTo?.includes(element)) { dmg = Math.floor(dmg * 0.60); weakStr = 'RES' }
    }
    if (target.archonMarked) dmg = Math.floor(dmg * 1.5)

    // Surface reaction
    const react = checkReact(target, element); let rMult = 1
    if (react) {
      doLog(`✦ ${react.name} — ${react.msg}`); rMult = react.bonus || 1
      if (react._ct) remS(target, react._ct)
      if (react.applyWet) addS(target, 'wet', 2)
      if (react.healParty) { const g2=gs.current; g2.party.forEach(m=>{if(m.hp>0){m.hp=Math.min(m.mhp,m.hp+(react.healParty||0));addFloat(m,`+${react.healParty}`,'#2ecc71')}}); doLog(`   💚 Party +${react.healParty} HP!`) }
      if (react.drainEther) { target.ether = Math.max(0,(target.ether||0)-(react.drainEther||0)); doLog(`   🟪 Ether -${react.drainEther}!`) }
      if (react.shatterArmor) { const sa=Math.floor(dmg*react.shatterArmor); target.temper=Math.max(0,(target.temper||0)-sa); target.ether=Math.max(0,(target.ether||0)-sa); doLog(`   💔 ARMOR SHATTERED! -${sa} both!`) }
      if (react.sts) { if (tryS(target, react.sts.t, react.sts.ch||.7, react.sts.turns||2, react.aF||1)) doLog(`   ${SD[react.sts.t]?.ico||'✦'} ${target.name}: ${react.sts.t.toUpperCase()}!`) }
    }

    // Field bonus
    const g = gs.current
    const fB = g.fieldEffect && g.fieldEffect.type === element ? 1.38 : 1
    const armor = isMag ? (target.ether||0) : (target.temper||0)
    const maxA  = isMag ? (target.mether||1) : (target.mtemper||1)
    const armorPct = maxA > 0 ? armor/maxA : 0
    const breakBonus = armor === 0 ? 1.15 : 1
    dmg = Math.max(1, Math.floor(dmg * rMult * extraMult * fB * (1 - armorPct*.18) * breakBonus))
    target.hp = Math.max(0, target.hp - dmg)

    // Float
    const floatCol = isCrit ? '#ffd700' : weakStr==='WEAK!' ? '#ff6b35' : weakStr==='RES' ? '#888' : isMag ? '#a29bfe' : '#e74c3c'
    addFloat(target, `${isCrit?'★':weakStr==='WEAK!'?'⚡':weakStr==='RES'?'▽':''}${dmg}`, floatCol, isCrit?13:weakStr==='WEAK!'?12:10)
    if (isCrit) doLog(`   ✦ CRITICAL! ${dmg}!`)
    if (weakStr === 'WEAK!') doLog(`   ⚡ WEAKNESS! ${element.toUpperCase()} hits hard!`)
    if (breakBonus > 1 && !isCrit) doLog(`   💔 BREAK BONUS +15%!`)

    // Passives
    if (!isMag && job?.passive?.key === 'tempStrip') target.temper = Math.max(0, (target.temper||0) - (job.passive.val||0))
    if (element === 'dark' && job?.passive?.key === 'darkEtherDrain') target.ether = Math.max(0, (target.ether||0) - (job.passive.val||0))
    if (element === 'holy' && job?.passive?.key === 'holyEtherRestore') attacker.ether = Math.min(attacker.mether, (attacker.ether||0) + (job.passive.val||0))

    const broken = stripArmorF(target, dmg, isMag)
    if (broken === 'ether')  doLog(`🟪 ${target.name}'s ETHER collapsed! Magic unguarded!`)
    if (broken === 'temper') doLog(`🟧 ${target.name}'s TEMPER shattered! Physical unguarded!`)

    if (skillSts && !react?.sts) { if (tryS(target, skillSts.t, skillSts.ch||.3, skillSts.turns||2)) doLog(`   ${SD[skillSts.t]?.ico||'✦'} ${target.name}: ${skillSts.t.toUpperCase()}!`) }

    checkResonanceWindow(target)
    return dmg
  }

  // ── HIT CHAIN SYSTEM ─────────────────────────────────────
  // Processes hits one at a time with a SURGE timing window per hit
  function buildHits(m, skill, targetId, extraMult=1) {
    const el = skill.el || 'none'
    const et = ET[el] || ET.none
    const n = et.hits
    const pPerHit = Math.floor((skill.p || 50) / n * 1.12)
    const isAoE = skill.tgt === 'all'
    return Array.from({ length:n }, (_, i) => ({
      charId: m.id,
      power: pPerHit,
      type: skill.t || 'phys',
      targetId: isAoE ? null : targetId,
      isAoE,
      element: el,
      skillSts: i === n-1 ? skill.sts : null,
      isLastHit: i === n-1,
      extraMult,
      hitNum: i+1,
      totalHits: n,
      winMs: et.winMs,
      gapMs: et.gapMs,
      col: et.col,
      label: et.label,
    }))
  }

  function startHitChain(hits, postFn) {
    const g = gs.current; g._postHitFn = postFn
    function next(remaining) {
      if (!remaining.length) { const f = gs.current._postHitFn; gs.current._postHitFn = null; if (f) f(); return }
      const [hit, ...rest] = remaining
      const g2 = gs.current
      g2.surgeWin = { type:'surge', deadline:Date.now()+hit.winMs, duration:hit.winMs, col:hit.col, label:hit.label, hitNum:hit.hitNum, totalHits:hit.totalHits, charId:hit.charId, clicked:false }
      render()
      setTimeout(() => {
        const g3 = gs.current
        const surged = g3.surgeWin?.clicked || false; g3.surgeWin = null
        const bonus = surged ? 1.45 : 1.0
        const m = g3.party.find(p => p.id === hit.charId)
        if (m && m.hp > 0) {
          const alive = g3.enemies.filter(e => e.hp > 0)
          const tgts = hit.isAoE ? alive : [alive.find(e => e.id === hit.targetId) || alive[0]].filter(Boolean)
          tgts.forEach(tgt => {
            const d = dealDmg(m, hit.power, hit.type, tgt, hit.element, hit.isLastHit ? hit.skillSts : null, bonus * (hit.extraMult||1))
            if (d > 0) doLog(`   ${EI[hit.element]||'⚔'} Hit ${hit.hitNum}/${hit.totalHits}: ${tgt.name} -${d}${surged?' [SURGE!]':''}`)
          })
          // Holy SURGE bonus: heal party on surged last hit
          if (surged && hit.element === 'holy' && hit.isLastHit) {
            const h = Math.floor((m.mag||0)*.5 + 20)
            g3.party.forEach(p => { if (p.hp > 0) { p.hp = Math.min(p.mhp, p.hp + h); addFloat(p, `+${h}`, '#ffeaa7') } })
            doLog(`   ✨ Holy SURGE! Party +${h} HP!`)
          }
        }
        render()
        if (g3.enemies.every(e => e.hp <= 0)) { setTimeout(() => waveClear(), 200); return }
        if (rest.length > 0) setTimeout(() => next(rest), hit.gapMs || 80)
        else { const f = g3._postHitFn; g3._postHitFn = null; if (f) f() }
      }, hit.winMs)
    }
    next(hits)
  }

  // ── COMBO LOGIC ──────────────────────────────────────────
  function triggerCombo(combo, src, tgtId, is3) {
    const g = gs.current
    doLog(`${is3?'⚡⚡⚡ 3-WAY':'⚡⚡ 2-WAY'} COMBO — ★ ${combo.name} ★`); doLog(`   ${combo.d}`)
    g.comboResult = combo; g.comboChain = []
    if ((combo.heal||0) > 0) { g.party.forEach(m => { if (m.hp>0) { m.hp=Math.min(m.mhp,m.hp+(combo.heal||0)); addFloat(m,`+${combo.heal}`,'#2ecc71') } }); doLog(`   💚 Party +${combo.heal} HP!`) }
    if ((combo.p||0) > 0 && src) {
      const alive = g.enemies.filter(e => e.hp > 0)
      const tgts = combo.all ? alive : [alive.find(e => e.id === tgtId) || alive[0]].filter(Boolean)
      tgts.forEach(en => { const d = dealDmg(src, combo.p, 'magic', en, combo.e, null, 1); if (d>0) doLog(`   💥 ${en.name} -${d}!`) })
    }
    setTimeout(() => { gs.current.comboResult = null; render() }, 3800)
    if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 350)
  }

  function checkChain(el, src, tgtId) {
    const g = gs.current; if (!CELS.has(el)) return false
    const now = Date.now()
    const job = JOBS[src?.job]; const chainMs = 7000 + (job?.passive?.key === 'chainExtend' ? (job.passive.val||0) : 0)
    const chain = g.comboChain.filter(c => now - c.time < chainMs)
    if (chain.length >= 2) { const c3 = getC3(chain[0].el, chain[1].el, el); if (c3) { triggerCombo(c3, src, tgtId, true); return true } }
    if (chain.length >= 1) { const c2 = getC2(chain[chain.length-1].el, el); if (c2) { triggerCombo(c2, src, tgtId, false); return true } }
    g.comboChain = [...chain.slice(-1), { el, cid: src?.id, time: Date.now() }]
    if (chain.length >= 1) doLog(`✨ Chain: [${g.comboChain.map(c=>c.el.toUpperCase()).join('→')}] — add compatible element!`)
    return false
  }

  // ── SUMMON ───────────────────────────────────────────────
  function findEidEl(eid) { for (const [el,arr] of Object.entries(EID)) if (arr.includes(eid)) return el; return 'none' }

  function executeSummon(eid, charId, targetId) {
    const g = gs.current; const m = g.party.find(p => p.id === charId)
    if (!m || m.hp <= 0) return
    if (m.mp < eid.mp) { doLog('❌ Not enough MP!'); render(); return }
    m.mp -= eid.mp; m.atb = 0; g.activeChar = null; g.pendingSkill = null; g.phase = 'battle'
    const job = JOBS[m.job]
    const el = findEidEl(eid)
    let boost = m.aura ? 1.5 : 1
    if (job?.passive?.key === 'summonBoost') boost *= (1 + (job.passive.val||0))
    if (job?.passive?.key === 'darkSummonBoost' && el === 'dark') boost *= (1 + (job.passive.val||0))
    doLog(`📖 ${m.name} calls ${eid.name} [${eid.tl}]!`)
    if (eid.t <= 2) { g.summonAnim = { name:eid.name, sub:eid.sub, ico:eid.ico, t:eid.t, col:EC[el]||'#ffd700', desc:eid.d }; setTimeout(() => { gs.current.summonAnim = null; render() }, eid.t === 1 ? 2800 : 1500) }
    if ((eid.heal||0) > 0) { const h = Math.floor(eid.heal*boost); g.party.forEach(p => { if (p.hp>0) { p.hp=Math.min(p.mhp,p.hp+h); addFloat(p,`+${h}`,'#2ecc71') } }); doLog(`   💚 Party +${h} HP!`) }
    if ((eid.restoreEther||0) > 0) { g.party.forEach(p => { p.ether=Math.min(p.mether,(p.ether||0)+(eid.restoreEther||0)) }); doLog(`   🟪 Party Ether +${eid.restoreEther}!`) }
    if (eid.stripTemper) { const alive=g.enemies.filter(e=>e.hp>0); alive.forEach(e=>{e.temper=Math.max(0,(e.temper||0)-eid.stripTemper)}); g.party.forEach(p=>{p.temper=Math.min(p.mtemper,(p.temper||0)+Math.floor(eid.stripTemper*.5))}); doLog(`   🪨 Enemy Temper -${eid.stripTemper}!`) }
    if (eid.purgeAll) { g.party.forEach(p => { p.statuses=p.statuses.filter(s=>!['cursed','silence','blind','burning','weaken'].includes(s.type)); addS(p,'blessed',3) }); doLog(`   ✨ Null purged! Party Blessed!`) }
    const alive = g.enemies.filter(e => e.hp > 0)
    if ((eid.p||0) > 0 && alive.length > 0) {
      const et = ET[el] || ET.none
      const pPerHit = Math.floor(Math.floor(eid.p*boost) / et.hits * 1.08)
      const firstTarget = alive.find(e => e.id === targetId) || alive[0]
      const sumHits = Array.from({ length:et.hits }, (_, i) => ({
        charId:m.id, power:pPerHit, type:'magic',
        targetId: eid.all ? null : firstTarget?.id, isAoE:eid.all||false,
        element:el, skillSts: i===et.hits-1?eid.sts:null, isLastHit:i===et.hits-1,
        extraMult:1, hitNum:i+1, totalHits:et.hits,
        winMs:et.winMs, gapMs:et.gapMs, col:et.col, label:`${eid.name}!`,
      }))
      startHitChain(sumHits, () => {
        if (eid.eff === 'zantetsuken') { const t=alive[0]; if(t){if(Math.random()<.35){t.hp=0;addFloat(t,'KO!','#e74c3c',13);doLog(`   ☠ ZANTETSUKEN!`)}else doLog(`   ☠ Zantetsuken missed…`)} }
        if ((eid.drainEther||0) > 0) { const t=alive.find(e=>e.id===targetId)||alive[0]; if(t){t.ether=Math.max(0,(t.ether||0)-(eid.drainEther||0));m.ether=Math.min(m.mether,(m.ether||0)+Math.floor((eid.drainEther||0)*.5));doLog(`   🟪 ${t.name} Ether drained!`)} }
        if (eid.name === 'Vaelthorn') alive.forEach(en => { if (en.hp>0){addS(en,'cursed',3,{dot:20});doLog(`   💜 ${en.name} Null-Cursed!`)} })
        if (eid.eff?.startsWith('field_')) { const ft=eid.eff.replace('field_',''); g.fieldEffect={type:ft,turns:3,source:eid.name}; doLog(`🌐 ${eid.name}'s field! [${ft.toUpperCase()}+38%] 3 turns!`) }
        checkChain(el, m, targetId)
        if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 350)
        render()
      })
    } else {
      if (eid.eff?.startsWith('field_')) { const ft=eid.eff.replace('field_',''); g.fieldEffect={type:ft,turns:3,source:eid.name}; doLog(`🌐 ${eid.name}'s field!`) }
      checkChain(el, m, targetId)
      if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 350)
      render()
    }
  }

  // ── WAVE CLEAR ──────────────────────────────────────────
  function waveClear() {
    const g = gs.current
    const earned = g.enemies.reduce((s,e) => s+(e.rwd||0), 0)
    const jp = g.enemies.reduce((s,e) => s+(e.jp||0), 0)
    g.gold += earned; g.totalJP += jp
    const prev = sLv(g.totalJP - jp), nxt = sLv(g.totalJP)
    if (nxt > prev) doLog(`⭐ RESONANT Lv${prev}→Lv${nxt}! New Guardians answer!`)
    const freed = g.enemies.filter(e => e.isGuardian && e.hp <= 0)
    if (freed.length) doLog(`💚 ${freed.map(e => e.name.replace(/ \[.*\]/,'') + '\'s Ether freed!').join(' ')}`)
    doLog(`✨ Wave cleared! +${earned}G | +${jp}JP | Total: ${g.totalJP}JP`)
    g.phase = g.wave >= WAVES.length-1 ? 'victory' : 'waveClear'
    if (g.wave >= WAVES.length-1) doLog('🏆 OMEGA NULL SHATTERED! Vaelthar breathes again.')
    render()
  }

  // ── EXECUTE SKILL ────────────────────────────────────────
  function execSkill(charId, skill, targetId) {
    const g = gs.current; const m = g.party.find(p => p.id === charId)
    if (!m || m.hp <= 0) return
    if (hasS(m, 'silence') && (skill.mp||0) > 0) { doLog(`🤫 ${m.name}'s Ether sealed!`); render(); return }
    if (m.mp < (skill.mp||0)) { doLog('❌ Not enough MP!'); render(); return }
    if (skill.id === 'resonate') { tryResonate(charId); return }
    if (skill.t === 'summon') { g.phase = 'summon_menu'; g.summonTab = 'fire'; render(); return }
    m.mp -= (skill.mp||0); m.atb = 0; g.activeChar = null; g.pendingSkill = null; g.phase = 'battle'
    const el = skill.el || 'none'

    // Instant / non-damage skills
    if (skill.cover)       { m.guard=1; const a=g.party.find(p=>p.id===targetId); if(a)a.guard=1; doLog(`🛡 ${m.name}: Cover!`); render(); return }
    if (skill.aura)        { m.aura=1; doLog(`🌟 ${m.name}: Aura — Guardian power ×1.5!`); render(); return }
    if (skill.partyAura)   { g.party.filter(p=>p.hp>0).forEach(p=>{p.aura=1}); doLog(`🌟 ${m.name}: Bond Oath — ALL party Aura!`); render(); return }
    if (skill.manaFlow)    { const r=Math.floor(m.mmp*.38); m.mp=Math.min(m.mmp,m.mp+r); addFloat(m,`+${r}MP`,'#2980b9'); doLog(`💧 ${m.name}: Mana Flow +${r} MP!`); render(); return }
    if (skill.haste)       { const t=g.party.find(p=>p.id===targetId)||m; t.haste=1;t.spd*=1.5;addS(t,'haste',5); doLog(`⏩ ${m.name}: Haste → ${t.name}!`); render(); return }
    if (skill.slow)        { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){addS(t,'slow',3);t.spd*=.5;doLog(`⏱ ${m.name}: Slow!`)}; render(); return }
    if (skill.stop)        { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){addS(t,'stun',3);doLog(`⏸ ${m.name}: Stop!`)}; render(); return }
    if (skill.timestop)    { g.enemies.filter(e=>e.hp>0).forEach(en=>addS(en,'stun',4)); doLog(`⌛ ${m.name}: TIMESTOP — all enemies frozen 4 turns!`); render(); return }
    if (skill.phaseShift)  { const t=g.party.find(p=>p.id===targetId); if(t){addS(t,'shielded',3);doLog(`👁 ${m.name}: Phase Shift — ${t.name} phased!`)}; render(); return }
    if (skill.dispel)      { const t=g.party.find(p=>p.id===targetId); if(t){t.statuses=[];addFloat(t,'PURGED!','#ffd700');doLog(`🌟 ${m.name}: Dispel!`)}; render(); return }
    if (skill.dispelAll)   { g.party.forEach(p=>{p.statuses=[]}); doLog(`🌟 ${m.name}: Null Purge — all party cleansed!`); render(); return }
    if (skill.sanctuary)   { g.party.filter(p=>p.hp>0).forEach(p=>addS(p,'shielded',3)); doLog(`🏰 ${m.name}: Sanctuary — party shielded 3 turns!`); render(); return }
    if (skill.setField)    { g.fieldEffect={type:skill.setField,turns:3,source:m.name}; doLog(`🌐 ${m.name} creates ${skill.setField} field!`); render(); return }
    if (skill.etherThread) { doLog(`🧵 ${m.name}: Ether Thread — combo chain seeded!`); g.comboChain=[...g.comboChain,{el:'fire',cid:m.id,time:Date.now()},{el:'ice',cid:m.id,time:Date.now()}]; render(); return }
    if (skill.partyTemper) { const amt=skill.partyTemper||50; g.party.filter(p=>p.hp>0).forEach(p=>{p.temper=Math.min(p.mtemper,(p.temper||0)+amt);addFloat(p,`+${amt}TMP`,'#fd9644')}); doLog(`🛡 ${m.name}: Dragonscale — Party Temper +${amt}!`); render(); return }
    if (skill.voidShackle) { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){addS(t,'silence',2);addS(t,'cursed',2,{dot:12});addS(t,'weaken',2);addFloat(t,'SHACKLED!','#9b59b6',11);doLog(`⛓ ${m.name}: Void Shackle!`)}; render(); return }
    if (skill.archonMark)  { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){t.archonMarked=1;doLog(`🎯 ${m.name}: Archon's Mark — ${t.name} takes +50% damage!`)}; render(); return }
    if (skill.skyChain) {
      const n=skill.skyChain||5; const t=g.enemies.find(e=>e.id===targetId&&e.hp>0)
      if (t) { const et2=ET.wind; const hits=Array.from({length:n},(_,i)=>({charId:m.id,power:Math.floor(m.str*.8+40),type:'phys',targetId:t.id,isAoE:false,element:'wind',skillSts:i===n-1?{t:'knockdown',ch:.4,turns:1}:null,isLastHit:i===n-1,extraMult:1,hitNum:i+1,totalHits:n,winMs:et2.winMs,gapMs:et2.gapMs,col:et2.col,label:'GUST!'})); doLog(`💨 ${m.name}: Sky Chain!`); startHitChain(hits,()=>render()) }
      render(); return
    }
    if (skill.chainHit) { ['fire','ice','thunder'].forEach(elem=>g.enemies.filter(e=>e.hp>0).forEach(en=>dealDmg(m,Math.floor((skill.p||155)*.55),'magic',en,elem,null,1))); const c3=C3['fire|ice|thunder']; if(c3)triggerCombo(c3,m,g.enemies.find(e=>e.hp>0)?.id,true); render(); return }
    if (skill.restoreTemper || skill.restoreEther) {
      const t = g.party.find(p => p.id === targetId) || m
      if (skill.restoreTemper) { t.temper=Math.min(t.mtemper,(t.temper||0)+(skill.restoreTemper||0)); addFloat(t,`+${skill.restoreTemper}TMP`,'#fd9644') }
      if (skill.restoreEther)  { t.ether =Math.min(t.mether, (t.ether||0) +(skill.restoreEther||0));  addFloat(t,`+${skill.restoreEther}ETH`,'#9b59b6') }
      doLog(`🛡 ${m.name}: ${skill.n} → ${t.name} Temper/Ether restored!`); render(); return
    }
    if (skill.revive) {
      const t = g.party.find(p => p.id === targetId && p.hp <= 0)
      if (t) { const pct=skill.fullRevive?1.0:.25; t.hp=Math.floor(t.mhp*pct); t.temper=Math.floor(t.mtemper*.5); t.ether=Math.floor(t.mether*.5); t.statuses=[]; addFloat(t,skill.fullRevive?'FULL REVIVE!':'REVIVED!','#ff6b35',11); doLog(`✨ ${m.name}: ${skill.n} — ${t.name} revived!`) }
      else doLog(`❌ No KO'd ally!`); render(); return
    }
    if (skill.instakill) {
      const t = g.enemies.find(e => e.id === targetId && e.hp > 0)
      if (t) { const ch=(t.temper||0)===0?.55:.28; if(Math.random()<ch){t.hp=0;addFloat(t,'INSTANT KO!','#e74c3c',11);doLog(`☠ ${m.name}: ${skill.n} — ${t.name} KO!`)}else doLog(`${m.name}: ${skill.n} missed…`); if(skill.curseSurvivors)g.enemies.filter(e=>e.hp>0).forEach(en=>{addS(en,'cursed',3,{dot:18});doLog(`   💜 ${en.name} Null-Cursed!`)}) }
      render(); return
    }
    if (skill.t === 'heal' || skill.healAll) {
      const h = Math.floor((skill.p||0) + m.mag * (skill.healAll?0.8:1))
      if (skill.tgt === 'party' || skill.healAll) {
        g.party.filter(p=>p.hp>0).forEach(p => {
          p.hp=Math.min(p.mhp,p.hp+h); addFloat(p,`+${h}`,'#2ecc71')
          const job2=JOBS[m.job]; if(job2?.passive?.key==='healTemper')p.temper=Math.min(p.mtemper,(p.temper||0)+(job2.passive.val||0))
        })
        doLog(`💚 ${m.name}: ${skill.n} — Party +${h} HP!`)
      } else {
        const t = g.party.find(p => p.id === targetId) || m
        t.hp = Math.min(t.mhp, t.hp+h); addFloat(t,`+${h}`,'#2ecc71')
        const job2=JOBS[m.job]; if(job2?.passive?.key==='healTemper')t.temper=Math.min(t.mtemper,(t.temper||0)+(job2.passive.val||0))
        doLog(`💚 ${m.name}: ${skill.n} → ${t.name} +${h} HP!`)
      }
      render(); return
    }
    if (skill.holyHeal) {
      const tgts = g.enemies.filter(e => e.hp > 0)
      const hits = buildHits(m, skill, targetId, 1)
      startHitChain(hits, () => {
        const h = skill.holyHeal||50; g.party.forEach(p=>{if(p.hp>0){p.hp=Math.min(p.mhp,p.hp+h);addFloat(p,`+${h}`,'#ffeaa7')}}); doLog(`   ✨ Radiant Edge healed party +${h}!`)
        checkChain(el, m, targetId); if(g.enemies.every(e=>e.hp<=0))setTimeout(()=>waveClear(),200); render()
      }); render(); return
    }

    // Normal damage → hit chain
    doLog(`${skill.ico||'⚔'} ${m.name}: ${skill.n}!`)
    const hits = buildHits(m, skill, targetId, 1)
    startHitChain(hits, () => {
      if (skill.drain) { const dr=Math.floor((skill.p||90)*.5); m.hp=Math.min(m.mhp,m.hp+dr); addFloat(m,`+${dr}`,'#2ecc71') }
      if (skill.drainEther) { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){const de=Math.min(t.ether||0,skill.drainEther||28);t.ether=Math.max(0,(t.ether||0)-de);m.ether=Math.min(m.mether,(m.ether||0)+Math.floor(de*.5));doLog(`🟪 Ether drained!`)} }
      if (skill.sunTemper) { const t=g.enemies.find(e=>e.id===targetId&&e.hp>0); if(t){t.temper=Math.max(0,(t.temper||0)-(skill.sunTemper||40));doLog(`🔨 Sunder — ${t.name} Temper -${skill.sunTemper}!`);if(t.temper===0)doLog(`🟧 ${t.name}'s TEMPER shattered!`)} }
      checkChain(el, m, targetId)
      if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 200)
      render()
    })
    render()
  }

  // ── LIMIT BREAK ──────────────────────────────────────────
  function executeLimitBreak(charId) {
    const g = gs.current; const m = g.party.find(p => p.id === charId)
    if (!m || m.hp <= 0 || (m.limit||0) < 100) return
    m.limit = 0; m.atb = 0; g.activeChar = null; g.pendingSkill = null; g.phase = 'battle'
    const lb = LB[m.job]; if (!lb) return
    doLog(`💥 ${m.name}: LIMIT BREAK — ${lb.n}!`)
    const alive = g.enemies.filter(e => e.hp > 0)
    const doHeal = (hp, tmp, eth, clearSts, blessed) => g.party.forEach(p => {
      if (p.hp <= 0) return
      if (hp > 0) { p.hp = Math.min(p.mhp, p.hp + (hp === 9999 ? p.mhp : hp)) }
      if (tmp) p.temper = p.mtemper; if (eth) p.ether = p.mether
      if (clearSts) p.statuses = []; if (blessed) addS(p,'blessed',3)
    })
    switch (m.job) {
      case 'knight':      for(let i=0;i<3;i++) alive.forEach(en=>{const d=dealDmg(m,138,'phys',en,'none',null,1);en.temper=Math.max(0,(en.temper||0)-45);if(d>0)doLog(`   ⚔ Hit${i+1}: -${d}, -45 Temper!`)}); break
      case 'nullbreaker': alive.forEach(en=>{en.temper=0;doLog(`   💔 ${en.name} Temper→0!`)}); for(let i=0;i<4;i++) alive.forEach(en=>{const d=dealDmg(m,155,'phys',en,'none',null,1);if(d>0)doLog(`   ⚔ Hit${i+1}: -${d}!`)}); break
      case 'blackmage':   alive.forEach(en=>{dealDmg(m,105,'magic',en,'fire',null,1);dealDmg(m,105,'magic',en,'ice',null,1);dealDmg(m,105,'magic',en,'thunder',null,1)}); { const c3=C3['fire|ice|thunder'];if(c3)triggerCombo(c3,m,alive[0]?.id,true) } break
      case 'etherweaver': Object.keys(EC).filter(el=>EI[el]).forEach(el=>alive.forEach(en=>dealDmg(m,80,'magic',en,el,null,1))); doLog('🌈 ALL 8 ELEMENTS strike!'); break
      case 'summoner':    { const slv2=sLv(g.totalJP);let best=null,bestP=0;Object.entries(EID).forEach(([el,arr])=>arr.forEach((eid,ti)=>{if(slv2>=(SUMMON_REQ[el]?.[ti]||99)&&(eid.p||0)>bestP){bestP=eid.p;best=eid}}));if(best){const oldMp=m.mp;m.mp=m.mmp;executeSummon(best,charId,alive[0]?.id);m.mp=oldMp} } break
      case 'primalbinder':{ const slv2=sLv(g.totalJP);Object.entries(EID).forEach(([el,arr])=>{const eid=arr[3];if(slv2>=(SUMMON_REQ[el]?.[3]||99))alive.forEach(en=>{const d=dealDmg(m,Math.floor(eid.p*.3),'magic',en,el,null,1);if(d>0)doLog(`   ${EI[el]} ${eid.name}: -${d}!`)})}) } break
      case 'whitemage':   doHeal(9999,true,true,true,true); doLog('✨ ASTRAL LIGHT — Party fully restored!'); break
      case 'seraph':      doHeal(9999,true,true,true,true); g.party.filter(p=>p.hp>0).forEach(p=>addS(p,'regen',3)); doLog('✨ ASCENSION — Full restore + Regen + Blessed!'); break
      case 'dragoon':     for(let i=0;i<5;i++) alive.forEach(en=>{const d=dealDmg(m,95,'magic',en,'fire',null,1);if(d>0)doLog(`   🔥 Hit${i+1}: -${d}!`)}); break
      case 'skysovereign':for(let i=0;i<7;i++) alive.forEach(en=>{const d=dealDmg(m,88,'phys',en,'fire',null,1);if(d>0)doLog(`   🐲 Hit${i+1}: -${d}!`)}); g.fieldEffect={type:'fire',turns:3,source:'Sky Sovereign'}; g.party.filter(p=>p.hp>0).forEach(p=>{p.temper=Math.min(p.mtemper,(p.temper||0)+60)}); doLog('🐲 Fire field! Party Temper+60!'); break
      case 'timemage':    alive.forEach(en=>{addS(en,'stun',3);en.spd*=.3}); g.party.filter(p=>p.hp>0).forEach(p=>{p.haste=1;p.spd*=1.5}); doLog('⏸ CHRONOSTASIS — All stopped! Party hasted!'); break
      case 'nullchrono':  alive.forEach(en=>addS(en,'stun',4)); g.party.filter(p=>p.hp>0).forEach(p=>{p.spd*=2}); doLog('⌛ TEMPORAL COLLAPSE — Frozen 4 turns! Party speed ×2!'); break
      case 'paladin':     alive.forEach(en=>{const d=dealDmg(m,720,'magic',en,'holy',null,1);if(d>0)doLog(`   ⚜ -${d}!`)}); doHeal(0,true,true,false,true); doLog('⚜ SACRED JUDGMENT — Full Temper/Ether + Blessed!'); break
      case 'radiantkeeper':alive.forEach(en=>{dealDmg(m,720,'magic',en,'holy',null,1);tryS(en,'blind',.9,3)}); g.fieldEffect={type:'holy',turns:4,source:'Radiant Keeper'}; doHeal(0,true,true,false,true); doLog('⚜ DIVINE SANCTUM — Holy field 4t + full Temper/Ether!'); break
      case 'necromancer': { let td=0; alive.forEach(en=>{const d=dealDmg(m,140,'magic',en,'dark',null,1);const de=Math.min(en.ether||0,65);en.ether=Math.max(0,(en.ether||0)-de);td+=de;addS(en,'cursed',3,{dot:18});if(d>0)doLog(`   🌑 -${d}HP,-${de}ETH,CURSED!`)}); const pp=Math.floor(td/Math.max(1,g.party.filter(p=>p.hp>0).length)); g.party.filter(p=>p.hp>0).forEach(p=>{p.ether=Math.min(p.mether,(p.ether||0)+pp);addFloat(p,`+${pp}ETH`,'#9b59b6')}); doLog(`💀 NULL FLOOD — Party +${pp} Ether each!`) } break
      case 'nullarchon':  alive.forEach(en=>{addS(en,'silence',2);addS(en,'cursed',3,{dot:18});addS(en,'weaken',3);en.ether=0;doLog(`   ⛓ ${en.name}: Void Shackled!`)}); { const pp=Math.floor(alive.reduce((s,en)=>s+(en.mether||0),0)*.3/Math.max(1,g.party.filter(p=>p.hp>0).length));g.party.filter(p=>p.hp>0).forEach(p=>{p.ether=Math.min(p.mether,(p.ether||0)+pp)});doLog(`💀 NULL APOCALYPSE — Party Ether maxed!`) } break
      case 'darksummoner':{ const v=EID.dark[3]; const oldMp=m.mp; m.mp=m.mmp; executeSummon(v,charId,alive[0]?.id); m.mp=oldMp } break
      case 'vaelthornsvoice':EID.dark.forEach(eid=>alive.forEach(en=>{const d=dealDmg(m,Math.floor(eid.p*.25),'magic',en,'dark',null,1);if(d>0)doLog(`   🌑 ${eid.name}: -${d}!`)})); doLog('🐉 NULL GENESIS — All dark Guardians strike!'); break
    }
    if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 350)
    render()
  }

  // ── RESONANCE ────────────────────────────────────────────
  function tryResonate(charId) {
    const g = gs.current; if (!g.resonanceWindow) return
    const m = g.party.find(p => p.id === charId); if (!m || m.hp <= 0) return
    if (m.mp < 30) { doLog('❌ Need 30 MP to Resonate!'); render(); return }
    m.mp -= 30; m.atb = 0; g.activeChar = null; g.pendingSkill = null; g.phase = 'battle'
    const isR = ['summoner','darksummoner','primalbinder','vaelthornsvoice'].includes(m.job)
    const ch = (isR ? 0.82 : 0.48) + (m.aura ? 0.12 : 0)
    const guardian = g.enemies.find(e => e.id === g.resonanceWindow.guardianId)
    if (Math.random() < ch) {
      doLog(`📖 RESONANCE SUCCESS! ${guardian?.name||'Guardian'}\'s Void Anchor SHATTERS!`)
      doLog('✨ The Guardian\'s Ether flows free. They\'re coming home.')
      g.resonanceWindow = null
      const bonusJP = Math.floor((guardian?.jp||0) * .5); g.totalJP += bonusJP; if (bonusJP) doLog(`⭐ +${bonusJP} bonus JP!`)
      if (guardian) guardian.hp = 0; addFloat(m, 'RESONANCE!', '#ffd700', 11)
      g.party.forEach(p => { if (p.hp>0) { p.hp=Math.min(p.mhp,p.hp+85); addFloat(p,'+85','#2ecc71') } })
      doLog('💚 Guardian\'s freed Ether heals party +85 HP!')
      if (g.enemies.every(e => e.hp <= 0)) setTimeout(() => waveClear(), 600)
    } else {
      g.resonanceWindow.attempts = (g.resonanceWindow.attempts||0) + 1
      doLog('💔 Resonance failed — Void Anchor fights back!')
      if (g.resonanceWindow.attempts >= 2) {
        doLog(`🔴 ${guardian?.name||'Guardian'} BERSERK! Void Anchor re-seals!`)
        if (guardian) { addS(guardian,'berserk',4); guardian.hp=Math.min(guardian.mhp,guardian.hp+Math.floor(guardian.mhp*.25)) }
        g.resonanceWindow = null
      } else doLog('📖 One more chance… (Aura helps!)')
    }
    render()
  }

  // ── ITEM USE ─────────────────────────────────────────────
  function useItem(charId, itemKey, targetId) {
    const g = gs.current; if ((g.items[itemKey]||0) <= 0) { doLog('❌ None left!'); render(); return }
    g.items[itemKey]--; g.activeChar = null; g.pendingSkill = null; g.itemMode = false; g.phase = 'battle'
    const def = ITEM_DEFS[itemKey]
    switch (itemKey) {
      case 'vitaedraught':  { const t=g.party.find(p=>p.id===targetId); if(t){t.hp=Math.min(t.mhp,t.hp+200);addFloat(t,'+200','#2ecc71');doLog(`🧪 ${t.name}: Vitae Draught +200 HP!`)} } break
      case 'resonphial':    { const t=g.party.find(p=>p.id===targetId); if(t){t.ether=Math.min(t.mether,(t.ether||0)+90);addFloat(t,'+90ETH','#9b59b6');doLog(`💠 ${t.name}: Resonance Phial +90 Ether!`)} } break
      case 'ironcoreshard': { const t=g.party.find(p=>p.id===targetId); if(t){t.temper=Math.min(t.mtemper,(t.temper||0)+90);addFloat(t,'+90TMP','#fd9644');doLog(`🟧 ${t.name}: Ironcore Shard +90 Temper!`)} } break
      case 'soulmber':      { const t=g.party.find(p=>p.id===targetId&&p.hp<=0); if(t){t.hp=Math.floor(t.mhp*.60);t.temper=Math.floor(t.mtemper*.5);t.ether=Math.floor(t.mether*.5);t.statuses=[];addFloat(t,'SOUL RETURNED!','#ff6b35',10);doLog(`🔮 ${t.name}: Soul Ember — revived at 60%!`)}else doLog('❌ No KO\'d ally!') } break
      case 'nullbane':      { const t=g.party.find(p=>p.id===targetId); if(t){t.statuses=[];addFloat(t,'NULL CLEANSED!','#ffd700',10);doLog(`✨ ${t.name}: Null Bane — all statuses purged!`)} } break
    }
    render()
  }

  // ── ATB LOOP ─────────────────────────────────────────────
  useEffect(() => {
    const iv = setInterval(() => {
      const g = gs.current
      if (g.phase !== 'battle') return
      if (g.surgeWin) return  // PAUSE during timing windows

      let ch = 0
      const skipCheck = e => hasS(e,'frozen') || hasS(e,'stun') || hasS(e,'knockdown')
      const spdF = e => hasS(e,'slow') ? SD.slow.slow : hasS(e,'chilled') ? SD.chilled.slow : 1

      g.party.forEach(m => {
        if (m.hp <= 0 || skipCheck(m)) return
        const sf = spdF(m); if (m.atb < 100) { m.atb = Math.min(100, m.atb + (m.haste ? m.spd*sf*1.4 : m.spd*sf) * .72); ch = 1 }
      })
      g.enemies.forEach(en => {
        if (en.id === g.resonanceWindow?.guardianId) return
        if (en.hp <= 0 || skipCheck(en)) return
        const sf = spdF(en); if (en.atb < 100) { en.atb = Math.min(100, en.atb + en.spd*sf * .72); ch = 1 }
      })

      // Expire combo chain
      if (g.comboChain.length > 0) {
        const job = JOBS[g.party.find(p=>p.id===g.comboChain[g.comboChain.length-1]?.cid)?.job]
        const ms = 7000 + (job?.passive?.key === 'chainExtend' ? (job.passive.val||0) : 0)
        if (Date.now() - g.comboChain[g.comboChain.length-1].time > ms) { g.comboChain = []; ch = 1 }
      }

      if (!g.enemyActing) {
        const re = g.enemies.find(e => e.hp > 0 && e.atb >= 100)
        if (re) {
          g.enemyActing = 1; re.atb = 0

          if (skipCheck(re)) {
            const k = hasS(re,'frozen')?'frozen':hasS(re,'stun')?'stun':'knockdown'
            doLog(`${SD[k]?.ico||'💫'} ${re.name}: ${k.toUpperCase()}! Skip.`)
            tickStatuses(re)
            if (g.fieldEffect) { g.fieldEffect.turns--; if (g.fieldEffect.turns <= 0) { doLog(`🌐 ${g.fieldEffect.source} field fades.`); g.fieldEffect = null } }
            if (re.regenEther) { re.ether=Math.min(re.mether,(re.ether||0)+(re.regenEther||0)); doLog(`🟪 ${re.name} Ether regen +${re.regenEther}!`) }
            g.enemyActing = 0; ch = 1; render(); return
          }

          const sk = re.sk[Math.floor(Math.random() * re.sk.length)]
          const alive = g.party.filter(m => m.hp > 0); if (!alive.length) { g.enemyActing = 0; return }
          doLog(`👹 ${re.name} → ${sk.n}…`)

          // Open DEFLECT window
          g.surgeWin = { type:'deflect', deadline:Date.now()+500, duration:500, col:'#5dade2', label:'DEFLECT!', hitNum:1, totalHits:1, clicked:false }
          render()
          setTimeout(() => { const g2=gs.current; g2._deflecting=g2.surgeWin?.type==='deflect'&&g2.surgeWin.clicked; if(g2.surgeWin?.type==='deflect')g2.surgeWin=null; render() }, 500)

          setTimeout(() => {
            const g2 = gs.current; const alive2 = g2.party.filter(m => m.hp > 0); if (!alive2.length) { g2.enemyActing=0; return }
            const deflected = g2._deflecting; g2._deflecting = false

            // Smart targeting
            let smart = alive2[Math.floor(Math.random() * alive2.length)]
            if (sk.t === 'phys' || ['bleed','knockdown'].includes(sk.sts?.t||'')) smart = alive2.reduce((b,m)=>(m.temper||0)<(b.temper||0)?m:b, alive2[0])
            else if (sk.t === 'magic' || ['stun','cursed','silence','burning'].includes(sk.sts?.t||'')) smart = alive2.reduce((b,m)=>(m.ether||0)<(b.ether||0)?m:b, alive2[0])

            if (sk.stripEther)  alive2.forEach(t=>{t.ether= Math.max(0,(t.ether||0) -Math.floor((sk.stripEther||0)/alive2.length))})
            if (sk.stripTemper) alive2.forEach(t=>{t.temper=Math.max(0,(t.temper||0)-Math.floor((sk.stripTemper||0)/alive2.length))})
            if (sk.applyWet) alive2.forEach(t => addS(t,'wet',2))

            const tgts = sk.a ? alive2 : [smart]
            tgts.forEach(t => {
              const mb = g2.party.find(p => p.id === t.id); if (!mb || mb.hp <= 0) return
              if (hasS(mb,'shielded') && sk.t === 'phys') { doLog(`   👁 ${mb.name} phased! Physical misses!`); return }
              if (mb.guard) {
                const gRed = sk.t === 'phys' ? .35 : .55
                const d = Math.max(1, Math.floor(((sk.p||60) + (sk.t==='magic'?(re.mag||40):(re.str||40))*1.5 - (mb.def||20)*.7) * (.85+Math.random()*.3) * gRed))
                mb.guard = 0; addFloat(mb,`${d}🛡`,'#74b9ff'); doLog(`   🛡 ${mb.name} blocked! -${d}`); mb.hp = Math.max(0, mb.hp-d)
                mb.limit = Math.min(100, (mb.limit||0) + Math.floor(d/mb.mhp*60))
              } else {
                const d = dealDmg(re, sk.p||60, sk.t||'phys', mb, sk.el||'none', sk.sts, deflected?0.5:1.0)
                if (d > 0) { doLog(`   💢 ${mb.name} -${d}!${deflected?' [DEFLECTED!]':''} [TMP:${mb.temper} ETH:${mb.ether}]`); if(deflected)addFloat(mb,'DEFLECT!','#5dade2',13) }
                if (d > 0) mb.limit = Math.min(100, (mb.limit||0) + Math.floor(d/mb.mhp*120))
                if (mb.limit >= 100 && mb.limit - Math.floor(d/mb.mhp*120) < 100) doLog(`🔱 ${mb.name}: LIMIT BREAK READY!`)
                if (sk.drain && d > 0) { const dr=Math.floor(d*.4); re.hp=Math.min(re.mhp,re.hp+dr); addFloat(re,`+${dr}`,'#2ecc71') }
                if (sk.drainEther && (mb.ether||0) > 0) { const de=Math.min(mb.ether||0,sk.drainEther||25); mb.ether=Math.max(0,(mb.ether||0)-de) }
              }
            })

            tickStatuses(re)
            if (g2.fieldEffect) { g2.fieldEffect.turns--; if (g2.fieldEffect.turns <= 0) { doLog(`🌐 ${g2.fieldEffect.source} field fades.`); g2.fieldEffect = null } }
            if (re.regenEther) { re.ether=Math.min(re.mether,(re.ether||0)+(re.regenEther||0)); doLog(`🟪 ${re.name} Ether regen +${re.regenEther}!`) }
            if (g2.party.every(m => m.hp <= 0)) { g2.phase = 'defeat'; doLog('💀 DEFEAT — The Null Conclave wins…') }
            g2.enemyActing = 0; render()
          }, 720)
          ch = 1
        }
      }
      if (ch) render()
    }, 50)
    return () => clearInterval(iv)
  }, [])

  // ── EVENT HANDLERS ───────────────────────────────────────
  function onCharClick(id) { const g=gs.current; if(g.phase!=='battle')return; const c=g.party.find(m=>m.id===id); if(!c||c.hp<=0||c.atb<100)return; g.activeChar=id; g.itemMode=false; g.phase='skill'; render() }

  function onSkillClick(sk) {
    const g=gs.current; if(g.phase!=='skill')return; const c=g.party.find(m=>m.id===g.activeChar); if(!c)return
    if(sk.id==='resonate'){tryResonate(c.id);return}
    if(hasS(c,'silence')&&(sk.mp||0)>0){doLog(`🤫 ${c.name}'s Ether sealed!`);render();return}
    if(c.mp<(sk.mp||0)){doLog('❌ Not enough MP!');render();return}
    if(sk.t==='summon'){g.phase='summon_menu';g.summonTab='fire';render();return}
    const isAlly = sk.revive||sk.cover||sk.haste||sk.t==='heal'||sk.restoreTemper||sk.restoreEther||sk.dispel||sk.healAll||sk.sanctuary||sk.phaseShift||sk.dispelAll
    if(sk.aura||sk.manaFlow||sk.aegis?.tgt==='s') execSkill(c.id,sk,c.id)
    else if(sk.tgt==='s'||sk.tgt==='party'||sk.tgt==='all') execSkill(c.id,sk,c.id)
    else if(isAlly&&sk.tgt==='a'){g.pendingSkill=sk;g.phase='target_a';render()}
    else{g.pendingSkill=sk;g.phase='target_e';render()}
  }

  function onEnemyClick(eid) { const g=gs.current; if(g.phase!=='target_e')return; if(!g.enemies.find(e=>e.id===eid&&e.hp>0))return; if(g.pendingSkill?._eid){executeSummon(g.pendingSkill,g.activeChar,eid);return}; execSkill(g.activeChar,g.pendingSkill,eid) }
  function onAllyClick(aid)  { const g=gs.current; if(g.phase!=='target_a')return; if(g.itemMode)useItem(g.activeChar,g.pendingSkill?.itemKey,aid);else execSkill(g.activeChar,g.pendingSkill,aid) }
  function onSummonSelect(eid){ const g=gs.current; const slv2=sLv(g.totalJP); const el=g.summonTab; const ti=(EID[el]||[]).indexOf(eid); if((SUMMON_REQ[el]?.[ti]||99)>slv2){doLog(`❌ Need Resonant Lv${SUMMON_REQ[el][ti]}!`);render();return}; if(!eid.all&&(eid.p||0)>0){g.pendingSkill={...eid,_eid:1};g.phase='target_e';render()}else executeSummon(eid,g.activeChar,null) }
  function cancelToBattle()  { const g=gs.current; g.phase='battle';g.activeChar=null;g.pendingSkill=null;g.itemMode=false;render() }
  function cancelToSkill()   { const g=gs.current; g.phase='skill';g.pendingSkill=null;g.itemMode=false;render() }

  function nextWave() {
    const g=gs.current; const nw=g.wave+1
    if(nw>=WAVES.length){g.phase='victory';render();return}
    g.wave=nw; g.enemies=JSON.parse(JSON.stringify(WAVES[nw])); g.phase='battle'; g.comboChain=[]; g.resonanceWindow=null
    g.party.forEach(m=>{
      m.hp=Math.min(m.mhp,Math.floor(m.hp+m.mhp*.3)); m.mp=Math.min(m.mmp,Math.floor(m.mp+m.mmp*.5))
      m.temper=Math.min(m.mtemper,Math.floor((m.temper||0)+m.mtemper*.6)); m.ether=Math.min(m.mether,Math.floor((m.ether||0)+m.mether*.6))
      m.atb=0; m.statuses=m.statuses.filter(s=>s.type==='blessed'); m.floats=[]; m.guard=0; m.aura=0
      const job=JOBS[m.job]; if(job?.passive?.key==='startHaste'){m.haste=1;m.spd*=1.5;doLog(`⏩ ${m.name}: Null Chronomancer passive — Haste!`)}
    })
    const loreE=WAVES[nw].find(e=>e.lore); if(loreE)doLog(`📜 ${loreE.lore}`)
    doLog(`⚔ Wave ${nw+1}! ${g.enemies.map(e=>e.name).join(' & ')}!`)
    render()
  }

  function restart() { gs.current = freshState(); render() }

  // ── RENDER ───────────────────────────────────────────────
  const g = gs.current
  const ac = g.party.find(m => m.id === g.activeChar)
  const slv = sLv(g.totalJP)
  const chain = g.comboChain.filter(c => Date.now() - c.time < 7500)
  const nextLvJP = slv < 7 ? SLV_JP[slv+1] : null

  return (
    <div style={{ fontFamily:"'Press Start 2P',monospace", minHeight:'100vh',
      background:'linear-gradient(160deg,#040412 0%,#0b0b22 55%,#050f0a 100%)',
      color:'#ddd', display:'flex', flexDirection:'column', alignItems:'center', padding:'14px 10px', position:'relative' }}>
      <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet" />
      <div style={{ position:'fixed', inset:0, backgroundImage:'radial-gradient(circle,#ffffff09 1px,transparent 1px)', backgroundSize:'44px 44px', pointerEvents:'none', zIndex:0 }} />

      {/* ── SURGE / DEFLECT BUTTON ── */}
      {g.surgeWin && !g.surgeWin.clicked && (
        <div style={{ position:'fixed', bottom:'16%', left:'50%', transform:'translateX(-50%)', zIndex:600,
          display:'flex', flexDirection:'column', alignItems:'center', gap:6 }}>
          {g.surgeWin.totalHits > 1 && <div style={{ fontSize:8, color:g.surgeWin.col, textShadow:`0 0 8px ${g.surgeWin.col}` }}>{g.surgeWin.hitNum}/{g.surgeWin.totalHits}</div>}
          <button onClick={handleSurge} style={{ width:80, height:80, borderRadius:'50%',
            background:`radial-gradient(circle,${g.surgeWin.col}44,${g.surgeWin.col}11)`,
            border:`4px solid ${g.surgeWin.col}`, color:g.surgeWin.col, fontSize:20,
            cursor:'pointer', fontFamily:'inherit',
            boxShadow:`0 0 30px ${g.surgeWin.col}, 0 0 60px ${g.surgeWin.col}44`,
            animation:'surgePulse .25s ease-in-out infinite' }}>
            {g.surgeWin.type === 'deflect' ? '🛡' : '⚡'}
          </button>
          <div style={{ fontSize:8, color:g.surgeWin.col, textShadow:`0 0 10px ${g.surgeWin.col}`, animation:'blink .3s steps(1) infinite' }}>{g.surgeWin.label}</div>
          <div style={{ width:80, height:5, background:'#111', overflow:'hidden', borderRadius:3 }}>
            <div style={{ height:'100%', background:g.surgeWin.col,
              animation:`countdownBar ${g.surgeWin.duration}ms linear forwards`, transformOrigin:'left' }} />
          </div>
        </div>
      )}

      {/* COMBO FLASH */}
      {g.comboResult && (
        <div style={{ position:'fixed', top:'50%', left:'50%', transform:'translate(-50%,-55%)', zIndex:400,
          background:'linear-gradient(135deg,#12052e,#200a50)', border:`3px solid ${EC[g.comboResult.e]||'#ffd700'}`,
          padding:'22px 36px', textAlign:'center', boxShadow:`0 0 70px ${EC[g.comboResult.e]||'#ffd700'}`,
          animation:'comboPop .4s cubic-bezier(.17,.67,.38,1.37) forwards' }}>
          <div style={{ fontSize:7, color:'#888', marginBottom:5 }}>{(g.comboResult.p||0)>500?'✦✦✦ 3-WAY COMBO ✦✦✦':'✦✦ 2-WAY COMBO ✦✦'}</div>
          <div style={{ fontSize:15, color:EC[g.comboResult.e]||'#ffd700', marginBottom:10, textShadow:`0 0 30px ${EC[g.comboResult.e]||'#ffd700'}` }}>{g.comboResult.name}</div>
          <div style={{ fontSize:7, color:'#ccc' }}>{g.comboResult.d}</div>
        </div>
      )}

      {/* SUMMON ANIMATION */}
      {g.summonAnim && (
        <div style={{ position:'fixed', inset:0, zIndex:350, display:'flex', flexDirection:'column',
          alignItems:'center', justifyContent:'center',
          background: g.summonAnim.t === 1 ? 'rgba(0,0,0,.88)' : 'rgba(0,0,0,.72)', animation:'fadeIn .3s ease-out' }}>
          {g.summonAnim.t === 1 && <div style={{ fontSize:7, color:g.summonAnim.col, letterSpacing:4, marginBottom:10, animation:'pulse 1s infinite' }}>⭐ PRIMAL GUARDIAN ANSWERS ⭐</div>}
          <div style={{ fontSize: g.summonAnim.t===1?88:56, filter:`drop-shadow(0 0 30px ${g.summonAnim.col})`, animation:'godPulse 1s ease-in-out infinite' }}>{g.summonAnim.ico}</div>
          <div style={{ fontSize: g.summonAnim.t===1?18:10, color:g.summonAnim.col, marginTop:12, textShadow:`0 0 24px ${g.summonAnim.col}` }}>{g.summonAnim.name}</div>
          <div style={{ fontSize:7, color:'#aaa', marginTop:6 }}>{g.summonAnim.sub}</div>
          <div style={{ fontSize:7, color:'#888', marginTop:8, maxWidth:340, textAlign:'center' }}>{g.summonAnim.desc}</div>
        </div>
      )}

      {/* RESONANCE WINDOW */}
      {g.resonanceWindow && (
        <div style={{ position:'fixed', top:110, left:'50%', transform:'translateX(-50%)', zIndex:300,
          background:'linear-gradient(135deg,#0f0520,#200a40)', border:'2px solid #ffd700',
          padding:'14px 22px', textAlign:'center', boxShadow:'0 0 40px #ffd70066',
          animation:'pulse .8s ease-in-out infinite', width:290 }}>
          <div style={{ fontSize:8, color:'#ffd700', marginBottom:6 }}>💜 VOID ANCHOR EXPOSED</div>
          <div style={{ fontSize:6, color:'#a29bfe', marginBottom:8 }}>The Guardian's true Ether shines through!</div>
          <div style={{ fontSize:6, color:'#ffd700' }}>📖 Use RESONATE in the skill menu</div>
          <div style={{ fontSize:5, color:'#555', marginTop:4 }}>Attempt {(g.resonanceWindow.attempts||0)+1}/2 | Resonant: 82% | Others: 48%</div>
        </div>
      )}

      <div style={{ width:'100%', maxWidth:720, position:'relative', zIndex:1 }}>

        {/* HEADER */}
        <div style={{ textAlign:'center', marginBottom:8 }}>
          <div style={{ fontSize:11, color:'#ffd700', textShadow:'0 0 18px #ffd70099', letterSpacing:3, marginBottom:4 }}>VAELTHAR: EIDOLON CHRONICLES</div>
          <div style={{ fontSize:6, color:'#333' }}>💰{g.gold} | WAVE {g.wave+1}/{WAVES.length} | 📖Lv{slv}{nextLvJP?` (${g.totalJP}/${nextLvJP}JP)`:' ★MAX★'}</div>
          {g.fieldEffect && <div style={{ fontSize:7, marginTop:4, padding:'3px 8px', display:'inline-block',
            background:`${EC[g.fieldEffect.type]||'#555'}15`, border:`1px solid ${EC[g.fieldEffect.type]||'#555'}`,
            color:EC[g.fieldEffect.type]||'#888', animation:'pulse 1.2s infinite' }}>
            🌐 {g.fieldEffect.source} [{g.fieldEffect.type.toUpperCase()}+38%] {g.fieldEffect.turns}t
          </div>}
        </div>

        {chain.length > 0 && !g.comboResult && (
          <div style={{ background:'rgba(255,215,0,.07)', border:'1px solid #ffd70044', padding:'4px 10px', marginBottom:6, textAlign:'center', animation:'pulse 1.1s infinite' }}>
            <span style={{ fontSize:7, color:'#ffd700' }}>⚡ CHAIN: {chain.map(c=>c.el.toUpperCase()).join('→')} — add compatible element!</span>
          </div>
        )}

        {/* BATTLE ARENA */}
        <div style={{ background:'linear-gradient(180deg,#0b1622,#121f30 55%,#0b1320)', border:'2px solid #1a3355',
          padding:'12px 10px', marginBottom:8, position:'relative', minHeight:260, overflow:'visible' }}>
          <div style={{ position:'absolute', bottom:0, left:0, right:0, height:48, opacity:.2,
            background:'repeating-linear-gradient(90deg,transparent 0px,transparent 39px,#1a3355 40px)' }} />

          {/* ENEMIES */}
          <div style={{ display:'flex', justifyContent:'space-around', alignItems:'flex-end', minHeight:165, paddingBottom:6 }}>
            {g.enemies.map(en => {
              const dead = en.hp <= 0
              const isTgt = g.phase === 'target_e' && !dead
              return (
                <div key={en.id} onClick={() => { if (g.pendingSkill?._eid) executeSummon(g.pendingSkill,g.activeChar,en.id); else onEnemyClick(en.id) }}
                  style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:3, opacity:dead?.1:1,
                    cursor:isTgt?'pointer':'default', position:'relative',
                    filter: isTgt ? `drop-shadow(0 0 16px ${en.col}) brightness(1.3)` : hasS(en,'frozen') ? 'brightness(.7) hue-rotate(160deg)' : hasS(en,'berserk') ? `drop-shadow(0 0 12px #c0392b)` : 'none',
                    transform:isTgt?'scale(1.06)':'scale(1)', transition:'all .2s' }}>
                  {(en.floats||[]).map((f, fi) => (
                    <div key={f.id} style={{ position:'absolute', top:-20-fi*18, left:'50%', transform:'translateX(-50%)', color:f.col, fontSize:f.size||10, fontFamily:"'Press Start 2P',monospace", textShadow:`0 0 8px ${f.col}`, animation:'floatUp 1.5s ease-out forwards', pointerEvents:'none', zIndex:200, whiteSpace:'nowrap' }}>{f.text}</div>
                  ))}
                  <div style={{ width:en.mhp>2000?90:en.mhp>700?70:55, height:en.mhp>2000?102:en.mhp>700?78:62,
                    background:`linear-gradient(140deg,${en.col}dd,${en.col}44)`,
                    clipPath:'polygon(50% 0%,100% 25%,100% 75%,50% 100%,0% 75%,0% 25%)',
                    boxShadow:`0 0 22px ${en.col}44`, display:'flex', alignItems:'center', justifyContent:'center',
                    fontSize:dead?22:28, animation:dead?'none':'enemyFloat 2.8s ease-in-out infinite',
                    border:`2px solid ${en.col}77` }}>{dead ? '💀' : ''}</div>
                  <div style={{ fontSize:7, color:en.col, textAlign:'center', maxWidth:120 }}>{en.name}</div>
                  {en.weakTo && !dead && <div style={{ fontSize:5, color:'#fd9644' }}>WEAK:{en.weakTo.map(e=>EI[e]||e).join('')}</div>}
                  <StatusIcons statuses={en.statuses} />
                  {!dead && <div style={{ width:105 }}>
                    <div style={{ display:'flex', gap:2, marginBottom:1 }}>
                      <div style={{ flex:1 }}><div style={{ background:'#0a0a1a', height:3 }}><div style={{ width:`${(en.mtemper>0?(en.temper||0)/en.mtemper:0)*100}%`, height:'100%', background:'#fd9644' }} /></div></div>
                      <div style={{ flex:1 }}><div style={{ background:'#0a0a1a', height:3 }}><div style={{ width:`${(en.mether>0?(en.ether||0)/en.mether:0)*100}%`, height:'100%', background:'#9b59b6' }} /></div></div>
                    </div>
                    <Bar v={en.hp} m={en.mhp} h={6} col={en.col} />
                    <div style={{ fontSize:5, color:'#333', textAlign:'center' }}>{en.hp}/{en.mhp}</div>
                  </div>}
                  {!dead && <div style={{ width:100 }}><Bar v={en.atb} m={100} h={3} col={en.atb>=100?'#ff4757':'#ff9f43'} /></div>}
                </div>
              )
            })}
          </div>

          <div style={{ textAlign:'center', fontSize:6, color:'#1e3a5f', margin:'3px 0', letterSpacing:4 }}>── VS ──</div>

          {/* PARTY SPRITES */}
          <div style={{ display:'flex', justifyContent:'space-around', alignItems:'flex-end', paddingTop:4 }}>
            {g.party.map(m => {
              const job = JOBS[m.job] || {}
              const ready = g.phase === 'battle' && m.hp > 0 && m.atb >= 100
              const isAl = g.phase === 'target_a' && m.hp > 0
              return (
                <div key={m.id}
                  onClick={() => { if (g.phase==='battle') onCharClick(m.id); else if (isAl) onAllyClick(m.id) }}
                  style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:2, cursor:(ready||isAl)?'pointer':'default', position:'relative' }}>
                  {(m.floats||[]).map((f, fi) => (
                    <div key={f.id} style={{ position:'absolute', bottom:60+fi*18, left:'50%', transform:'translateX(-50%)', color:f.col, fontSize:f.size||10, fontFamily:"'Press Start 2P',monospace", textShadow:`0 0 8px ${f.col}`, animation:'floatDown 1.5s ease-out forwards', pointerEvents:'none', zIndex:200, whiteSpace:'nowrap' }}>{f.text}</div>
                  ))}
                  <div style={{ fontSize:10 }}>{job.ico || '⚔'}</div>
                  <CharSprite col={m.col} isDead={m.hp<=0} isReady={ready} isActive={g.activeChar===m.id} guard={m.guard} aura={m.aura} />
                </div>
              )
            })}
          </div>
        </div>

        {/* PARTY STATUS CARDS */}
        <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:5, marginBottom:7 }}>
          {g.party.map(m => {
            const job = JOBS[m.job] || { name:'?', col:'#888', ico:'?' }
            const ready = g.phase === 'battle' && m.hp > 0 && m.atb >= 100
            const limitReady = (m.limit||0) >= 100
            const isAscended = (job.tier||0) === 5
            return (
              <div key={m.id} onClick={() => g.phase==='battle' && onCharClick(m.id)} style={{
                background:'rgba(4,4,16,.97)',
                border:`1px solid ${limitReady?'#ffd700':ready?m.col:g.activeChar===m.id?m.col:'#1a3355'}`,
                padding:'5px', opacity:m.hp<=0?.3:1, cursor:ready?'pointer':'default',
                boxShadow: limitReady?'0 0 12px #ffd70066':isAscended?`0 0 6px ${job.col}33`:ready?`0 0 8px ${m.col}44`:'none',
                transition:'all .2s' }}>
                <div style={{ display:'flex', justifyContent:'space-between', marginBottom:2 }}>
                  <span style={{ fontSize:7, color:m.col }}>{m.name}</span>
                  <span style={{ fontSize:9 }}>{job.ico}</span>
                </div>
                <div style={{ fontSize:5, color:job.col, marginBottom:2 }}>{job.name}{isAscended?'★':''}</div>
                <div style={{ fontSize:5, color:'#444' }}>HP</div><Bar v={m.hp} m={m.mhp} h={6} col="hp" />
                <div style={{ fontSize:5, color:'#2980b9', marginTop:1 }}>MP</div><Bar v={m.mp} m={m.mmp} h={4} col="#2980b9" />
                <div style={{ fontSize:5, color:'#444', marginTop:1 }}>ATB</div><Bar v={m.atb} m={100} h={3} col={m.atb>=100?'#ffd700':'#27ae60'} />
                <TEBars temper={m.temper||0} mtemper={m.mtemper||1} ether={m.ether||0} mether={m.mether||1} />
                {limitReady
                  ? <div style={{ fontSize:5, color:'#ffd700', animation:'blink .4s steps(1) infinite', marginTop:2 }}>★ LIMIT READY</div>
                  : <><div style={{ fontSize:4, color:'#ffd70088', marginTop:2 }}>LIMIT</div><Bar v={m.limit||0} m={100} h={3} col="#ffd700" /></>
                }
                <StatusIcons statuses={m.statuses} />
                <div style={{ display:'flex', gap:2, marginTop:2, flexWrap:'wrap' }}>
                  {m.guard && <span style={{ fontSize:6, color:'#74b9ff' }}>🛡</span>}
                  {m.aura  && <span style={{ fontSize:6, color:'#ffd700' }}>🌟</span>}
                  {m.haste && <span style={{ fontSize:6, color:'#00cec9' }}>⏩</span>}
                  {m.hp<=0 && <span style={{ fontSize:5, color:'#e74c3c' }}>⚰KO</span>}
                </div>
              </div>
            )
          })}
        </div>

        {/* SKILL MENU */}
        {g.phase === 'skill' && ac && (() => {
          const lb = LB[ac.job]; const limitReady = (ac.limit||0) >= 100
          const job = JOBS[ac.job]; const isAscended = (job?.tier||0) === 5
          return (
            <div style={{ background:'rgba(2,2,12,.98)', border:`2px solid ${isAscended?(job?.col||ac.col):ac.col}`, padding:'10px', marginBottom:8 }}>
              <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6, alignItems:'center' }}>
                <span style={{ fontSize:9, color:ac.col }}>{ac.name} [{job?.name||'?'}]{isAscended?'★':''}</span>
                <div style={{ display:'flex', gap:6, alignItems:'center' }}>
                  <span style={{ fontSize:6, color:'#fd9644' }}>TMP:{ac.temper}</span>
                  <span style={{ fontSize:6, color:'#9b59b6' }}>ETH:{ac.ether}</span>
                  <button onClick={cancelToBattle} style={{ background:'transparent', border:'1px solid #333', color:'#555', fontSize:7, padding:'2px 6px', cursor:'pointer', fontFamily:'inherit' }}>✕</button>
                </div>
              </div>
              {/* Passive display */}
              {job?.passive && <div style={{ fontSize:5, color:job.col, marginBottom:6, padding:'3px 6px', background:`${job.col}11`, border:`1px solid ${job.col}44` }}>★ PASSIVE: {job.passive.desc}</div>}
              {/* Resonate button when active */}
              {g.resonanceWindow && <button onClick={() => tryResonate(ac.id)} style={{ width:'100%', marginBottom:8, padding:'10px', background:'linear-gradient(90deg,#1a0a3a,#2a0a5a)', border:'2px solid #ffd700', color:'#ffd700', cursor:'pointer', fontFamily:'inherit', fontSize:8, boxShadow:'0 0 20px #ffd70066', animation:'pulse .8s infinite' }}>
                📖 RESONATE (30 MP) — {['summoner','darksummoner','primalbinder','vaelthornsvoice'].includes(ac.job)?'82%':'48%'} success — Free the Guardian!
              </button>}
              <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:6 }}>
                {(job?.sk||[]).map(sk => {
                  const ok = ac.mp >= (sk.mp||0) && !(hasS(ac,'silence') && (sk.mp||0) > 0)
                  const c2 = chain.length>0 && CELS.has(sk.el||'') && getC2(chain[chain.length-1].el, sk.el)
                  const c3 = chain.length>=2 && CELS.has(sk.el||'') && getC3(chain[0].el, chain[1].el, sk.el)
                  return (
                    <button key={sk.id} onClick={() => onSkillClick(sk)} disabled={!ok} style={{
                      background: ok?'rgba(18,18,44,.9)':'rgba(10,10,10,.7)',
                      border:`1px solid ${c3?'#ff6b35':c2?'#ffd700':(sk.el&&sk.el!=='none'?EC[sk.el]||'#333':'#333')}`,
                      color:ok?'#ddd':'#333', padding:'7px', cursor:ok?'pointer':'not-allowed',
                      textAlign:'left', fontFamily:'inherit', fontSize:7,
                      boxShadow:c3?'0 0 12px #ff6b3566':c2?'0 0 8px #ffd70044':'none' }}
                      onMouseEnter={e => { if (ok) e.currentTarget.style.background='rgba(45,45,80,.9)' }}
                      onMouseLeave={e => { e.currentTarget.style.background=ok?'rgba(18,18,44,.9)':'rgba(10,10,10,.7)' }}>
                      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:2 }}>
                        <span>{sk.ico||'⚔'} {sk.n}</span>
                        <span style={{ color:'#2980b9' }}>{sk.mp||0}MP</span>
                      </div>
                      <div style={{ display:'flex', gap:4, alignItems:'center', flexWrap:'wrap' }}>
                        {sk.el && sk.el !== 'none' && <span style={{ fontSize:6, color:EC[sk.el]||'#666' }}>[{sk.el.toUpperCase()}]</span>}
                        {sk.el && ET[sk.el] && <span style={{ fontSize:5, color:'#444' }}>×{ET[sk.el].hits}hit</span>}
                        <span style={{ fontSize:5, color:'#444' }}>{sk.t==='magic'?'🔮ETH':sk.t==='phys'?'⚔TMP':sk.t==='heal'?'💚':sk.t==='summon'?'📖':'✦'}</span>
                        {sk.sts && <span style={{ fontSize:5, color:SD[sk.sts.t]?.col||'#888' }}>{SD[sk.sts.t]?.ico}({Math.round((sk.sts.ch||0)*100)}%)</span>}
                        {(c3||c2) && <span style={{ fontSize:5, color:c3?'#ff6b35':'#ffd700', animation:'blink .45s steps(1) infinite' }}>{c3?'⚡3W!':'⚡2W!'}</span>}
                      </div>
                    </button>
                  )
                })}
              </div>
              {/* LIMIT BREAK */}
              {limitReady && lb && <button onClick={() => executeLimitBreak(ac.id)} style={{ marginTop:8, width:'100%', padding:'10px',
                background:`linear-gradient(90deg,${lb.col}22,${lb.col}11)`, border:`2px solid ${lb.col}`,
                color:lb.col, cursor:'pointer', fontFamily:'inherit', fontSize:8,
                boxShadow:`0 0 20px ${lb.col}66`, animation:`limitPulse 1s ease-in-out infinite` }}>
                💥 {lb.ico} {lb.n}
              </button>}
              {/* ITEMS */}
              <div style={{ marginTop:8, display:'flex', gap:5, flexWrap:'wrap' }}>
                {Object.entries(ITEM_DEFS).map(([key, def]) => {
                  const count = g.items[key] || 0; if (count <= 0) return null
                  return <button key={key} onClick={() => { g.pendingSkill={itemKey:key}; g.itemMode=true; g.phase='target_a'; render() }} style={{ background:`${def.col}11`, border:`1px solid ${def.col}55`, color:def.col, fontSize:6, padding:'4px 8px', cursor:'pointer', fontFamily:'inherit' }}>
                    {def.ico} {def.name} ×{count}
                  </button>
                })}
              </div>
            </div>
          )
        })()}

        {/* SUMMON MENU */}
        {g.phase === 'summon_menu' && ac && (() => {
          const slv2 = sLv(g.totalJP)
          const elems = Object.keys(EID)
          const eids = EID[g.summonTab] || []
          return (
            <div style={{ background:'rgba(2,2,12,.99)', border:'2px solid #ffd700', padding:'10px', marginBottom:8, boxShadow:'0 0 32px #ffd70033' }}>
              <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8 }}>
                <span style={{ fontSize:8, color:'#ffd700' }}>📖 GUARDIAN CODEX [Resonant Lv{slv2}]</span>
                <button onClick={cancelToSkill} style={{ background:'transparent', border:'1px solid #333', color:'#555', fontSize:7, padding:'2px 6px', cursor:'pointer', fontFamily:'inherit' }}>✕</button>
              </div>
              <div style={{ display:'flex', gap:4, marginBottom:10, flexWrap:'wrap' }}>
                {elems.map(el => <button key={el} onClick={() => { gs.current.summonTab=el; render() }} style={{ background:g.summonTab===el?`${EC[el]}22`:'rgba(10,10,20,.8)', border:`1px solid ${g.summonTab===el?EC[el]:'#222'}`, color:g.summonTab===el?EC[el]:'#444', fontSize:9, padding:'4px 6px', cursor:'pointer', fontFamily:'inherit' }}>{EI[el]}</button>)}
              </div>
              <div style={{ fontSize:6, color:'#444', marginBottom:8 }}>
                {EI[g.summonTab]} {g.summonTab.toUpperCase()} Guardians — {ET[g.summonTab]?.hits}×hit pattern — window: {ET[g.summonTab]?.winMs}ms
              </div>
              <div style={{ display:'flex', flexDirection:'column', gap:5 }}>
                {[...eids].reverse().map((eid, ri) => {
                  const ti = eids.length - 1 - ri
                  const unlocked = slv2 >= (SUMMON_REQ[g.summonTab]?.[ti] || 99)
                  const canAfford = ac.mp >= eid.mp
                  const isGod = eid.t === 1
                  return (
                    <div key={eid.name} style={{ background:unlocked?(isGod?`linear-gradient(90deg,${EC[g.summonTab]}14,rgba(255,215,0,.06))`:'rgba(14,14,38,.9)'):'rgba(8,8,8,.9)', border:`1px solid ${unlocked?(isGod?'#ffd700':EC[g.summonTab]||'#333'):'#1a1a1a'}`, padding:'7px 9px', display:'flex', alignItems:'center', gap:9 }}>
                      <div style={{ minWidth:65, textAlign:'center' }}>
                        <div style={{ fontSize:5.5, color:isGod?'#ffd700':eid.t===2?'#a29bfe':eid.t===3?'#2ecc71':'#888', marginBottom:3 }}>{eid.tl}</div>
                        <div style={{ fontSize:unlocked?24:18, filter:unlocked?`drop-shadow(0 0 8px ${EC[g.summonTab]})`:'grayscale(1) opacity(.25)' }}>{unlocked?eid.ico:'❓'}</div>
                      </div>
                      <div style={{ flex:1 }}>
                        {unlocked ? <>
                          <div style={{ fontSize:8, color:isGod?'#ffd700':EC[g.summonTab]||'#ddd', marginBottom:2 }}>{eid.name}</div>
                          <div style={{ fontSize:5.5, color:'#555', marginBottom:2 }}>{eid.sub}</div>
                          <div style={{ fontSize:6, color:'#777' }}>{eid.d}</div>
                          {eid.sts && <div style={{ fontSize:5.5, color:SD[eid.sts.t]?.col||'#888', marginTop:2 }}>{SD[eid.sts.t]?.ico} {eid.sts.t} ({Math.round((eid.sts.ch||0)*100)}%)</div>}
                          {(eid.restoreEther||0) > 0 && <div style={{ fontSize:5.5, color:'#9b59b6', marginTop:1 }}>🟪 Restores {eid.restoreEther} Ether to party</div>}
                          {eid.eff?.startsWith('field_') && <div style={{ fontSize:5.5, color:'#a29bfe', marginTop:1 }}>★ Creates elemental field</div>}
                        </> : <>
                          <div style={{ fontSize:8, color:'#333' }}>??? Guardian</div>
                          <div style={{ fontSize:6, color:'#333' }}>Resonant Lv{SUMMON_REQ[g.summonTab]?.[ti]} required</div>
                        </>}
                      </div>
                      <div style={{ textAlign:'center', minWidth:55 }}>
                        {unlocked ? <>
                          <div style={{ fontSize:7, color:canAfford?'#2980b9':'#e74c3c', marginBottom:5 }}>{eid.mp}MP</div>
                          <button onClick={() => onSummonSelect(eid)} disabled={!canAfford} style={{ background:canAfford?`${EC[g.summonTab]}22`:'rgba(10,10,10,.5)', border:`1px solid ${canAfford?EC[g.summonTab]:'#333'}`, color:canAfford?EC[g.summonTab]:'#333', fontSize:6, padding:'4px 8px', cursor:canAfford?'pointer':'not-allowed', fontFamily:'inherit' }}>{canAfford?'CALL!':'NO MP'}</button>
                        </> : <div style={{ fontSize:6, color:'#333' }}>🔒 Lv{SUMMON_REQ[g.summonTab]?.[ti]}</div>}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )
        })()}

        {/* TARGET SELECT */}
        {(g.phase === 'target_e' || g.phase === 'target_a') && (
          <div style={{ background:'rgba(2,2,12,.98)', border:'1px solid #1a3355', padding:'10px', marginBottom:8 }}>
            <div style={{ textAlign:'center', marginBottom:8 }}>
              <div style={{ fontSize:9, color:'#ffd700', marginBottom:10 }}>🎯 {g.phase==='target_e'?'Select Enemy':'Select Ally'}</div>
              <div style={{ display:'flex', justifyContent:'center', gap:8, flexWrap:'wrap' }}>
                {g.phase === 'target_e' && g.enemies.filter(e => e.hp > 0).map(en => (
                  <button key={en.id} onClick={() => { if(g.pendingSkill?._eid)executeSummon(g.pendingSkill,g.activeChar,en.id);else onEnemyClick(en.id) }} style={{ background:`${en.col}12`, border:`2px solid ${en.col}`, color:en.col, padding:'7px 12px', cursor:'pointer', fontFamily:'inherit', fontSize:7 }}>
                    {en.name}
                    {en.weakTo && <div style={{ fontSize:5, color:'#fd9644', marginTop:2 }}>WEAK:{en.weakTo.map(e=>EI[e]||e).join('')}</div>}
                    <div style={{ fontSize:5, color:'#555', marginTop:1 }}>TMP:{en.temper} ETH:{en.ether}</div>
                    <StatusIcons statuses={en.statuses} />
                  </button>
                ))}
                {g.phase === 'target_a' && g.party.filter(m => g.itemMode && g.pendingSkill?.itemKey==='soulmber' ? m.hp<=0 : m.hp>0).map(m => (
                  <button key={m.id} onClick={() => onAllyClick(m.id)} style={{ background:`${m.col}12`, border:`2px solid ${m.col}`, color:m.col, padding:'7px 12px', cursor:'pointer', fontFamily:'inherit', fontSize:7 }}>
                    {m.name}<div style={{ fontSize:5, color:'#555', marginTop:2 }}>TMP:{m.temper} ETH:{m.ether}</div>
                  </button>
                ))}
              </div>
              <button onClick={() => { g.pendingSkill?._eid?cancelToSkill():cancelToBattle(); render() }} style={{ marginTop:8, background:'transparent', border:'1px solid #333', color:'#444', fontSize:7, padding:'3px 8px', cursor:'pointer', fontFamily:'inherit' }}>BACK</button>
            </div>
          </div>
        )}

        {/* BATTLE LOG */}
        <div style={{ background:'rgba(0,0,0,.88)', border:'1px solid #1a3355', padding:'7px 10px', marginBottom:7, height:92, overflowY:'auto' }}>
          {g.log.slice(-7).map((line, i) => (
            <div key={i} style={{ fontSize:7, marginBottom:3, lineHeight:1.5,
              color: line.includes('COMBO')||line.includes('★')?'#ffd700':
                     line.includes('REACTION')||line.includes('SHATTER')||line.includes('PURGE')?'#ff9f43':
                     line.includes('LIMIT BREAK')||line.includes('LIMIT READY')?'#ffd700':
                     line.includes('RESONA')?'#a29bfe':
                     line.includes('💀')||line.includes('DEFEAT')?'#e74c3c':
                     line.includes('💚')||line.includes('+HP')?'#2ecc71':
                     line.startsWith('👹')||line.includes('💢')?'#ff6b35':
                     line.includes('🟪')||line.includes('Ether')?'#9b59b6':
                     line.includes('🟧')||line.includes('Temper')?'#fd9644':
                     line.includes('WEAK!')?'#ff6b35':
                     line.includes('CRIT')?'#ffd700':
                     line.includes('📖')||line.includes('calls')?'#ffd700':'#444' }}>{line}</div>
          ))}
        </div>

        {/* LEGEND */}
        <div style={{ background:'rgba(2,2,12,.9)', border:'1px solid #111', padding:'6px 10px' }}>
          <div style={{ fontSize:5.5, color:'#222', lineHeight:1.8 }}>
            🟧 TEMPER = physical defense (bleed, slow, knockdown) | 🟪 ETHER = magic defense (burn, stun, freeze, curse)<br />
            ⚡ WEAK = +60% dmg | ★ CRIT = ×1.55 | 💔 ARMOR BREAK = +15% when at 0 | 🛡 DEFLECT = 50% dmg reduction<br />
            SURGE timing: ⚡Thunder×4fast | 🔥Fire×3med | ❄Ice×1big | 🌀Wind×3fast | 🌊Water×2aoe | 🪨Earth×1heavy | 🔱LIMIT fills when hit
          </div>
        </div>
      </div>

      {/* WAVE CLEAR OVERLAY */}
      {g.phase === 'waveClear' && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,.93)', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', zIndex:50, padding:20 }}>
          <div style={{ fontSize:13, color:'#ffd700', textShadow:'0 0 28px #ffd700', marginBottom:10 }}>✨ WAVE CLEARED ✨</div>
          {g.enemies.find(e => e.isGuardian) && <div style={{ background:'rgba(255,215,0,.06)', border:'1px solid #ffd70033', padding:'12px 20px', marginBottom:14, maxWidth:400, textAlign:'center' }}>
            <div style={{ fontSize:7, color:'#ffd700', marginBottom:6 }}>GUARDIAN FREED</div>
            <div style={{ fontSize:6, color:'#555' }}>The Void Anchor shatters. Their Ether flows clean. They will answer your call.</div>
          </div>}
          <div style={{ fontSize:8, color:'#aaa', marginBottom:5 }}>Resonant Lv: {slv} | JP: {g.totalJP}{nextLvJP?` / ${nextLvJP}`:''}</div>
          {nextLvJP && <div style={{ fontSize:7, color:'#ffd700', marginBottom:4 }}>Next unlock: {nextLvJP-g.totalJP} JP</div>}
          <div style={{ fontSize:7, color:'#555', marginBottom:3 }}>HP/MP/Temper/Ether partially restored</div>
          <div style={{ fontSize:7, color:'#333', marginBottom:12 }}>Items: {Object.entries(g.items).filter(([,v])=>v>0).map(([k,v])=>`${ITEM_DEFS[k]?.ico||k}×${v}`).join(' ')}</div>
          {g.wave < WAVES.length-1 && <div style={{ fontSize:7, color:'#333', marginBottom:14 }}>
            Next: {WAVES[g.wave+1]?.map(e=>e.name).join(' & ')}
            {WAVES[g.wave+1]?.find(e=>e.isGuardian) && <div style={{ fontSize:6, color:'#8e44ad', marginTop:4 }}>⚠ Corrupted Guardian ahead. Bring Zane.</div>}
          </div>}
          <div style={{ display:'flex', gap:10 }}>
            <button onClick={() => { gs.current.phase='job_screen'; gs.current.jobScreenChar='kael'; render() }} style={{ background:'transparent', border:'2px solid #a29bfe', color:'#a29bfe', fontSize:8, padding:'8px 14px', cursor:'pointer', fontFamily:'inherit' }}>⚜ JOBS</button>
            <button onClick={nextWave} style={{ background:'transparent', border:'2px solid #ffd700', color:'#ffd700', fontSize:10, padding:'10px 22px', cursor:'pointer', fontFamily:'inherit', textShadow:'0 0 8px #ffd700' }}>NEXT WAVE ▶</button>
          </div>
        </div>
      )}

      {/* JOB SCREEN */}
      {g.phase === 'job_screen' && (() => {
        const jp = g.totalJP
        const curC = g.party.find(c => c.id === g.jobScreenChar) || g.party[0]
        const tierCols = ['','#e74c3c','#fdcb6e','#a29bfe','#c0392b','#ff4757']
        return (
          <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,.96)', display:'flex', flexDirection:'column', alignItems:'center', zIndex:60, padding:20, overflowY:'auto' }}>
            <div style={{ fontSize:11, color:'#a29bfe', textShadow:'0 0 20px #a29bfe', marginBottom:10, marginTop:20 }}>⚜ JOB ASSIGNMENT</div>
            <div style={{ fontSize:7, color:'#444', marginBottom:12 }}>JP: {jp}</div>
            <div style={{ display:'flex', gap:7, marginBottom:10, flexWrap:'wrap' }}>
              {g.party.map(c => <button key={c.id} onClick={() => { gs.current.jobScreenChar=c.id; render() }} style={{ background:g.jobScreenChar===c.id?`${c.col}22`:'rgba(10,10,10,.8)', border:`1px solid ${g.jobScreenChar===c.id?c.col:'#222'}`, color:g.jobScreenChar===c.id?c.col:'#444', fontSize:8, padding:'6px 10px', cursor:'pointer', fontFamily:'inherit' }}>{c.name}</button>)}
            </div>
            <div style={{ fontSize:7, color:'#555', marginBottom:10 }}>{curC.name} — <span style={{ color:JOBS[curC.job]?.col||'#888' }}>{JOBS[curC.job]?.name||'?'}</span></div>
            <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:7, maxWidth:620, width:'100%', marginBottom:16 }}>
              {Object.entries(JOBS).map(([jk, jv]) => {
                const unlocked = jp >= (jv.jpReq||0); const isCurrent = curC.job === jk; const lb = LB[jk]
                return (
                  <div key={jk} onClick={() => { if (unlocked) { curC.job=jk; doLog(`✨ ${curC.name} → ${jv.name}!`); render() } }} style={{ background:isCurrent?`${jv.col}22`:'rgba(10,10,20,.8)', border:`1px solid ${isCurrent?jv.col:unlocked?'#2a3a5a':'#111'}`, padding:'8px', cursor:unlocked?'pointer':'not-allowed', opacity:unlocked?1:.4, boxShadow:isCurrent?`0 0 10px ${jv.col}44`:'none', transition:'all .2s' }}>
                    <div style={{ display:'flex', gap:5, alignItems:'center', marginBottom:4 }}>
                      <span style={{ fontSize:14 }}>{jv.ico}</span>
                      <div>
                        <div style={{ fontSize:7, color:jv.col }}>{jv.name}{(jv.tier||0)===5?'★':''}</div>
                        <div style={{ fontSize:5, color:tierCols[jv.tier||0]||'#888' }}>{['','Tier 1','Tier 2','Tier 3','Apex','Ascended'][jv.tier||0]||''}{jv.jpReq?` · ${jv.jpReq}JP`:' · Free'}</div>
                      </div>
                    </div>
                    <div style={{ fontSize:5, color:'#555', marginBottom:3 }}>{jv.desc}</div>
                    {jv.passive && <div style={{ fontSize:5, color:jv.col, marginBottom:2 }}>★ {jv.passive.desc}</div>}
                    {lb && <div style={{ fontSize:5, color:lb.col }}>LB: {lb.ico} {lb.n}</div>}
                    {isCurrent && <div style={{ fontSize:5, color:jv.col, marginTop:3 }}>★ EQUIPPED</div>}
                  </div>
                )
              })}
            </div>
            <button onClick={() => { gs.current.phase='waveClear'; render() }} style={{ background:'transparent', border:'2px solid #ffd700', color:'#ffd700', fontSize:9, padding:'8px 22px', cursor:'pointer', fontFamily:'inherit', marginBottom:20 }}>← BACK</button>
          </div>
        )
      })()}

      {/* VICTORY */}
      {g.phase === 'victory' && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,.94)', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', zIndex:50 }}>
          <div style={{ fontSize:13, color:'#ffd700', textShadow:'0 0 32px #ffd700', marginBottom:8 }}>🏆 VAELTHAR SAVED 🏆</div>
          <div style={{ fontSize:7, color:'#2ecc71', marginBottom:6, textAlign:'center' }}>The last Void Anchor is gone.<br />The Guardians' Ether flows clean again.</div>
          <div style={{ fontSize:7, color:'#ffd700', marginBottom:4 }}>💰 {g.gold}G | JP: {g.totalJP}</div>
          <div style={{ fontSize:7, color:'#a29bfe', marginBottom:20 }}>Resonant Lv: {slv}/7 {slv>=7?'— VAELTHORN BONDED! ★ COMPLETE ★':'— Earn JP for Vaelthorn (920JP)'}</div>
          <button onClick={restart} style={{ background:'transparent', border:'2px solid #2ecc71', color:'#2ecc71', fontSize:10, padding:'12px 28px', cursor:'pointer', fontFamily:'inherit' }}>PLAY AGAIN</button>
        </div>
      )}

      {/* DEFEAT */}
      {g.phase === 'defeat' && (
        <div style={{ position:'fixed', inset:0, background:'rgba(0,0,0,.96)', display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', zIndex:50 }}>
          <div style={{ fontSize:13, color:'#e74c3c', textShadow:'0 0 32px #e74c3c', marginBottom:8 }}>💀 DEFEATED 💀</div>
          <div style={{ fontSize:8, color:'#555', marginBottom:20 }}>The Null Conclave wins… for now.</div>
          <button onClick={restart} style={{ background:'transparent', border:'2px solid #e74c3c', color:'#e74c3c', fontSize:10, padding:'12px 28px', cursor:'pointer', fontFamily:'inherit' }}>TRY AGAIN</button>
        </div>
      )}

      <style>{`
        @keyframes enemyFloat   { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-8px)} }
        @keyframes blink        { 0%,100%{opacity:1} 50%{opacity:0} }
        @keyframes pulse        { 0%,100%{opacity:1} 50%{opacity:.5} }
        @keyframes limitPulse   { 0%,100%{opacity:.8} 50%{opacity:1} }
        @keyframes surgePulse   { 0%,100%{transform:scale(1)} 50%{transform:scale(1.1)} }
        @keyframes comboPop     { 0%{transform:translate(-50%,-55%) scale(.3);opacity:0} 60%{transform:translate(-50%,-55%) scale(1.08)} 100%{transform:translate(-50%,-55%) scale(1);opacity:1} }
        @keyframes fadeIn       { from{opacity:0} to{opacity:1} }
        @keyframes godPulse     { 0%,100%{transform:scale(1)} 50%{transform:scale(1.08)} }
        @keyframes floatUp      { 0%{transform:translateX(-50%) translateY(0);opacity:1} 100%{transform:translateX(-50%) translateY(-60px);opacity:0} }
        @keyframes floatDown    { 0%{transform:translateX(-50%) translateY(0);opacity:1} 100%{transform:translateX(-50%) translateY(-55px);opacity:0} }
        @keyframes countdownBar { from{transform:scaleX(1)} to{transform:scaleX(0)} }
      `}</style>
    </div>
  )
}
