---
name: rigorous-review
description: Use before calling a change ready or requesting merge.
---

# Rigorous Review

## When to use
Use before calling a change ready or requesting merge.

## Procedure
1. Compare diff to explicit acceptance criteria.
2. Check regressions, determinism, asset dependencies, game state, persistence, input, failure behavior and performance.
3. Require reproducible automated evidence plus visual/manual checks where needed.
4. Distinguish pass, fail, blocked, and not-run; do not claim unexecuted checks passed.

## Gate
- Preserve repository behavior and project constraints.
- State source of evidence and checks actually run.
- No merge, public release, or live-demo change without explicit authorization.
