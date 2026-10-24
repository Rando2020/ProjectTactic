---
name: pragmatic-engineering
description: Prefer smallest verifiable change over a new framework.
---

# Pragmatic Engineering

## When to use
Prefer smallest verifiable change over a new framework.

## Procedure
1. Identify the immediate user-visible outcome and existing code path.
2. Compare a minimal patch against larger architecture changes.
3. Implement the narrowest correct fix with a rollback path.
4. Verify changed behavior and regressions.

## Gate
- Preserve repository behavior and project constraints.
- State source of evidence and checks actually run.
- No merge, public release, or live-demo change without explicit authorization.
