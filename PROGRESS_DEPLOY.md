# PROGRESS — Mars Arachnid Defense · Web & delivery pass

Recovery file for the continuation pass that turned the finished Godot desktop build into a
GitHub Pages deliverable. Read this first if the session is interrupted.

Format: `[x]` done, `[~]` in progress, `[ ]` not started, `[!]` blocked.
Rule: a checkbox is marked done only after the file exists and the relevant command/scene
was actually run. This is the deployment tracker; `PROGRESS_MARS.md` remains the history of
the original 15-sector build, and `PROGRESS.md` is only the formatting reference from a
different project.

## Current state

- **Status:** complete — the desktop project is unchanged, and the browser build is published
  through a themed `index.html` launcher with the game in `web/`.
- **Engine:** Godot 4.7.2 stable (`%LOCALAPPDATA%\Temp\opencode\godot`), GL Compatibility.
- **Desktop evidence:** `TestRunner` 663 checks / 0 failures; `FlowTest` 35 / 0; `RestartTest`
  OK; `FairPlayTest` 15/15 victories; `PlaythroughTest` 15/15.
- **Web export:** single-threaded template, release build, `web/index.wasm` 39,514,754 bytes,
  `web/index.pck` 841,472 bytes, `web/` total 38.82 MB.
- **Launcher:** `index.html` 22,933 bytes; loading overlay fades on a 900 ms timer and never
  blocks input.
- **Browser evidence:** boots to the menu, starts sector 1, places a Pulse Turret, fights a
  wave, and keeps the master volume after an iframe reload (IndexedDB save). On web the
  main-menu desktop quit button becomes **RELOAD GAME**, which restarts the page cleanly.
- **Deployment:** branch-based GitHub Pages from the repository root. `.nojekyll` included.
  Verified from a `/Defender/` sub-path with no COOP/COEP headers; `node tools/check-pages.mjs`
  passes. Opening `index.html` from disk is detected and blocked with instructions;
  `start.bat` / `start.sh` serve the folder locally and open the browser.

## Block D0 — Recovery and baseline [x]
- [x] Read `Defender.md`, `PROGRESS.md` (format reference) and `PROGRESS_MARS.md`.
- [x] Confirm the working folder is the active project, not `Defender0.1`.
- [x] Verify Godot 4.7.2 boots `res://scenes/main/Boot.tscn` to the main menu.
- [x] Run `tests/TestRunner.tscn` headlessly: 663 checks, 0 failures.
- [x] Re-read the existing verification logs (`fairplay.log`, `playthrough.log`, `flow_test.log`,
  `restart_test.log`, `perf_test.log`).
- [x] Identify the real gaps: `FEATURE_AUDIT.md` referenced but absent; no `index.html`; no Web
  export preset or build; no Pages instructions.

## Block D1 — Missing audit document [x]
- [x] Write `FEATURE_AUDIT.md` with the required columns (feature, evidence, benefit, priority,
  decision, acceptance check, final status).
- [x] Classify rows as Working / Partial / Missing / Broken and priorities P0–P3.
- [x] Record real suite results, performance numbers and screenshot locations.
- [x] Add browser-specific evidence and limitations (MSAA warning, 40 MB payload, IndexedDB).

## Block D2 — Web export toolchain [x]
- [x] Install only the Web export templates from the official 1.2 GB `.tpz` using HTTP range
  requests (~20 MB written instead of the whole archive).
- [x] Add `export_presets.cfg` with a `Web` preset: single-threaded, GL Compatibility,
  `web/index.html`, tests/tools/Markdown excluded from the `.pck`.
- [x] Export the release build with `godot --headless --export-release "Web" web/index.html`.
- [x] Confirm `web/` contains `index.html`, `index.js`, `index.wasm`, `index.pck`, icons and
  audio worklets.
- [x] Add `tools/serve.mjs`, a dependency-free static server with `application/wasm` and the
  cross-origin headers needed if a threaded build is used later.

## Block D3 — Browser launcher [x]
- [x] Create root `index.html`: dark graphite / amber military console theme, no CDN, no
  external fonts, inline SVG favicon.
- [x] Lazy-load `web/index.html` in a full-screen iframe after the Deploy button, so audio
  starts from a user gesture and the 40 MB payload is not fetched until requested.
- [x] Add environment checks for `file://`, missing WebAssembly and missing WebGL 2.
- [x] Add campaign briefing, controls summary, links to README / audit / this log, and an
  "open build directly" escape hatch.
- [x] Keep the launcher responsive: 1600×900, 1280×720 (compact height rules) and narrow
  windows (stacked single column).
- [x] Make the loading overlay purely decorative (`pointer-events: none`) so it can never
  swallow the first click.

## Block D4 — Browser verification [x]
- [x] Add `tools/web-shot.mjs`: headless Chrome through CDP, waits for the engine canvas,
  reports console errors, captures a screenshot, supports a setup expression.
- [x] Direct build boots to the main menu (`tests/web_build_1600x900.png`).
- [x] Launcher → Play → embedded build reaches the menu
  (`tests/web_launcher_game_1600x900.png`).
- [x] Sector 1 loads; Pulse Turret placed for $100; credits drop 620 → 520
  (`tests/web_play3_tower.png`).
- [x] Wave starts with Space; enemies advance, the turret fires, damage numbers and credits
  update (`tests/web_play3_combat.png`).
- [x] Settings panel opens; master volume set to 2%; after reloading the iframe it is still
  2% (`tests/web_persist_persisted.png`), proving the IndexedDB save works.
- [x] Capture launcher at 1280×720 and at a narrow 500 px window; no horizontal overflow.

## Block D5 — GitHub Pages readiness [x]
- [x] Add `.nojekyll` so Pages serves the export verbatim.
- [x] Update `.gitignore`: keep `.import` sidecars, `web/`, `export_presets.cfg`; ignore cache,
  local logs and archives.
- [x] Document the three-click Pages setup (Settings → Pages → branch `main` / root).
- [x] Document re-exporting the build after code changes.
- [x] Document that no COOP/COEP headers are needed for the single-threaded build.
- [x] Update `README.md`: browser play, deployment, new files, web smoke test, limitations.

## Block D6 — Final regression [x]
- [x] Re-run `TestRunner` after all file additions: 663 checks, 0 failures (also re-run
  after the web-only `MainMenuController.gd` edit).
- [x] Re-export the Web build after the launcher changes.
- [x] Verify the export below a sub-path (`/Defender/`) to match `user.github.io/repo/`.
- [x] Verify the web-only main-menu **RELOAD GAME** button reloads the page back to the menu
  (`tests/web_menu_reload_game.png`, `tests/web_reload_after_reload_click.png`).
- [x] Confirm the launcher loading overlay no longer waits for the iframe `load` event:
  the `done` class is applied at ~1.05 s. (Headless SwiftShader may finish the CSS fade
  later because it stalls the compositor while compiling the 40 MB wasm; input is never
  blocked and real GPUs fade immediately.)
- [x] Final read-through of README, audit, progress files for stale claims.
- [x] Record the final file inventory and sizes (below).

## Block D7 — Direct-file guard and one-click start [x]
- [x] Reproduce the `file://` failure: Godot's loader calls `fetch()` for `index.wasm` /
  `index.pck`, which browsers reject as `Failed to fetch`. This is a browser rule, not a
  bug in the page.
- [x] Stop `index.html` from attempting the iframe load on `file://`: the Deploy button is
  disabled, renamed **Local server required**, and a notice explains the cause and the fix.
- [x] Intercept both "open build directly" links under `file://` and point the user at the
  same notice instead of opening a broken game page.
- [x] Add `start.bat` (Windows; Node first, Python fallback) and `start.sh` (macOS/Linux)
  that serve the folder over HTTP and open the browser automatically.
- [x] Add `--open` to `tools/serve.mjs` so the server launches the default browser once it is
  listening; positional `[port] [root]` arguments still work.
- [x] Verify the guard in headless Chrome from `file://`: button disabled, notice visible,
  iframe `src` stays empty, zero JS exceptions (`tests/web_file_guard.png`).
- [x] Re-verify the HTTP path after the change: launcher reaches the game and the overlay
  class is applied in ~1.05 s.

## Block D8 — Port collision and duplicate folder [x]
- [x] Investigated the report that two different games open on ports 8125 and 8642.
  Ports 8125 and 8137 are old **Ashen Crown** dev servers started on 29 Oct and 3 Nov by
  `Temp\server2.cjs` / `server.cjs`; they are unrelated to this project. Port 8642 is this
  game's `tools/serve.mjs`.
- [x] Change the default port from 8125 to **8787**, so the documented address cannot be
  shadowed by an unrelated server that is already running.
- [x] Add automatic fallback in `tools/serve.mjs`: on `EADDRINUSE` it prints the conflict,
  tries the next port (up to 20 times), and opens/prints the real URL.
- [x] Update `start.bat`, `start.sh`, README, audit and this log to 8787.
- [x] Verify the fallback by starting on occupied port 8125: the server reported
  "port 8125 was busy, using 8126 instead" and served **Mars Arachnid Defense**
  (200), not the other game.
- [x] Identified `D+D` as a byte-identical duplicate of `Defender` (617 files, 0 content
  differences, `.godot` cache excluded). The owner chose to keep it as a backup, so nothing
  was deleted or copied. It was later renamed to `Defender0.2` outside this session; a
  `Defender0.3` snapshot also exists. Only `Defender` received the files in this pass.

## Block D9 — GitHub Pages launch audit [x]
- [x] Simulate GitHub Pages: serve the parent folder, open `/Defender/` with a plain static
  server that sends **no COOP/COEP** and no Pages-specific headers.
- [x] Launcher → Play → embedded build reaches the menu; direct `/Defender/web/index.html`
  also boots (`tests/web_pages_home.png`, `tests/web_pages_launcher.png`,
  `tests/web_pages_direct.png`). On the home page Deploy is enabled, the notice is hidden
  and the iframe is not fetched until the click.
- [x] Network audit: 0 non-200 responses, 0 failed requests; only the data-URI grain and a
  `blob:` audio worklet are outside `/Defender/`.
- [x] Confirm the export is single-threaded (`GODOT_THREADS_ENABLED = false`,
  `variant/thread_support=false`), so no cross-origin isolation is required.
- [x] Verify every `href`/`src` in both HTML files with case-sensitive filename matching
  (GitHub Pages runs on Linux); all references exist.
- [x] Add `.gitattributes` so wasm/pck/images stay byte-exact in git.
- [x] Add `tools/check-pages.mjs`: validates required files, exact case, relative links,
  `.nojekyll`, single-threaded export and GitHub's upload limits; result **PASS**.
- [x] Dry-run `git add --all`: 613 entries, including `web/` and `.nojekyll`; `.godot/`
  and `*.log` stay excluded by `.gitignore`.
- [x] Document the real deployment traps: publish the `Defender` folder itself (not the
  `Opencode` parent), use git/GitHub Desktop (browser upload rejects the 39.5 MB wasm),
  never Git LFS, public repo on the free plan, open the URL with a trailing slash.

## Verification commands

```bash
# Desktop mechanics
godot --headless --path . --fixed-fps 60 res://tests/TestRunner.tscn
godot --headless --path . --fixed-fps 60 res://tests/FlowTest.tscn
godot --headless --path . --fixed-fps 60 res://tests/RestartTest.tscn
godot --headless --path . --fixed-fps 60 res://tests/FairPlayTest.tscn

# Web export (templates must be installed for 4.7.2)
godot --headless --path . --export-release "Web" web/index.html

# Browser smoke test
node tools/serve.mjs 8787 --open
node tools/web-shot.mjs "http://127.0.0.1:8787/web/index.html" "tests/web_build_1600x900.png" 1600 900 4000

# GitHub Pages preflight (no browser)
node tools/check-pages.mjs
```

## Final inventory (2026-11-10)

Measured from the repository root; `.godot/` cache and `*.log` files excluded.

| Item | Size / count |
| --- | --- |
| Project files (excluding cache and logs) | 613 files, 51.57 MB |
| `web/` export | 10 files, 38.82 MB |
| `web/index.wasm` | 39,514,754 bytes |
| `web/index.pck` | 841,472 bytes |
| `index.html` launcher | 24,587 bytes |
| `start.bat` / `start.sh` | 800 / 159 bytes |
| `.gitattributes` / `tools/check-pages.mjs` | 149 / 5,009 bytes |
| Web evidence screenshots | `tests/web_*.png` (25 files) |

The committed export is a snapshot. Re-export after any gameplay change; only `web/` needs
to be replaced, the launcher and docs stay valid.

## Known limitations (delivery)

- The committed `web/` build is a snapshot; re-export after changing the game.
- GitHub Pages serves the repository root, so the source project and the build are public.
- The WebAssembly payload is ~39.5 MB before HTTP compression; first load is slow on poor
  connections, later loads come from the browser cache.
- Chrome logs one harmless `2D MSAA is not yet supported for GLES3` warning.
- Opening `index.html` directly from disk cannot work: browsers block `fetch()` of local
  `.wasm`/`.pck` files. Use `start.bat`, `start.sh` or `tools/serve.mjs`, or deploy to Pages.
- No human playtest has been recorded; balance evidence is bot-driven.

## Key files for this pass

- `index.html` — launcher, theme, environment checks, iframe boot, file:// guard.
- `start.bat` / `start.sh` — one-click local server + browser.
- `web/` — exported game (do not edit by hand).
- `export_presets.cfg` — reproducible Web export settings.
- `tools/serve.mjs` — local static server (`--open` to launch the browser).
- `tools/check-pages.mjs` — static GitHub Pages readiness check.
- `tools/web-shot.mjs` — headless Chrome verification.
- `.gitattributes` — keeps wasm/pck/images byte-exact in git.
- `FEATURE_AUDIT.md` — evidence table for desktop and browser.
- `.nojekyll` — GitHub Pages marker.
