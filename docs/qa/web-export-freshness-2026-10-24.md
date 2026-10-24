# Web export freshness and integrity

This packaging-only safeguard addresses a reproducible cache hazard, **not a reported live-user failure**. Stable `index.pck.partN` URLs previously allowed independently cached releases to be concatenated. The former checker accepted a mixed pack with correct length and `GDPC` header.

## Loading contract

- Physical PCK/WASM parts, generated engine JS/worklets, and Godot executable name remain unchanged. Godot stays pinned to 4.6.3.
- Packaging emits `asset-parts.json` with complete-PCK SHA-256 and length. Legacy `asset-parts.js` remains available, but the new wrapper never trusts it as a fallback.
- Each logical asset fetch first revalidates JSON metadata (`cache: no-cache`). PCK part requests use `?v=<expected whole-pack SHA-256>`; this is a cache namespace, **not retained historical origin storage**.
- Complete PCK bytes are verified before returning a response to Godot. A size/digest mismatch refreshes the manifest and retries the **whole** pack once; retry bypasses the previous cache entry while respecting caller `no-store`. A second mismatch rejects visibly with reload guidance. Manifest/HTTP/JSON/crypto failures fail closed; there is no eval, hash-skip, or automatic page reload.
- Godot's existing preloader separately retries failed fetches up to four times. The wrapper's two-attempt budget is per fetch, so at most eight pack attempts can occur through that existing engine retry path; this patch does not alter engine code.
- Ordinary full GET requests are reconstructed. Unrelated URLs, queries on the logical asset URL, non-GET, Range and caller-SRI requests are passed to native fetch unchanged. Request overrides, credentials, headers, redirects and abort signals are preserved; abort also applies while a returned body remains unread.
- Newly generated HTML cache-versions the wrapper URL by its bytes. JSON is parsed only as JSON, and manifest part paths must match the expected local sequential filenames.

## Compatibility and limits

Generated `index.js` uses `fileSizes` for progress tracking, not content selection. Fresh metadata therefore needs no startup/config change. This deliberately relies on the pinned, byte-identical engine/WASM/worklet graph across these gameplay exports; an engine upgrade requires separately reviewing bootstrap compatibility.

Already-cached **pre-fix** HTML/loaders cannot be retroactively repaired by publication. They require revalidation/hard reload or expiration of their remaining cache lifetime. Open games are not hot-updated. Global CDN propagation is not instantaneous. A current `build-info.json` identifies server provenance but is not proof of a client's verified PCK. This patch does not retain old releases or claim those guarantees.

Full-PCK verification buffers bytes before Godot receives them, trading earlier progress updates and some memory for fail-closed integrity. No browser/device performance claim is made here.

## Deterministic verification

```sh
node --test tools/test_web_package.mjs
python -m unittest discover -s tools -p 'test_*.py'
node tools/check_web_package.mjs <packaged-export-directory>
```

The guards use the real wrapper and standard Fetch/Blob/WebCrypto; only HTTP responses are mocked. They cover stale metadata, mixed/equal-length/truncated content, a deployment transition, poisoned cache recovery, retry limits, invalid JSON/hash/path metadata, HTTP failure, absent WebCrypto, Request options, abort during manifest/part/hash and after headers, native passthrough, and root/subpath loading.

Before implementation: 25 of 28 initial loader guards failed against the old wrapper; 3 existing passthrough behaviors passed. The new packaging test failed because JSON metadata was absent. A later malformed-digest-array test independently failed before strict type validation was added. Independent frozen review found one Important passthrough regression: constructing a Request before excluding non-GET consumed POST/PUT bodies. Three new body-bearing regressions failed, then passed after effective non-GET methods were bypassed before Request construction; method overrides are also covered. The final deterministic suite has 35 loader guards and 37 Python tests. The Python browser harness tests simulate their timeout/cleanup paths; their expected diagnostic output is not an attempted local browser run.

Offline checks reconstructed/repackaged copies of two existing verified production exports (`c5563585…`, `5551d4d0…`) plus the latter's QA export. Both root/subpath package checks passed, PCK hashes remained exact, and all 12 engine/worklet/part files per export were byte-identical. Production packs were checked for absence of browser-observer resources. The actual new checker rejects the same mixed real PCK that the old checker accepted.

CI runs guards in validation and Pages build. The existing browser-smoke workflow now packages/checks the QA export too, so its smoke exercises the actual wrapper while observer staging/production-exclusion contracts remain intact. Local browser, GUI, localhost, fresh Godot export, push, deployment and live-client validation were not performed for this change.
