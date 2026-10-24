# Web Export Freshness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Prevent a freshly bootstrapped game from receiving stale or mixed PCK bytes across deployments, without changing gameplay or physical asset names.

**Architecture:** Keep Godot's generated startup and pinned engine graph unchanged. The fetch wrapper obtains JSON manifest metadata with revalidation before reconstructing an asset; PCK part URLs include the expected full-pack digest and the complete pack is length/hash checked before delivery. A content mismatch refreshes the manifest and restarts the whole pack once, then fails with reload guidance.

**Tech Stack:** Python standard library, JavaScript Fetch/WebCrypto, Node built-in test runner. No new dependency/service.

**Spec:** `/workspace/shared/tactics-export-freshness.md` plus parent approval of 2026-10-24 11:43 UTC.

## Global Constraints

- Base `c80a025930a7e27c6fc2def169b82b1e23d1e3f5`, tree `a5667343e47548eaca8f51e36acb9f70ecc96e28`; isolated local checkout only.
- Preserve physical `index.*.partN`, `executable: "index"`, Godot 4.6.3 engine JS/WASM/worklets, native passthrough and abort semantics.
- No eval, missing-hash fallback, infinite retry/reload, gameplay/save changes, browser installation/use, localhost, external publication.
- Legacy `asset-parts.js` remains for pre-fix clients; new wrapper reads `asset-parts.json` as data. New HTML versions the wrapper URL by wrapper content hash.
- Pre-fix cached HTML/loaders and open games still require revalidation/restart; CDN propagation is not instantaneous.

## Source-backed startup compatibility

Generated `index.js` loadFetch uses `fetch(file)`; fileSizes initializes a progress tracker and does not select or validate PCK bytes. Generated paths are `index.pck`, `index.wasm`, and `index.audio*.worklet.js`. The two verified exports have identical engine/worklet bytes. Therefore manifest refresh can be awaited inside the wrapper without changing generated Engine config or introducing a second startup mechanism. Do not append versions to the executable/logical PCK URL: the current wrapper matches those exact URLs and Godot derives worklet paths from the executable.

## Review Focus

- Cached legacy manifest must not select old bytes after fresh JSON becomes available: stale-global regression test.
- Deployment switch during sequential part download must not leak partial/mixed bytes: mixed/truncated and bounded whole-pack retry tests.
- Abort during manifest, chunk, or digest work must reject without retry: Request/AbortSignal tests.
- Root/subpath URLs, query-bearing pages, and unrelated Request objects must keep correct resolution/passthrough: URL/request tests.
- Missing digest/WebCrypto or HTTP failure must fail closed rather than skip verification: malformed-manifest/crypto/HTTP tests.

## Task 1 — Executable loader guards (RED)

**Files:** create `tools/test_web_package.mjs`.

- [x] Test the actual wrapper in VM with mocked HTTP only and native Fetch/Blob/WebCrypto: stale cached manifest, clean bytes, equal-length mixed pack, truncation, manifest/part HTTP failure, changed-manifest recovery, retry budget, missing digest/crypto, root/subpath and Request options/abort/native passthrough.
- [x] Run `node --test tools/test_web_package.mjs` against unchanged loader; preserve RED output. Existing real-export mixed-PCK checker PASS remains the negative baseline.

## Task 2 — Packaging + fetch wrapper (GREEN)

**Files:** modify `tools/prepare_playable_web.py`, `web/compressed-wasm-loader.js`, `tools/check_web_package.mjs`; add `tools/test_prepare_playable_web.py`.

**Interface:** JSON manifest has existing `index.wasm`/`index.pck` entries; PCK additionally has lowercase 64-character `sha256`, expected raw `size`, unchanged relative `parts`. Legacy JS emits the same metadata.

- [x] Add packaging test for exact SHA/length, preserved physical parts, JSON/legacy consistency and executable versioned-loader reference; watch RED.
- [x] Emit JSON/digest and wrapper content-hash query in HTML, retaining existing physical files and legacy manifest.
- [x] Fetch current JSON with `cache: "no-cache"`; preserve caller Request settings/signal; intercept only ordinary full GET logical asset requests. Digest-version PCK part requests, collect/verify complete bytes with native SHA-256, retry once only on integrity mismatch after fresh metadata, otherwise error with reload guidance. Check abort before return. Keep engine decompression/path behavior intact.
- [x] Update checker to execute the packaged wrapper, compare reconstructed PCK against manifest digest, and test root/subpath/native passthrough; preserve WASM validation.
- [x] Run Node guards, Python packaging/export tests and real-package reconstruction checks on copies of verified export bytes.

## Task 3 — CI and frozen review

**Files:** modify `.github/workflows/godot-validate.yml`, `.github/workflows/deploy.yml`; add `docs/qa/web-export-freshness-2026-10-24.md`.

- [x] Run deterministic guards in validation and before Pages packaging; use existing Node setup (explicit Node 24 in validation).
- [x] Package/check `build/web-qa` before the existing CI browser smoke, keeping observer staging/exclusion checks intact. Do not launch a browser locally.
- [x] Run full available Python test suite, Node guards, checker against both rebuilt real packages, diff/whitespace checks; record all failures/limitations and RED/GREEN evidence.
- [x] Freeze local commit and request independent review before any integration. Review of `f598f855` found one Important non-GET body-passthrough issue; the single fix pass adds three RED→GREEN body regressions and override coverage. No push, merge, deploy, or live-file edits.
