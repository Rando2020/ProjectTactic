import { useEffect, useMemo, useState } from 'react'
import CombatPrototype from '../../VaeltharChronicles.jsx'
import './styles/vaelthar.css'

import { TOWNS, getTown } from './data/towns.js'
import { getMission } from './data/missions.js'
import { DEFAULT_SETTINGS } from './data/settings.js'
import { STORY_CHAPTERS, getStoryChapter, getNextAvailableChapter } from './data/story.js'
import { createNewSave, loadSave, writeSave, clearSave } from './systems/saveSystem.js'
import { applyMissionResult, buildMissionResult } from './systems/missionResultSystem.js'

import StoryScene from './components/StoryScene.jsx'
import WorldMap from './components/WorldMap.jsx'
import TownScreen from './components/TownScreen.jsx'
import QuestLog from './components/QuestLog.jsx'
import CodexScreen from './components/CodexScreen.jsx'
import MissionBriefing from './components/MissionBriefing.jsx'
import BattleResultScreen from './components/BattleResultScreen.jsx'
import SettingsPanel from './components/SettingsPanel.jsx'
import ControlsHelp from './components/ControlsHelp.jsx'
import LoadingScreen from './components/LoadingScreen.jsx'
import OnboardingOverlay from './components/OnboardingOverlay.jsx'
import Toast from './components/Toast.jsx'
import PartyScreen from './components/PartyScreen.jsx'
import InventoryScreen from './components/InventoryScreen.jsx'
import JobBoard from './components/JobBoard.jsx'
import SummonArchive from './components/SummonArchive.jsx'
import InnScreen from './components/InnScreen.jsx'

export default function VaeltharChronicles() {
  const [save, setSave] = useState(() => loadSave() || createNewSave())
  const [settings, setSettings] = useState(() => DEFAULT_SETTINGS)
  const [mode, setMode] = useState(save.currentMode || 'title')
  const [previousMode, setPreviousMode] = useState('town')
  const [storyBeatIndex, setStoryBeatIndex] = useState(0)
  const [selectedMissionId, setSelectedMissionId] = useState(null)
  const [battleResult, setBattleResult] = useState(null)
  const [toast, setToast] = useState('')
  const [loadingTarget, setLoadingTarget] = useState(null)
  const [onboardingStep, setOnboardingStep] = useState(0)

  const currentTown = getTown(save.currentTownId) || TOWNS.ashvale
  const currentStory = getStoryChapter(save.currentStoryId) || getNextAvailableChapter(save.storyFlags, save.completedStoryIds) || STORY_CHAPTERS[0]

  const appClassName = useMemo(() => {
    const classes = ['vaelthar-app']
    if (settings.highContrast) classes.push('is-high-contrast')
    if (settings.largeText) classes.push('is-large-text')
    if (settings.reducedMotion) classes.push('is-reduced-motion')
    return classes.join(' ')
  }, [settings])

  useEffect(() => {
    if (settings.autoSave) writeSave({ ...save, currentMode: mode })
  }, [save, mode, settings.autoSave])

  useEffect(() => {
    if (!toast) return undefined
    const timeout = window.setTimeout(() => setToast(''), 2600)
    return () => window.clearTimeout(timeout)
  }, [toast])

  const updateSave = (updater, message) => {
    setSave((current) => {
      const next = typeof updater === 'function' ? updater(current) : updater
      return settings.autoSave ? writeSave(next) : next
    })
    if (message) setToast(message)
  }

  const goLoading = (targetMode, label = 'Loading') => {
    setPreviousMode(mode)
    setLoadingTarget({ mode: targetMode, label })
    setMode('loading')
  }

  const completeLoading = () => {
    setMode(loadingTarget?.mode || 'town')
    setLoadingTarget(null)
  }

  const finishStoryChapter = () => {
    const chapter = currentStory
    const completedStoryIds = [...new Set([...save.completedStoryIds, chapter.id])]
    const reward = chapter.rewards || {}
    const nextFlags = [...new Set([...save.storyFlags, ...(reward.flags || [])])]
    const nextStory = getNextAvailableChapter(nextFlags, completedStoryIds)

    updateSave((current) => ({
      ...current,
      storyFlags: nextFlags,
      unlockedTownIds: [...new Set([...current.unlockedTownIds, ...(reward.unlockTownIds || [])])],
      activeQuestIds: [...new Set([...current.activeQuestIds, ...(reward.activateQuestIds || [])])],
      completedStoryIds,
      currentTownId: chapter.nextTownId || current.currentTownId,
      currentStoryId: nextStory?.id || chapter.id,
      currentMode: chapter.nextMode || 'town'
    }), `Story updated: ${chapter.title}`)

    setStoryBeatIndex(0)
    goLoading(chapter.nextMode || 'town', 'Advancing story')
  }

  const advanceStory = () => {
    if (storyBeatIndex < currentStory.beats.length - 1) {
      setStoryBeatIndex((index) => index + 1)
      return
    }
    finishStoryChapter()
  }

  const selectTown = (townId) => {
    updateSave((current) => ({ ...current, currentTownId: townId, currentMode: 'town' }), `${getTown(townId)?.name || 'Town'} selected`)
    goLoading('town', 'Traveling')
  }

  const openMission = (missionId) => {
    setSelectedMissionId(missionId)
    goLoading('mission', 'Preparing mission briefing')
  }

  const openService = (serviceMode) => {
    setPreviousMode('town')
    setMode(serviceMode)
  }

  const restAtInn = (cost) => {
    updateSave((current) => ({
      ...current,
      gold: Math.max(0, current.gold - cost),
      restCount: (current.restCount || 0) + 1
    }), 'Party rested and resources restored')
  }

  const buildBattleResult = (missionId, victory = true) => {
    const mission = getMission(missionId)
    if (!mission) return

    const result = buildMissionResult(missionId, {
      victory,
      completedBonusObjectives: victory ? mission.bonusObjectives.slice(0, 2) : []
    })

    setBattleResult(result)
    setMode('result')
  }

  const applyBattleResult = () => {
    if (!battleResult) {
      setMode('town')
      return
    }

    if (!battleResult.victory) {
      setToast('No rewards applied after defeat')
      setMode('town')
      return
    }

    const nextSave = applyMissionResult(save, battleResult)
    const nextStory = getNextAvailableChapter(nextSave.storyFlags, nextSave.completedStoryIds)
    const resolvedSave = {
      ...nextSave,
      currentStoryId: nextStory?.id || nextSave.currentStoryId,
      currentMode: nextStory ? 'story' : 'town'
    }

    updateSave(resolvedSave, `Rewards applied: ${battleResult.title}`)
    setBattleResult(null)
    goLoading(nextStory ? 'story' : 'town', 'Applying battle results')
  }

  const launchMission = (missionId) => {
    setSelectedMissionId(missionId)
    setBattleResult(null)
    goLoading('battle', 'Entering battle')
  }

  const retryMission = () => {
    setBattleResult(null)
    goLoading('battle', 'Retrying mission')
  }

  const returnToTownFromResult = () => {
    setBattleResult(null)
    setMode('town')
  }

  const newGame = () => {
    clearSave()
    const fresh = createNewSave()
    setSave(fresh)
    setStoryBeatIndex(0)
    setSelectedMissionId(null)
    setBattleResult(null)
    setToast('New game started')
    goLoading('story', 'Starting prologue')
  }

  const renderTitle = () => (
    <main className="v-shell">
      <section className="v-card">
        <p className="v-eyebrow">Vaelthar</p>
        <h1 className="v-title">Eidolon Chronicles</h1>
        <p className="v-copy" style={{ fontSize: 20 }}>
          A modern browser tactical RPG shell with story hubs, world map progression, mission briefings, accessibility options, codex unlocks, onboarding, loading tips, and a connected combat prototype.
        </p>
        <div className="v-grid-3" style={{ margin: '24px 0' }}>
          <div className="v-panel"><span className="v-pill">Story</span><h2>Guardian corruption</h2><p className="v-copy">Reach corrupted Guardians instead of only destroying them.</p></div>
          <div className="v-panel"><span className="v-pill">Tactics</span><h2>Mission board</h2><p className="v-copy">Preview enemies, objectives, rewards, terrain, and bonus challenges.</p></div>
          <div className="v-panel"><span className="v-pill">Modern UX</span><h2>Player-first shell</h2><p className="v-copy">Auto-save, settings, codex, onboarding, loading tips, and readable menus.</p></div>
        </div>
        <div className="v-btn-row">
          <button className="v-btn v-btn-primary" onClick={newGame}>New Game</button>
          <button className="v-btn v-btn-blue" onClick={() => goLoading(save.currentMode || 'town', 'Continuing')}>Continue</button>
          <button className="v-btn" onClick={() => setMode('settings')}>Settings</button>
          <button className="v-btn" onClick={() => setMode('controls')}>Controls</button>
        </div>
      </section>
    </main>
  )

  const renderBattlePlaceholder = () => (
    <main className="v-shell">
      <section className="v-card">
        <header className="v-header">
          <div>
            <p className="v-eyebrow">Battle Prototype</p>
            <h1 className="v-title">{getMission(selectedMissionId)?.title || 'Combat Simulation'}</h1>
            <p className="v-copy">The existing combat prototype is mounted below. Use the result buttons to test victory/defeat, rewards, and story progression until the combat engine returns real results.</p>
          </div>
          <div className="v-btn-row">
            <button className="v-btn" onClick={() => setMode('mission')}>Briefing</button>
            <button className="v-btn v-btn-primary" onClick={() => buildBattleResult(selectedMissionId, true)}>Simulate Victory</button>
            <button className="v-btn" onClick={() => buildBattleResult(selectedMissionId, false)}>Simulate Defeat</button>
          </div>
        </header>
      </section>
      <CombatPrototype />
    </main>
  )

  let content
  if (mode === 'title') content = renderTitle()
  else if (mode === 'loading') content = <LoadingScreen label={loadingTarget?.label} onComplete={completeLoading} />
  else if (mode === 'story') content = <StoryScene chapter={currentStory} beatIndex={storyBeatIndex} onNext={advanceStory} />
  else if (mode === 'world') content = <WorldMap unlockedTownIds={save.unlockedTownIds} currentTownId={save.currentTownId} onSelectTown={selectTown} onOpenQuestLog={() => setMode('quests')} />
  else if (mode === 'town') content = <TownScreen town={currentTown} activeQuestIds={save.activeQuestIds} completedQuestIds={save.completedQuestIds} onBackToWorld={() => setMode('world')} onStartMission={openMission} onOpenQuestLog={() => setMode('quests')} onOpenCodex={() => setMode('codex')} onOpenSettings={() => setMode('settings')} onOpenService={openService} />
  else if (mode === 'mission') content = <MissionBriefing missionId={selectedMissionId} onBack={() => setMode('town')} onLaunch={launchMission} />
  else if (mode === 'battle') content = renderBattlePlaceholder()
  else if (mode === 'result') content = <BattleResultScreen result={battleResult} onContinue={applyBattleResult} onRetry={retryMission} onReturnToTown={returnToTownFromResult} />
  else if (mode === 'quests') content = <QuestLog activeQuestIds={save.activeQuestIds} completedQuestIds={save.completedQuestIds} onBack={() => setMode(previousMode || 'town')} />
  else if (mode === 'codex') content = <CodexScreen storyFlags={save.storyFlags} onBack={() => setMode('town')} />
  else if (mode === 'settings') content = <SettingsPanel settings={settings} onChange={setSettings} onBack={() => setMode(previousMode || 'title')} />
  else if (mode === 'controls') content = <ControlsHelp onBack={() => setMode('title')} />
  else if (mode === 'party') content = <PartyScreen partyIds={save.partyIds} onBack={() => setMode('town')} />
  else if (mode === 'inventory') content = <InventoryScreen inventory={save.inventory} gold={save.gold} onBack={() => setMode('town')} />
  else if (mode === 'jobs') content = <JobBoard onBack={() => setMode('town')} />
  else if (mode === 'summons') content = <SummonArchive storyFlags={save.storyFlags} onBack={() => setMode('town')} />
  else if (mode === 'inn') content = <InnScreen town={currentTown} gold={save.gold} onRest={restAtInn} onBack={() => setMode('town')} />
  else content = renderTitle()

  return (
    <div className={appClassName}>
      {content}
      {!save.onboardingComplete && mode !== 'title' && mode !== 'loading' && mode !== 'battle' && (
        <OnboardingOverlay
          stepIndex={onboardingStep}
          onNext={() => {
            if (onboardingStep >= 4) {
              updateSave((current) => ({ ...current, onboardingComplete: true }), 'Guide complete')
            } else {
              setOnboardingStep((index) => index + 1)
            }
          }}
          onSkip={() => updateSave((current) => ({ ...current, onboardingComplete: true }), 'Guide skipped')}
        />
      )}
      <Toast message={toast} />
    </div>
  )
}
