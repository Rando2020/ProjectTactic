// app.jsx — entry point
const { useState: useStateApp } = React;

function App() {
  const [screen, setScreen] = useStateApp("antechamber");
  const [tier, setTier] = useStateApp(2);
  const [scene, setScene] = useStateApp(null);

  React.useEffect(() => {
    document.getElementById("app").className = `tier-${tier}`;
  }, [tier]);

  return (
    <>
      <TopRail screen={screen} onNav={(s) => { setScene(null); setScreen(s); }} tier={tier} onTierChange={setTier} />
      <main className="stage">
        {screen === "title"       && <TitleScreen onNewGame={() => setScreen("chapter")} onContinue={() => setScreen("antechamber")} tier={tier} />}
        {screen === "antechamber" && <Antechamber tier={tier} onBeginRun={() => setScreen("chapter")} onTalk={setScene} />}
        {screen === "chapter"     && <ChapterCard tier={tier} />}
        {screen === "runmap"      && <RunMap />}
        {screen === "roster"      && <Roster />}
        {screen === "battle"      && <Battle tier={tier} />}
        {screen === "codex"       && <Codex tier={tier} />}
        {scene && <DialogueOverlay loc={scene} onClose={() => setScene(null)} tier={tier} />}
      </main>
    </>
  );
}

const root = ReactDOM.createRoot(document.getElementById("app"));
root.render(<App />);
