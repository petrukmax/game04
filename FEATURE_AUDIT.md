# Feature Audit — Mars Arachnid Defense

Audit of the delivered Godot 4 project **and** the browser build. Every row states what
was actually run or measured; nothing below claims a human playtest that did not happen.

- **Build audited:** Godot 4.7.2 stable, GL Compatibility renderer, GDScript.
- **Desktop verification:** headless suites in `tests/` (logs at the repository root).
- **Web verification:** release Web export in `web/`, served over HTTP and driven in
  headless Chrome (WebGL 2 via SwiftShader) on 2026-11-10.
- **Status legend:** `Working`, `Partial`, `Missing`, `Broken`.
- **Priority:** P0 blockers, P1 required mechanics/UI/balance, P2 polish, P3 future work.

## Summary

| Area | Verdict | Evidence |
| --- | --- | --- |
| Campaign (15 sectors) | Working | `FairPlayTest`: 15/15 victories on the normal economy; `PlaythroughTest`: 15/15 |
| Mechanics | Working | `TestRunner`: 661 checks, 0 failures |
| UI and flows | Working | `FlowTest`: 35 checks, 0 failures; rendered captures at 1600×900 and 1280×720 |
| Restart/pause lifecycle | Working | `RestartTest`: real scene reload, OK |
| Save/load | Working | `FlowTest` persistence checks; browser reload kept the changed volume |
| Audio | Working | 37 generated WAVs; mute/volume wired and persisted |
| Performance | Working | Sector 15 benchmark: avg 10.09 ms, p95 19.94 ms, p99 30.07 ms per simulated frame |
| Web export | Working | Boots to the main menu, enters a sector, builds a tower, starts a wave and fights in Chrome |
| GitHub Pages delivery | Working | `index.html` launcher + `web/` build; verified under a `/Defender/` sub-path with no COOP/COEP headers |
| Human playtest | Missing | Not performed; balance is bot-verified only |
| Web 2D MSAA | Partial | Engine prints "2D MSAA is not yet supported for GLES3"; rendering continues normally |

## Full table

| Feature or defect | Current state and evidence | Player benefit | Priority | Decision | Acceptance check | Final status |
| --- | --- | --- | --- | --- | --- | --- |
| Playable entry point | `res://scenes/main/Boot.tscn` hands over to `MainMenu.tscn`; headless boot and browser boot both reach the menu | Player can start the game | P0 | Keep | Boot scene and exported build both show the menu | Working |
| Two crossing roads per level | 15 `LevelData` resources with `path_a`/`path_b`; `TestRunner` validates crossing routes and road cells | Readable tactical map | P0 | Keep | All 15 routes cross and stay inside the grid | Working |
| Grid and placement rules | `GridManager` states + `TestRunner` checks: road, occupied, blocked and insufficient-credit rejections | Fair, predictable building | P0 | Keep | Placement rejected with the correct reason; snap works | Working |
| Tower roster | 10 tower resources and 10 editable scenes; 3 upgrades each; verified by `TestRunner` and shop UI | Varied strategies | P1 | Keep | All ten buyable/upgradable where unlocked | Working |
| Upgrade/sell/targeting | `TowerPanel` previews next tier, sell refund, six targeting modes; tested headlessly | Meaningful decisions | P1 | Keep | Cost, refund and priority changes apply | Working |
| Enemy roster | 10 enemy resources/scenes including shields, burrow, heal, fly, elite and boss phases | Threat variety | P1 | Keep | Each type spawns and applies its mechanic | Working |
| Damage model | Armor, resistances, shields, statuses, minimum 1 damage, single reward per kill | Transparent combat | P1 | Keep | `TestRunner` damage/shield/resistance checks | Working |
| Wave sequencing | Deterministic spawns on both routes, early-call bonus, completion detection | Replayable pacing | P1 | Keep | All waves register and complete; 15/15 fair victories | Working |
| Economy | Starting credits, kill/wave income, early bonus, 70% refund; fair-play bot wins all sectors | Real resource pressure | P1 | Keep | No duplicate rewards; all sectors affordable | Working |
| Abilities | 5 abilities with cooldowns, charges and area targeting; pause-safe timers | Clutch tools in late sectors | P1 | Keep | Cooldowns freeze while paused and reset on restart | Working |
| HUD and shop | Credits, integrity, sector, wave preview, speed, pause, 10 cards, ability bar | Readable command console | P1 | Keep | Legible at 1600×900 and 1280×720 | Working |
| Menus and flows | Main menu, sector select, settings, manual, pause, victory, defeat | Complete campaign loop | P1 | Keep | `FlowTest` 35/35; screenshots 01–11 | Working |
| Pause/resume | Simulation, timers and cooldowns freeze; resume restores state | Fair interruptions | P1 | Keep | `FlowTest` pause checks | Working |
| Restart lifecycle | Scene reload clears units, projectiles, FX and signals | Safe retries | P1 | Keep | `RestartTest` reports OK | Working |
| Persistence | Versioned JSON in `user://`; validation and corrupt-file recovery; browser stores it in IndexedDB | Progress survives sessions | P1 | Keep | `FlowTest` save checks; browser volume persisted after reload | Working |
| Audio | 37 locally synthesized WAVs, 18-voice pool, same-sound guard, mute and volume | Feedback without clutter | P2 | Keep | No unbounded overlap; mute persists | Working |
| Performance | Sector 15, 18 towers, 14 waves: avg 10.09 ms, p95 19.94 ms, p99 30.07 ms, worst 85.12 ms (headless simulation only) | Stable late game | P1 | Keep | Benchmark completes; no stalls in browser play | Working |
| Web export | `web/index.html` + `index.pck` + `index.wasm` (39.5 MB) exported from preset "Web", single-threaded | Game runs in a browser | P1 | New | Boots, builds, fights and saves in Chrome | Working |
| GitHub Pages launcher | Root `index.html`, no external requests, lazy iframe, environment checks, `.nojekyll`; `file://` is detected and blocked with instructions | One-link playable page | P1 | New | Launcher and embedded build verified over HTTP; disk launch shows guidance, not a broken iframe | Working |
| Touch input | Relies on Godot's mouse-from-touch emulation; buttons are large | Tablet play | P2 | Keep | Click-to-place and all HUD buttons usable | Partial |
| Web 2D MSAA | Project requests 2D MSAA; GLES3/WebGL prints a warning and ignores it | None | P3 | Accept | Warning is cosmetic; gameplay unaffected | Partial |
| Human balance review | Only the scripted bot has played the campaign | Human-tuned fun | P3 | Future | A human completes sectors 11–15 | Missing |
| Music | Not implemented; ambience loop only | Atmosphere | P3 | Future | Optional soundtrack | Missing |
| Headless shutdown warnings | `ObjectDB instances were leaked` after `quit()` in some suites; assertions finish first | None in normal play | P3 | Accept | Warnings documented; no crash | Partial |

## Verification evidence

All commands were run from the repository root with the local Godot 4.7.2 console build.

```text
godot --headless --path . --fixed-fps 60 res://tests/TestRunner.tscn
  RESULT: 661 checks, 0 failures

godot --headless --path . --fixed-fps 60 res://tests/FlowTest.tscn
  RESULT: 35 checks, 0 failures (settings, mute, pause, victory/defeat wiring)

godot --headless --path . --fixed-fps 60 res://tests/RestartTest.tscn
  RESTART RESULT: OK

godot --headless --path . --fixed-fps 60 res://tests/PlaythroughTest.tscn
  PLAYTHROUGH RESULT: 0 level(s) failed (15/15 victories, test-only funding)

godot --headless --path . --fixed-fps 60 res://tests/FairPlayTest.tscn
  FAIR PLAYTHROUGH COMPLETE (15/15 victories on the normal economy)

godot --headless --path . --fixed-fps 60 res://tests/PerfTest.tscn
  PERF avg 10.09 ms (99 sim FPS) p95 19.94 ms p99 30.07 ms worst 85.12 ms
```

Rendered desktop evidence: `tests/screenshots_1600x900/` (11 screens) and
`tests/screenshots_1280x720/`.

Web evidence produced for this audit:

- `tests/web_launcher_1600x900.png` — launcher at 1600×900.
- `tests/web_launcher_1280x720.png` — launcher at a 1280×720 window.
- `tests/web_launcher_mobile.png` — narrow layout.
- `tests/web_launcher_game_1600x900.png` — launcher loaded the embedded build.
- `tests/web_play3_level.png`, `web_play3_tower.png`, `web_play3_combat.png` — sector 1,
  tower placement and live combat inside the browser.
- `tests/web_persist_persisted.png` — master volume set to 2% and still 2% after an
  iframe reload, proving IndexedDB persistence.
- `tests/web_menu_reload_game.png` — the web menu with **RELOAD GAME** in place of the
  desktop quit button.
- `tests/web_file_guard.png` — opening `index.html` from `file://`: Deploy is disabled and
  the launcher explains how to start the bundled server.
- `tests/web_pages_home.png` — what a visitor sees at `/Defender/` before clicking:
  Deploy enabled, no notice, iframe not loaded yet.
- `tests/web_pages_launcher.png`, `tests/web_pages_direct.png` — GitHub Pages simulation:
  served from a `/Defender/` sub-path with no COOP/COEP headers. The launcher reaches the
  menu, the direct build boots, and the network log shows no 404s or failed requests.

## Browser-specific notes

- The export uses the **single-threaded** web template, so GitHub Pages does not need
  COOP/COEP headers. `tools/serve.mjs` still sends them for future threaded builds.
- First load transfers roughly 40 MB of WebAssembly; the browser caches it afterwards.
- Chrome headless reports `2D MSAA is not yet supported for GLES3` once. The engine
  falls back cleanly; screenshots show correct rendering.
- On Web the main-menu **QUIT TO DESKTOP** button becomes **RELOAD GAME**
  (`tests/web_menu_reload_game.png`), because a browser tab cannot quit itself.
- The launcher loading overlay is decorative: it fades about one second after Deploy and
  never intercepts a click.
- Local serving defaults to port **8787**. If it is occupied, `tools/serve.mjs` moves to the
  next free port and reports it, so an unrelated old dev server cannot be mistaken for this
  game. `start.bat` / `start.sh` open the actual URL.
- GitHub Pages was simulated under `/Defender/` with a plain static server and no COOP/COEP:
  0 non-200 responses and 0 failed requests. The export is single-threaded
  (`GODOT_THREADS_ENABLED = false`), so Pages needs no special headers.
- Publish the **`Defender` folder itself** as the repository root. Use git or GitHub Desktop:
  GitHub's browser uploader rejects files over 25 MB and `index.wasm` is 39.5 MB. Do not use
  Git LFS. A public repository is required on the free plan.
- `node tools/check-pages.mjs` re-checks required files, exact filename case, relative links,
  `.nojekyll` and the upload limit before each deployment.
- Opening the launcher from the file system cannot work: browsers block `fetch()` of local
  `.wasm`/`.pck` files (`Failed to fetch`). `index.html` detects `file://`, disables Deploy and
  points at `start.bat` / `start.sh`; the deployed Pages URL is unaffected.
- Save data for the web build lives in the browser's IndexedDB for the site origin.
  Clearing site data resets the campaign, same as deleting the local JSON save.

## Known limitations (unchanged)

- Balance is validated by a deterministic bot, not by human players.
- Art is procedural vector-style drawing and audio is synthesized; both are original.
- The design viewport is 1600×900 with `canvas_items` stretch and `expand` aspect.
- Headless exits can print cleanup warnings after all assertions pass.
