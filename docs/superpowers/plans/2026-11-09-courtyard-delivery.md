# Courtyard Delivery Implementation Plan

> **For agentic workers:** Use native execution and independent whole-branch review. Steps use checkboxes to distinguish completed implementation from release gates.

**Goal:** Build and verify a separate courtyard Web package on each proposed change, and make Pages publish it only after those checks pass.

**Architecture:** Integrate only the reviewed standalone subtree and its ground/contact fixes onto main. Stage the courtyard entry point in a temporary copy, export production separately from its read-only browser observer, and require the accepted artifact in Pages deployment.

**Tech Stack:** Godot 4.6.3, Python, Chrome DevTools Protocol, GitHub Actions and Pages.

**Spec:** `docs/production/courtyard-continuous-delivery.md`.

## Constraints and review focus

- Preserve the main campaign, default source entry points and existing saves.
- Do not enable unfinished art or merge unrelated stacked dependencies.
- Reject stale outputs and zero-exit engine error logs.
- Keep browser instrumentation out of the public package.
- Match the delivered artifact commit to the deploying commit.
- Keep full-match, touch, performance and audible-audio acceptance distinct.

## Tasks

- [x] Copy the #111 demo subtree and apply the standalone-only #107/#110 delta.
- [x] Write failing release-staging tests; implement temporary export staging,
  output freshness checks and production-package observer exclusion.
- [x] Add read-only observation and actual browser keyboard/mouse smoke coverage.
- [x] Add a reusable release workflow and same-run artifact/commit validation to Pages.
- [ ] Complete local supported suites and exact-head CI.
- [ ] Independently review source isolation, gating and browser evidence.
- [ ] Resolve review findings and obtain required release approval before merging.
- [ ] Verify the hosted commit and playable route after deployment.
