# PROGRESS — Ashen Crown Combat Prototype

Context-recovery file for the Disciples II-style tactical battle prototype.
Format: `[x]` done, `[~]` in progress, `[ ]` not started.
Last updated after the Canvas 2D rewrite, balance pass, War Camp, responsive pass, tests, AUDIT_V2, the painted party-art pass, procedural audio, English/Russian localisation and the lighting-stability fix.

## Current state (post-fix)

- **Playable and self-contained.** `index.html` + vanilla ES modules + Canvas 2D; no build step, no CDN, no backend, no WebGL requirement.
- **Title:** Ashen Crown. All player-facing text, docs and progress labels are English.
- **Campaign:** 5 fixed heroes vs 5 enemies across 3 encounters (Ruined Watchtower → Sunken Marsh → Bone Cathedral); boss The Hollow King.
- **Combat:** initiative order, 2 rows × 3 columns, front-rank melee protection, Attack / Ability / Defend / Wait / Row, cooldowns, 8 statuses, deterministic seeded RNG, XP/levels, gold and War Camp upgrades.
- **Presentation:** Canvas 2D pseudo-perspective battlefield, painted sky/ground/props for 3 themes, painted-cutout party sprites baked per theme (enemies remain procedural), idle/attack/cast/guard/hit/death poses, shadows, rim light, embers/mist/god rays, screen shake, floating numbers, projectiles/beams/heals. Ambient lighting is steady: no whole-screen pulse, no desynchronised canvas presentation, whole-pixel ray drift.
- **Audio:** procedural Web Audio impact layers by damage type, critical accents, spell/status cues and a quiet per-theme music bed that fades in and changes with each encounter. `M` mutes everything; a master compressor prevents clipping.
- **UI:** reference-style initiative tower, corner medallions, central action wheel, toast/target hints, ability popover, title/help/intro/victory/defeat/campaign screens. English/Russian switch on the title screen; the choice persists and translates the battle HUD, tooltips, log and hints.
- **Tests:** 19/19 passing (16 combat in `tests/combat.test.mjs`, 3 localisation in `tests/i18n.test.mjs`); balance scan and campaign scan pass without deadlock.

## Completed blocks

### Block 1 — Analysis and design brief [x]
- [x] Workspace, references (`1.jpg`, `2.jpg`, `3.jpg`), old docs and all source files read.
- [x] Disciples II pillars extracted: initiative tower, 2-row formation, front-rank protection, action medallion, floating damage, spell effects.
- [x] `disciples2_battle.md` written.

### Block 2 — Pure simulation [x]
- [x] `js/battle/data.js` — 5 heroes, 9 enemy templates, 14 abilities, 8 statuses, 3 encounters, rewards, XP/level rules, `UPGRADES`.
- [x] `js/core/rng.js` — deterministic mulberry32.
- [x] `js/battle/sim.js` — rounds, initiative sort, actions, targeting, damage with armor/resist/shield/guard, status ticks, kill/removal, outcome once, snapshot.
- [x] `js/battle/ai.js` — role-aware enemy decisions; RNG comparator fixed.
- [x] `tests/combat.test.mjs` — 16 regression tests.
- [x] `tests/balance-scan.mjs` — 3 encounters × 6 seeds.
- [x] `tests/campaign-scan.mjs` — campaign with XP, levels, recovery and upgrades.

### Block 3 — Renderer replacement (critical fix) [x]
- [x] Diagnosed the fake “No WebGL” error: old `js/render/scene.js:764` called undefined `makeRidgeTexture`; `App.boot` caught it and showed misleading WebGL copy.
- [x] Removed Three.js from `index.html` and deleted `js/render/models.js`, `js/render/effects.js`, `js/vendor/three.min.js`.
- [x] Rewrote `js/render/scene.js` as Canvas 2D (`paintBackground`, `drawHumanoid`, `drawBeast`, `UnitView`, `CanvasEffects`, `BattleScene`).
- [x] Boot fallback now reports the real error (`js/main.js:73-90`); no WebGL check anywhere.
- [x] Picking, slot projection, active/target/hover rings, shake, ambient embers/mist/rays preserved.
- [x] Visual pass: darker ruins palette, stronger clouds/stars/cloud banks, ash/bones/cracks, green soul-fire, deeper face shadows, rim light, spread formation.
- [x] Responsive scene scale: `sizeK = min(W/900, H/590)` and x-clamping for narrow screens (`js/render/scene.js:1876`, `:1912-1929`).

### Block 4 — Interface and reference layout [x]
- [x] `styles.css` reference-layout overrides: topbar, narrow framed initiative tower, 148 px circular medallions, central action medallion, toast banner, target hint, ability popover, hidden combat log.
- [x] Crowded tower: cards shrink to 46 px when 9+ combatants, so all 10 fit at 1200×800.
- [x] Mid-height (≤700 px) mosaic tower so 800×600 shows all 10 cards without silent scrolling.
- [x] Phone layout (≤620 px): horizontal initiative strip, stacked enemy/ally panels, compact action wheel.
- [x] Tooltip now shows damage range and resistances.
- [x] War Camp CSS and victory-screen upgrade buttons.

### Block 5 — Mechanics and balance [x]
- [x] `shiftDestination` falls back to adjacent/any free slot in the other rank.
- [x] Smite gets `bonusVs: 'undead'`, `bonusAmount: 0.5`; `rollDamage` applies it.
- [x] Boss enrage triggers at ≤50% HP via `checkEnrage`.
- [x] Extra Crossbowman in Watchtower (B1) and third Bog Lurker in Marsh (F2) to reduce trivial difficulty.
- [x] Extra Skeleton Warrior in Cathedral (B0) so the finale survives a damage-race check; no-progression parties now usually lose, progressed parties win in 9–10 rounds.
- [x] War Camp gold sink: Sharpen Blades (+2 damage, 100 gold, max 4), Reinforce Armour (+2 armour, 90 gold, max 4), Field Hospital (full heal, 70 gold).
- [x] Victory screen shows rounds, damage, kills, losses, XP, gold, level-ups and War Camp with costs/caps/disabled states.
- [x] `window.__combat` API retained: state, snapshot, actions, targets, startEncounter, begin, act, chooseTarget, cancel, pause/resume, restart, title, setFast/setMuted, inspect, party.
- [x] Favicon 404 fixed with an inline SVG data URI; viewport zoom no longer disabled.

### Block 6 — Audit and documentation [x]
- [x] `AUDIT_V2.md` written with verdict, 12 scores, TOP-10, full table, removal list, rebuild-vs-patch, must-not-break, bug repros, juice ideas, missing features, 3-stage roadmap.
- [x] Exact “No WebGL” cause documented (`makeRidgeTexture` ReferenceError, old `js/render/scene.js:764`).
- [x] Stale `AUDIT.md` and `FEATURE_AUDIT.md` removed.
- [x] `PROGRESS.md` and `README.md` rewritten for the Canvas 2D build.

### Block 7 — 3D party models [x] (superseded by Block 9)
- [x] Mapped the five heroes to the GLBs in `glb/`: Ji'An → `dnd_dwarf`, Dain → `eisen_frieren…dwarf_male`, Tsok-Tsok → `wendigo`, Ilman → `miniature_firbolg`, Amuntia → `brunhilda`.
- [x] Headless-Chrome baker (`tools/build-party-assets.mjs`) normalizes each model by height, lights it per district, and bakes a 220×232 logical sprite at 3× plus a 512 px portrait.
- [x] Three theme variants per hero (`ruins`, `marsh`, `cathedral`), plus front/side view overrides and firbolg-plinth cleanup.
- [x] `js/render/party-models.js` preloads/caches sprites; `UnitView` draws them with lunge/cast/guard/walk/hit/death transforms and hero-specific body height.
- [x] HUD ally portraits replaced; bundle rebuilt; all three encounters verified by screenshot and a full auto-play victory.

### Block 8 — Audio, lighting and language [x]
- [x] Added type-aware impact SFX in `js/audio/sfx.js`: shared low body thump plus steel, fire, frost, holy or poison transients, with heavier critical layers and pitch jitter.
- [x] Added a master `DynamicsCompressor` so overlapping impacts and music cannot clip.
- [x] Added a procedural music bed per theme (`ruins`, `marsh`, `cathedral`): detuned pad voices, sub bass, sparse bells and a quiet echo; fades in over 4.5 s and retunes the filter when the encounter changes.
- [x] Raised the music bed to an audible-but-unobtrusive level and reduced bell density so loops do not feel mechanical.
- [x] Wrote `js/core/i18n.js` (English/Russian) with static UI tables, content overrides for units/abilities/statuses/upgrades/encounters and runtime error translation; language is persisted in `localStorage`.
- [x] Added the language picker to the title screen (`js/ui/hud.js`, `styles.css`) and rebuilds the open overlay immediately after a switch.
- [x] Finished localisation of runtime messages in `js/main.js`: hints, ability/upgrade names, round announcements, target banner, GUARD/WAIT/STUNNED floats and status names now follow the selected language.
- [x] Removed the whole-screen lighting pulse; kept ray opacity constant; particle twinkle softened and disabled under `prefers-reduced-motion`; ray drift snapped to whole pixels.
- [x] Confirmed the canvas no longer uses `desynchronized: true` (periodic black/bright flashes on some Windows GPUs).
- [x] Rebuilt `js/ashen-crown.js`; 19/19 tests pass (16 combat + 3 localisation).

### Block 9 — Painted party art [x]
- [x] Replaced the GLB renders with the painted characters in `glb/01.png`–`04.png`: Ji'An (dark elf duelist) and Amuntia (white familiar-mage) split from 01, Tsok-Tsok (horned faun) from 02, Dain (dwarf engineer) from 03, Ilman (blue leonid caster) from 04.
- [x] Added `tools/build-party-art.py`: alpha-component split for 01, checkerboard palette + GrabCut removal for 02–04, per-theme grading/rim light, 660×696 sprites (3× the 220×232 logical canvas, feet at y=606) and 512 px portraits.
- [x] Tuned relative heights so the dwarf reads clearly short: Ji'An 172, Amuntia 154, Tsok-Tsok 166, Dain 128, Ilman 188.
- [x] Updated `js/render/party-models.js` source/height metadata and `package.json` (`party` now runs the Python baker; `party:glb` keeps the legacy GLB path).
- [x] Rebuilt the bundle, passed 19/19 tests plus both scans, and verified all three encounters by 1200×800 headless screenshots.

### Block 10 — Dain/Ji'An battlefield swap [x]
- [x] Swapped Dain and Ji'An in every encounter: Dain now starts in `F1` and Ji'An in `F0`, so the dwarf takes the dark elf's old front slot and vice versa.
- [x] Kept each hero's portrait, stats and abilities bound to their id, so the dwarf moves as Dain (Shieldbearer) and the dark elf moves as Ji'An (Warden); nothing is duplicated or orphaned.
- [x] Updated the initiative-order regression test and the row-change messages, rebuilt the bundle, and re-verified all three encounters by screenshot.

### Block 11 — Ruins foreground cleanup [x]
- [x] Removed the broken foundry wall and its red banner from the far left of the Ruins foreground; it overlapped the leftmost hero and read as a house with a flag.
- [x] Kept the brazier, ground grass, distant skyline and background buildings untouched; the change is isolated to `paintForgeProps` for the `ruins` theme.
- [x] Rebuilt the bundle and verified the Ruins screenshot at 1200×800.

### Block 12 — Dain/Tsok-Tsok art refresh [x]
- [x] Replaced Dain's source with `glb/003.jpeg` (red-haired dwarf engineer with hammer and goggles) and Tsok-Tsok's with `glb/001.png` (horned faun ranger with axe).
- [x] Added white-background removal and direct-alpha loading to `tools/build-party-art.py`; tuned the portrait crops to the new poses.
- [x] Re-baked all 15 theme sprites and both portraits, updated the source metadata, rebuilt the bundle and verified all three encounters by screenshot.

### Block 13 — Hero rename [x]
- [x] Renamed all five heroes in English and Russian across data, i18n, rendering, tests, tools, asset filenames and docs.
- [x] Mapping: Vela → Amuntia (Амунтия), Mirelle → Tsok-Tsok (Цок-Цок), Oszar → Ilman (Ильман), Bran → Dain (Даин), Aldric → Ji'An (Джи'Ан).
- [x] IDs: `amuntia`, `tsok-tsok`, `ilman`, `dain`, `jian`. `tsok-tsok` keeps its hyphen in filenames and UIDs because UIDs are never split on hyphens.
- [x] Regenerated all 15 theme sprites and 5 portraits under the new filenames, removed the old files, rebuilt the bundle and verified all three encounters.

## Verification commands

```bash
node --test tests/combat.test.mjs tests/i18n.test.mjs   # 19 pass, 0 fail
node tests/balance-scan.mjs            # 3 encounters × 6 seeds
node tests/campaign-scan.mjs           # full campaign with XP/upgrades
python tools/build-party-art.py        # re-bake 15 party sprites + 5 portraits from glb/
```

Local server on this machine must be Node (Python `http.server` returns empty replies):

```powershell
Start-Process node -ArgumentList "server.cjs" -WorkingDirectory "C:\Users\petrukmax\Documents\Opencode\Disciples" -WindowStyle Hidden
curl.exe -s -o NUL -w "%{http_code}" http://127.0.0.1:8124/index.html
```

Headless screenshots use `node tools/cdp-shot.mjs <url> <out.png> <w> <h> "<setup>" [waitMs]` with Chrome `--headless=new --enable-unsafe-swiftshader`; step JSON must be UTF-8 **without BOM**.

## Known limitations (open)

- [ ] Enemy art is still flat procedural vector art while the five heroes are painted cutouts; the two styles sit side by side.
- [ ] Hero sprites have one baked pose each; attack/cast motion is transform-only (the source art is a single illustration per hero).
- [ ] Audio has a global mute only; no separate music/SFX volume sliders.
- [ ] Progression is stat-only; abilities never unlock, no perk choices.
- [ ] No save/load; refresh loses the campaign.
- [ ] Content is 3 encounters / 9 enemy templates / one boss (~15 min); low replayability.
- [ ] Combat log exists but is hidden (`styles.css:2822`); no event review/accessibility narration.
- [ ] Enemy AI is predictable and focus-fires low HP; no repositioning/healer protection.
- [ ] Phones are playable but cramped; 800×600 mosaic hides names.
- [ ] No damage preview; tooltip shows stats but not expected damage.
- [ ] War Camp purchase logic is not directly unit-tested (campaign scan re-implements it).
- [ ] Headless software rendering ~41 fps at 1200×800; no offscreen pose caching.
- [ ] No renderer/UI smoke test; visual regressions checked manually via screenshots.

## Next move

1. Extract `purchaseUpgrade(party, campaign, kind)` into `js/battle/data.js` and unit-test gold/max/heal guards.
2. Add a collapsible Chronicle drawer fed by `battle.log`; reuse it for `aria-live` announcements.
3. Add damage preview and persist Fast mode; shorten the default 430 ms enemy wait.
4. Add separate music/SFX volume sliders and let the player switch language from the pause menu.
5. Add save/load (`localStorage`, encounter boundary only) and a Continue button.
6. Add ability unlocks/perks at levels 4/5/6.
7. Only then invest in painted/baked sprites for the enemies and the remaining procedural portraits.

## Key files

- `js/render/scene.js` — Canvas 2D battlefield, sprites, effects, picking, responsive projection.
- `js/render/party-models.js` — hero/art map, theme sprite cache, portrait URLs.
- `js/main.js` — app shell, campaign, input, targeting, presentation queue, War Camp, `window.__combat`.
- `js/battle/sim.js` — pure turn engine.
- `js/battle/data.js` — templates, abilities, statuses, encounters, rewards, XP, upgrades.
- `js/battle/ai.js` — enemy decisions.
- `js/ui/hud.js` — DOM UI, queue, panels, tooltip, overlays, War Camp.
- `js/ui/portraits.js` — procedural enemy portraits at 2× resolution.
- `js/core/i18n.js` — English/Russian UI, content and dynamic-error translation.
- `js/audio/sfx.js` — procedural Web Audio impacts and per-theme ambient music.
- `tools/build-party-art.py` — cuts the painted heroes out of the source images in `glb/`, grades them per theme and bakes `assets/party/`.
- `tools/build-party-assets.mjs` — legacy GLB baker kept for reference (`npm run party:glb`).
- `styles.css` — reference layout, responsive modes, War Camp, crowded tower.
- `AUDIT_V2.md` — current evidence-based audit and roadmap.
