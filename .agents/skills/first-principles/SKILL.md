---
name: first-principles
description: Use when architectural claims or technical tradeoffs need validation.
---

# First Principles Engineering

## When to use
Use when architectural claims or technical tradeoffs need validation.

## Procedure
1. State the problem, invariants, constraints and falsifiable hypotheses.
2. Trace underlying data flow and resource costs before adding dependencies.
3. Choose a direct test or small prototype to discriminate alternatives.
4. Document assumptions and revisit when evidence conflicts.

## Gate
- Preserve repository behavior and project constraints.
- State source of evidence and checks actually run.
- No merge, public release, or live-demo change without explicit authorization.
