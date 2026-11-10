# PROGRESS — Mars Arachnid Defense

Context-recovery file for the Godot 4 tower-defense project in this folder.
Format: `[x]` done, `[~]` in progress, `[ ]` not started, `[!]` blocked.
Rule: mark a checkbox done only after the file exists and (where possible) Godot has parsed/run it.
This file is the project's own progress tracker; the supplied `PROGRESS.md` is only the formatting reference.

## Current state

- **Status:** complete and verified; all 15 sectors are playable from the boot scene to the victory screen.
- **Engine:** Godot 4.7.2 stable (local editor kept in `%LOCALAPPDATA%\Temp\opencode\godot`), GDScript, GL Compatibility renderer.
- **Entry point:** `res://scenes/main/Boot.tscn` -> `MainMenu.tscn` -> level scenes.
- **Scope:** 15 levels, 10 towers (3 upgrades each), 10 enemy types, 5 abilities, full campaign UI, original procedural art/audio.
- **Content counts:** 71 scenes, 59 scripts, 184 `.tres` resources (15 levels, 10 towers, 10 enemies, 5 abilities, wave sets), 37 generated WAV files.
- **Verification:** `tests/TestRunner.tscn` 663 checks / 0 failures; `tests/FlowTest.tscn` 35 checks / 0 failures; `tests/RestartTest.tscn` OK; `tests/PlaythroughTest.tscn` 15/15 victories; `tests/FairPlayTest.tscn` 15/15 victories on the normal economy; `tests/PerfTest.tscn` and `tests/StressTest.tscn` report late-wave frame times (see Block 11).
- **Rendered evidence:** `tests/screenshots_1600x900/` (11 screens at 1600x900 and 1280x720-scaled window captures).
- **Known exit-time limitation:** headless runs may print ObjectDB/resource "still in use" warnings after `quit()`; gameplay and all assertions complete normally. Documented in `FEATURE_AUDIT.md`.

## Block 0 — Scaffolding and documentation [x]
- [x] Create `project.godot`, folder tree, `.gitignore`, `README.md`.
- [x] Create this recovery file with every implementation block listed.
- [x] Confirm the project opens/parses in the downloaded Godot 4.7.2 editor and boots to the main menu.

## Block 1 — Data model and resources [x]
- [x] Write `TowerData`, `UpgradeData`, `EnemyData`, `WaveData`, `SpawnEntry`, `LevelData`, `AbilityData` Resource classes.
- [x] Author 10 tower resources with 3 upgrades each.
- [x] Author 10 enemy resources with resistances, shields, healing, burrow, flying and boss data.
- [x] Author 5 ability resources.
- [x] Author 15 level resources with distinct two-road crossing layouts, blocked cells, credits, base health and themes.
- [x] Author 15 wave sets (6–14 waves per level) with deterministic spawn entries, both routes, bosses/elites.
- [x] Validate every `.tres` loads through Godot.

## Block 2 — Autoloads [x]
- [x] `EventBus` signals for HUD/economy/wave/tower/ability decoupling.
- [x] `SaveManager` versioned local JSON save, validation, corrupt-file recovery.
- [x] `GameState` campaign unlock/progress/stats/settings and scene transitions.
- [x] `AudioManager` preloaded procedural SFX, pool, mute/volume, ambience, overlap guard.

## Block 3 — Core simulation [x]
- [x] `GridManager`: cell states, road/buildable/blocked/occupied, snapping, build validation reasons.
- [x] `PathManager`: road rasterisation, crossing paths, waypoints, progress, leak positions.
- [x] `EconomyManager`: credits, purchase/upgrade/sell refund, wave and early-call bonuses.
- [x] `DamageSystem`: armour, resistances, shields, status modifiers, minimum 1 damage, one-time rewards.
- [x] `TargetingSystem`: range, air filtering, first/last/strongest/weakest/closest/highest-HP priorities.
- [x] `WaveManager`: deterministic spawning, both routes, concurrent early calls, completion and level victory.
- [x] `AbilityManager`: cooldowns, limited uses, area/self targeting, pause-safe timers.

## Block 4 — Gameplay scenes [x]
- [x] `Tower.gd` base with placement, selection, upgrades, selling, targeting, buffs, disable/corrosion.
- [x] 10 editable tower scenes with visual root, range indicator, muzzle, animation placeholder, audio player.
- [x] `Enemy.gd` with path following, flying, burrow, shield regen, healing aura, spit, boss phases.
- [x] 10 editable enemy scenes with body, legs, health bar, status anchor, animation and audio.
- [x] `Projectile.tscn`, mines, orbital strike and temporary ability drone scenes.
- [x] FX scenes: muzzle flash, explosion, frost burst, tesla arc, missile trail, death burst, dust cloud, beam.
- [x] `DamageNumber.tscn` and floating feedback.

## Block 5 — Levels and map [x]
- [x] `LevelBase.gd` orchestrating managers, placement ghost, selection, pause, restart, victory/defeat.
- [x] 15 editable `Level_XX.tscn` scenes with grid overlay, path network, spawn gates, base core, terrain props, camera, HUD/pause instances.
- [x] Procedural Mars terrain themes, base structures and decoration that cannot be mistaken for buildable cells.
- [x] Verify every level has two crossing left-to-right roads and no tower placement on roads.

## Block 6 — UI [x]
- [x] `HUD.tscn` top tactical bar, credits, integrity, level, wave, next-wave preview, speed, pause.
- [x] `TowerShop.tscn` + `TowerCard.tscn` with 10 cards, shortcuts, costs, lock/afford states.
- [x] `TowerPanel.tscn` stats, next upgrade preview, upgrade/sell, targeting selector, range toggle.
- [x] `AbilityBar.tscn` + ability buttons with cooldown/uses feedback.
- [x] `WaveBanner.tscn`, `Tooltip.tscn`, notifications, damage numbers.
- [x] `MainMenu.tscn`, `LevelSelect.tscn`, `SettingsPanel.tscn`, `HelpPanel.tscn`.
- [x] `PauseMenu.tscn`, `VictoryScreen.tscn`, `DefeatScreen.tscn` with complete flows.
- [x] Reference-inspired dark graphite / amber / red military console theme, readable at 1600x900 and a 1280x720 window.

## Block 7 — Controls, lifecycle, persistence [x]
- [x] Mouse build/select/upgrade/sell, 1–0 shop, Q/W/E/R/T abilities, Space wave, U, X/Delete, Tab, Esc, M, F1–F3 speed buttons.
- [x] Touch-sized buttons and click-to-place flow (80x96 ability buttons; Godot mouse-from-touch emulation enabled by default).
- [x] Pause freezes simulation/timers/cooldowns; resume restores exactly.
- [x] Restart/menu/next-level cleanup without stale signals; restart verified by a real scene-reload harness.
- [x] Save/load unlocks, stars, totals, settings; contextual Continue button on the main menu.
- [x] Window focus loss safe; fixed 60 Hz physics with a clamped delta (`MAX_DELTA` 0.05, speed-scaled step capped).

## Block 8 — Audio assets [x]
- [x] Generate original local WAV assets: UI, build/upgrade/sell, all tower attacks, enemy hit/death/shield/burrow/boss, base warning, wave/victory/defeat stingers, abilities, Mars ambience (37 files).
- [x] Wire every event; respect mute/volume; no unbounded overlap (18-player pool, 45 ms same-sound guard).

## Block 9 — Verification and balance [x]
- [x] Headless parse and boot test.
- [x] Scripted mechanic tests: placement rejection, upgrades/sell, damage/shield/resist, wave completion, save validation.
- [x] Headless autoplay/balance pass for all 15 levels; tune credits, health, enemy counts.
- [x] Verify victory/defeat/restart/pause, saves, audio mute, UI at two resolutions.
- [x] Record real results and limitations in `FEATURE_AUDIT.md`.

## Block 10 — Final delivery [x]
- [x] `README.md` with open/run instructions, controls, structure, extension guides.
- [x] `FEATURE_AUDIT.md` full table with Working/Partial/Missing/Broken and evidence.
- [x] Final project tree, no external runtime dependencies, no oversized monoliths.
- [x] Final check: main scene, autoloads, 15 levels, 10 towers, 10 enemies, docs.

## Block 11 — Late-wave performance [x]
Goal: keep late waves smooth (Sector 15 waves 12–14 peak near 50 live enemies; the
stress harness deliberately uses 140 as a ~3× worst case).
- [x] `tests/StressTest.gd/.tscn`: spawns N high-health enemies, builds 17 maxed towers,
      reports avg/p50/p95/p99 wall time, engine monitors, draw calls and optional
      per-enemy profiler. Isolation flags: `--no-tower-ai`, `--no-enemy-ai`,
      `--no-visuals`, `--no-map`, `--no-hud`, `--no-towers`, `--no-bars`, `--no-body`,
      `--no-legs`.
- [x] `PathManager`: precomputed cumulative lengths + binary-search `point_at_distance`
      (enemies called it twice per frame).
- [x] `TargetingSystem`: per-physics-frame enemy/tower group caches, squared-distance
      range checks, shared by towers, enemies, mines and drones.
- [x] `EnemyVisual`: body styles baked into one shared atlas (normal + hit-flash
      variant), so a body is one textured quad; legs moved to a single batched
      `EnemyLegsLayer` (≈18 draw commands for the whole swarm, antialiasing off).
- [x] `EnemyHealthBar`: redrawn only when quantized health/shield/status changes.
- [x] `TowerVisual`: 24 Hz redraw only for animated styles (tesla, cryo, relay, mine,
      orbital) or disabled/kick states.
- [x] `Tower`: cached support aura (0.25 s rescan), static projectile-scene cache,
      shallow stat copy, squared distances.
- [x] `Enemy`: aggregated damage numbers per enemy (0.2 s flush + flush on death),
      cached healer/spitter scans.
- [x] `LevelBase`: all FX/beam/damage/mine/orbital/drone/projectile scenes preloaded;
      `MAX_LIVE_EFFECTS = 90`, `MAX_DAMAGE_LABELS = 32`; low-priority FX skipped under
      load; terrain + roads and the build grid baked once into two textures
      (~1100 static draw commands → 2).
- [x] `Projectile`: missile trail drawn from a local polyline instead of spawning a
      `MissileTrail` FX node every 35 ms.

Measured results (NVIDIA GTX 1050 Ti, OpenGL compatibility, vsync off):

| Scenario | Before | After |
| --- | --- | --- |
| Stress 140 enemies, windowed p50 | 66.48 ms | 27.9–30.5 ms |
| Stress 140 enemies, windowed draw calls | 4248 | ≈1490 |
| Stress 140 enemies, headless p50 | 50.32 ms | ≈12.3 ms |
| Stress 50 enemies, windowed p50 | — | ≈18–20 ms |
| PerfTest (real campaign, Sector 15) avg | 10.43 ms | 4.71 ms |

- [x] Regression suites: `TestRunner` 663/0, `FlowTest` 35/0, `FairPlayTest` 15/15,
      `RestartTest` OK, `PerfTest` 14/14 waves.
- [x] Web export rebuilt (`web/`), `node tools/check-pages.mjs` — Pages readiness PASS.
