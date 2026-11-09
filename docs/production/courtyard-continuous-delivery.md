# Courtyard continuous delivery candidate

This main-based integration preserves the campaign at `/tactics/` and adds a
separate `/courtyard/` package only after the release gate succeeds. It does not
replace either source project's default scene, and it does not establish that a
live deployment has happened. The hosted `courtyard/build-info.json` must identify
the expected commit before calling a release live.

## Integrated source

- Standalone demo subtree from #111, `b9de8235bf325d987ba9e04969b2b92a3506d1be`.
  This includes #103, #105, #106, #108 and #109: explicit action review, input fixes,
  accessible settings, scalable HUD and clearer forecasts.
- Only the standalone ground/contact delta from #107 and #110,
  `e2c0b6a457f1332c98b56afef808268631fcfee6`, relative to #103.
- No other root gameplay changes or historical feature-branch dependencies.
- No new wall, paving, character animation or emblem candidates are enabled.

Existing PR branches are untouched. This is an integration snapshot, not a claim
that all stacked PRs were merged or that every asset has been approved.

## Release boundary

`tools/export_courtyard_web.py` copies the standalone project into a temporary
directory. Only that copy launches `BloomingBattle.tscn` and uses the isolated
`ProjectTactic-Courtyard` save namespace. The production package is exported
first, checked for QA instrumentation, packaged and integrity-checked. A separate
QA package adds a read-only observer. Source projects are never rewritten.

The reusable `Courtyard Web release gate` runs supported native contracts,
exports both packages with Godot 4.6.3, and exercises actual Chrome keyboard/mouse
input: settings, move targeting, review/cancel, mouse confirmation, resource
preservation, and 1920/1366 layouts. It also loads the uninstrumented production
package. Failed gates prevent the accepted production artifact from uploading.

Pages deployment must consume that same run's accepted artifact and match its
source commit to `GITHUB_SHA`. The campaign keeps its existing export gate. A
failure in either package blocks upload/deployment of the whole new site.

## Run locally

Requirements: Godot 4.6.3 with matching Web templates, Python, Node, Chrome or
Chromium, and the `websocket-client` Python package for browser input.

```sh
python -m unittest discover -s tools -p test_courtyard_web.py
python tools/export_courtyard_web.py build/courtyard --qa-directory build/courtyard-qa
```

Both output directories must be empty. The workflow contains the complete
isolated browser/server commands and the native contract suite.

## Acceptance and rollback

Before merging: inspect exact-head CI, download the browser evidence, visually
review the real engine screenshots, and obtain the required release approval.
Do not infer visual acceptance from headless tests. After deployment, verify the
live `build-info.json`, Web package assets and actual playable route. A rollback
is a reviewed revert to the previous main commit and a fresh Pages deployment;
do not force-push main or change save formats as a rollback shortcut.

This browser smoke is not a full-match, mobile/touch, performance or audible-audio
acceptance claim. Retired standalone 1v1 and inherited main-game route tests are
not part of the supported courtyard suite; the separate production Godot CI
continues to cover the campaign. The existing SkillPreviewTest may report one
resource in use at shutdown after passing its assertions; retain that diagnostic
and do not relabel the full native suite warning-free.
