---
name: typescript-reliability
description: Use for TypeScript frontends, APIs and integrations, not for Godot GDScript.
---

# TypeScript Reliability

## When to use
Use for TypeScript frontends, APIs and integrations, not for Godot GDScript.

## Procedure
1. Type external boundaries; validate runtime input and error states.
2. Avoid unsafe casts, `any`, accidental nullable assumptions, and ambiguous streaming contracts.
3. Test serialization, abort, retries, and backward compatibility.
4. Run typecheck/lint/tests when the TypeScript package is available.

## Gate
- Preserve repository behavior and project constraints.
- State source of evidence and checks actually run.
- No merge, public release, or live-demo change without explicit authorization.
