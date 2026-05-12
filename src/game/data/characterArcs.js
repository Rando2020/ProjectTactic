export const HISTORY_CYCLE_THEMES = {
  centralQuestion: 'When history repeats, do you preserve the lie that kept people alive, expose the truth that may restart the war, or destroy the cycle entirely?',
  ancientLie:
    'The Concord did not end the First Breach. It buried the soldiers, Guardians, and witnesses who refused to let power rewrite the cost of survival.',
  presentPattern:
    'Every region is reliving one old wound through a new generation: Ashvale repeats abandonment, Mirefen repeats silencing, Stormglass repeats militarized obedience, and the Null Conclave repeats extraction disguised as salvation.',
  playerPromise:
    'Each major character should make the player feel that a tactical choice is also a historical argument.'
}

export const CHARACTER_ARCHETYPES = {
  listener: {
    id: 'listener',
    name: 'The Listener',
    cycleFunction: 'Hears the buried pain and proves the old war is not dead.',
    danger: 'Can mistake empathy for permission to carry everyone else’s fate.'
  },
  destroyer: {
    id: 'destroyer',
    name: 'The Destroyer',
    cycleFunction: 'Believes mercy toward the old order is how the cycle survives.',
    danger: 'Can become the next tyrant by calling every compromise cowardice.'
  },
  preserver: {
    id: 'preserver',
    name: 'The Preserver',
    cycleFunction: 'Keeps institutions intact because collapse also kills innocents.',
    danger: 'Can defend the lie long after the lie becomes the weapon.'
  },
  witness: {
    id: 'witness',
    name: 'The Witness',
    cycleFunction: 'Records what power wants forgotten.',
    danger: 'Can become passive, mistaking documentation for intervention.'
  },
  inheritor: {
    id: 'inheritor',
    name: 'The Inheritor',
    cycleFunction: 'Benefits from the old crime and must decide what inheritance is worth keeping.',
    danger: 'Can seek redemption without surrendering privilege.'
  },
  weaponmaker: {
    id: 'weaponmaker',
    name: 'The Weaponmaker',
    cycleFunction: 'Turns suffering into systems, tools, and battlefield doctrine.',
    danger: 'Can confuse usefulness with righteousness.'
  }
}

export const CHARACTER_ARCS = {
  zane: {
    characterId: 'zane',
    cycleArchetypeId: 'listener',
    historicalEcho: 'Echoes the erased Resonants who heard Guardian pain during the First Breach and were later written out as heretics.',
    personalWound:
      'Zane wants pain to mean something because meaningless suffering would make the world feel unforgivable.',
    falseBelief:
      'If he can understand the wound, he can save everyone touched by it.',
    pressurePoint:
      'The more Guardians he saves, the more people expect him to become a living bridge instead of a person.',
    destroysTheCycleBy:
      'Refusing both erasure and martyrdom. Zane must learn that remembering the truth does not require becoming the new sacrifice.',
    battlefieldExpression:
      'Resonance Windows, Guardian-saving objectives, and tactical choices where killing is faster but listening changes rewards, trust, and future encounters.',
    sampleLine: 'If the old war is speaking through them, then we do not get to call silence peace.'
  },
  mira: {
    characterId: 'mira',
    cycleArchetypeId: 'witness',
    historicalEcho: 'Echoes field surgeons who documented Accord-era atrocities before their ledgers were burned by the victors.',
    personalWound:
      'Mira has seen belief become an excuse for bad medicine, bad orders, and dead civilians.',
    falseBelief:
      'Only what can be proven should be trusted, even when proof arrives too late to save anyone.',
    pressurePoint:
      'Zane keeps hearing truths she cannot measure, while the Conclave keeps producing evidence that looks clean enough to fool institutions.',
    destroysTheCycleBy:
      'Turning skepticism into disciplined witness. She does not have to believe prophecy, but she does have to protect testimony before power edits it.',
    battlefieldExpression:
      'Cleanse, revive, and triage choices that preserve civilians, wounded enemies, and corrupted Guardians as future witnesses.',
    sampleLine: 'I do not need the world to be holy. I need it to stop burying bodies under beautiful words.'
  },
  rusk: {
    characterId: 'rusk',
    cycleArchetypeId: 'preserver',
    historicalEcho: 'Echoes local captains who held towns together while nobles and orders negotiated which truths civilians were allowed to know.',
    personalWound:
      'Rusk survived by trusting walls, rosters, watches, and clear chains of command.',
    falseBelief:
      'Order is always kinder than upheaval because order keeps children alive tonight.',
    pressurePoint:
      'The same civic order he protects may be enforcing a lie that guarantees tomorrow’s war.',
    destroysTheCycleBy:
      'Choosing people over procedure when the two finally split.',
    battlefieldExpression:
      'Protection, Cover, and objective defense missions where preserving life matters more than perfect victory conditions.',
    sampleLine: 'I can live with ugly orders. I cannot live with orders that make graves and call them foundations.'
  },
  elian: {
    characterId: 'elian',
    cycleArchetypeId: 'destroyer',
    historicalEcho: 'Echoes the Ashen Companies, common soldiers who won the First Breach and were erased so noble houses could inherit the victory.',
    personalWound:
      'Elian was raised on stories of unnamed soldiers who saved cities and received ditches instead of statues.',
    falseBelief:
      'If an institution was built on erasure, anything short of burning it down is collaboration.',
    pressurePoint:
      'He is often right about the lie, but dangerously wrong about who deserves to survive its destruction.',
    destroysTheCycleBy:
      'Learning that breaking history is not the same as breaking people who were born inside it.',
    battlefieldExpression:
      'Aggressive anti-armor, anti-institution objectives, sabotage maps, and optional routes that trade reputation for liberation gains.',
    sampleLine: 'You keep asking who gets hurt if we tear the bell down. I am asking who keeps bleeding if we leave it standing.'
  },
  serra: {
    characterId: 'serra',
    cycleArchetypeId: 'inheritor',
    historicalEcho: 'Descends from a sanctioned Concord bloodline whose house prospered after the erased soldiers disappeared from record.',
    personalWound:
      'Serra was trained to believe duty means carrying a beautiful lie with perfect posture.',
    falseBelief:
      'A rotten inheritance can be redeemed by noble behavior without surrendering the power it created.',
    pressurePoint:
      'The party needs her access, but her access is proof that the system still rewards the old crime.',
    destroysTheCycleBy:
      'Choosing material consequence over symbolic guilt: opening archives, burning claims, returning land, and losing status on purpose.',
    battlefieldExpression:
      'Command abilities, formation bonuses, and deployment advantages that become morally complicated when tied to noble authority.',
    sampleLine: 'My family taught me how to inherit a country. No one taught me how to give one back.'
  },
  caldus: {
    characterId: 'caldus',
    cycleArchetypeId: 'weaponmaker',
    historicalEcho: 'Repeats the Accord engineers who turned Guardian pain into anchors, prisons, and obedient battlefield miracles.',
    personalWound:
      'Caldus believes unstructured grief becomes chaos, so every wound must be converted into a usable system.',
    falseBelief:
      'If suffering can be made useful, then its use can be justified.',
    pressurePoint:
      'He can stabilize breaches faster than anyone else, but every solution teaches the world to depend on controlled cruelty.',
    destroysTheCycleBy:
      'Either admitting that some power should not be optimized or becoming the clearest proof that the old war has returned.',
    battlefieldExpression:
      'Boss encounters, corrupted anchor mechanics, forced objective dilemmas, and enemies whose strength comes from harvested Guardian resonance.',
    sampleLine: 'You call it cruelty because you are standing close enough to hear the screaming. Step back, and it becomes infrastructure.'
  }
}

export const getCharacterArc = (characterId) => CHARACTER_ARCS[characterId]

export const getCharacterArchetype = (archetypeId) => CHARACTER_ARCHETYPES[archetypeId]

export const getCharacterArcWithArchetype = (characterId) => {
  const arc = getCharacterArc(characterId)
  if (!arc) return null

  return {
    ...arc,
    archetype: getCharacterArchetype(arc.cycleArchetypeId)
  }
}

export const getPlayableCycleCharacters = () =>
  ['zane', 'mira', 'rusk', 'elian', 'serra'].map(getCharacterArcWithArchetype).filter(Boolean)
