# AI Battle Telemetry

## Purpose

ProjectTactic's AI producer needs gameplay evidence, not just source code and CI status. `BattleTelemetry.gd` is the development-only observation layer that converts battle behavior into deterministic, structured evidence the producer can evaluate.

This system is deliberately passive. It observes existing signals and snapshots state. It does not change combat resolution, enemy AI, RNG, save data, rendering, or player input.

## Files

- `godot/scripts/ai/BattleTelemetry.gd`
  - attaches to a BattleManager-compatible node
  - observes battle and unit signals
  - records deterministic event sequence numbers
  - snapshots unit state
  - exposes an explicit decision-recording hook for future self-play policies
  - exports the shared AI evidence document
- `godot/tests/test_battle_telemetry.gd`
  - deterministic signal fixture
  - validates metrics, event order, decision records, state capture, and JSON export
- `tools/check_battle_telemetry.py`
  - runs the test with isolated Godot user data
  - copies the exported evidence into `.ai-reports/battle-telemetry/`
  - validates and analyzes the evidence with `tools/ai/producer.py`
- `.github/workflows/ai-battle-telemetry.yml`
  - pins Godot 4.6.2
  - runs static validation and the telemetry regression
  - uploads the evidence plus producer report

## Event model

The observer currently captures:

- `battle_started`
- `turn_started`
- `turn_ended`
- `unit_moved`
- `hp_changed`
- `status_applied`
- `status_removed`
- `unit_defeated`
- `enemy_intent`
- `battle_won`
- `battle_lost`
- explicit `decision` events from a future self-play/controller adapter
- manual `checkpoint` events when a harness needs a state boundary

Each event receives a monotonically increasing `seq` value. Wall-clock timing is disabled by default so identical deterministic simulations can be compared without timestamp noise. Timing can be enabled explicitly for performance investigations.

## Evidence contract

`to_evidence()` emits the repository-wide `ai/schemas/evidence.schema.json` shape. Important fields include:

- scenario ID
- deterministic seed
- build SHA
- source type
- battle outcome
- player/enemy turn counts
- move count
- explicit decision count
- enemy intent count
- status application count
- HP lost by each team
- defeated units by team
- initial and final unit snapshots
- complete structured event stream

The evidence can be sent directly to:

```bash
python tools/ai/producer.py validate --evidence <battle-evidence.json>
python tools/ai/producer.py analyze --evidence <battle-evidence.json>
```

## Attaching the recorder

The recorder is not an autoload and is not added to production battle scenes. A development harness or future self-play runner owns it:

```gdscript
var telemetry := BattleTelemetry.new()
telemetry.attach(battle_manager, {
    "scenario_id": "grasslands-floor-1",
    "seed": 18423,
    "build_sha": build_sha,
    "source": "self_play",
    "policy_id": "greedy-damage-v1",
    "run_id": "batch-0001",
})
```

A policy should record the choice before executing it:

```gdscript
telemetry.record_decision(
    unit.unit_id,
    "greedy-damage-v1",
    ability_id,
    target.unit_id,
    target.grid_pos,
    expected_damage
)
```

At battle completion, the harness can call `export_evidence()`.

## Why telemetry is observer-only

The initial AI loop must distinguish observation from intervention. If telemetry can affect RNG, timing, actions, or state, then the act of measuring the game can change the game being measured.

Keeping this layer passive provides three guardrails:

1. A telemetry regression cannot become a hidden balance change.
2. Self-play policies can be replaced independently of evidence capture.
3. Human-play and automated-play evidence can eventually share the same schema.

## Known placeholders

- Existing BattleManager signals do not expose a canonical player action-resolved event. The recorder therefore captures result signals and offers `record_decision()` for controller/self-play adapters.
- HP-loss metrics currently describe which team lost HP. They do not claim causal damage attribution because hazards, status ticks, counters, and abilities can share the same HP signal.
- Boon selections, run-map choices, equipment changes, and node transitions are outside battle telemetry and should remain separate evidence producers.
- The current regression uses a deterministic fake battle signal fixture. The next self-play PR should add real BattleManager scenarios without changing the recorder contract.

## Evolution path

### Phase 1: telemetry foundation

Current scope. Validate the evidence contract and deterministic event ordering.

### Phase 2: baseline self-play

Add independent policies such as:

- random legal
- greedy damage
- defensive survival
- objective rush
- terrain seeking
- control/status seeking

Each policy records the same decision structure before executing a legal action.

### Phase 3: seeded batch runner

Run many deterministic seeds and aggregate:

- win rate by policy
- turn distribution
- ability usage distribution
- positional movement
- status usage
- damage pressure
- invalid/stalled states
- dominant decision frequency

### Phase 4: search and critic layers

Add stronger search policies and reasoning-model critique only after the baseline policies provide stable comparison data.

## Risks and tech debt

### Best practice

Treat telemetry as evidence, not truth. Metrics should support design review rather than replace player experience.

### Pragmatic workaround

Until BattleManager exposes a richer canonical action event, self-play controllers should call `record_decision()` directly. This avoids parsing log strings and avoids modifying the large BattleManager file solely for instrumentation.

### Risk

An optimized self-play agent may discover strategies normal players would never identify. Those results are useful for exploit detection but should not be the sole balance target.

### Next recommended action

Build `feature/ai-self-play-baselines` on top of this branch after telemetry CI passes. Start with random-legal and greedy-damage policies plus a small deterministic real-battle scenario set. Do not optimize model weights yet.
