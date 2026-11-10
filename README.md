# Mars Arachnid Defense

A complete 2D top-down tower-defense campaign for Godot 4. Defend the First Bastion, the first human outpost on Mars, against two crossing roads of Martian arachnids across 15 sectors.

All art and audio are original and generated locally: terrain, towers, enemies, effects, UI frames and icons are drawn procedurally in GDScript, and the 37 sound effects and ambience loop are synthesized WAV files. There are no plugins, online services, CDNs, paid assets or external runtime dependencies.

## Play in the browser

A ready-to-publish Web export is included, so the game can be played without installing Godot:

- **`index.html`** — a self-contained, themed launcher (no CDN, no external fonts) that loads the game full-screen after a click. It warns about `file://`, missing WebAssembly or missing WebGL 2.
- **`web/`** — the Godot 4 Web export: `index.html`, `index.js`, `index.wasm`, `index.pck` and the icons, produced with the single-threaded template for static hosting.
- **`.nojekyll`** — lets GitHub Pages serve the export verbatim.

The browser build swaps the main-menu **QUIT TO DESKTOP** button for **RELOAD GAME**. A browser
tab cannot quit itself, so the button reloads the page and returns to a clean menu instead.

Run it locally over HTTP (browsers refuse WebAssembly modules from `file://`):

- **Windows:** double-click `start.bat`. It starts the server and opens the browser.
- **macOS / Linux:** run `./start.sh` (or `node tools/serve.mjs 8787 --open`).

Or start the server yourself:

```bash
node tools/serve.mjs 8787 --open
# then open http://127.0.0.1:8787/
```

**Do not open `index.html` by double-clicking it.** The page will load, but the game cannot:
browsers block `fetch()` of local `index.wasm` / `index.pck`, which surfaces as
`Failed to fetch`. The launcher detects `file://`, disables **Deploy** and shows the local-server
instructions instead of failing silently.

`tools/serve.mjs` is a dependency-free static server with the correct `application/wasm` MIME type.
It uses port **8787** by default. If another program already owns that port, it prints a warning,
tries the next free port and opens that URL, so an old dev server cannot make a different game
appear at this project's address. The console always prints the real address it is serving.

### Deploy to GitHub Pages

The repository root must be **this `Defender` folder**: `index.html` has to sit at the top level.
Do not publish the parent `Opencode` folder — its root has no game launcher, so the site root would
show a 404 or a file list. The other game folders (`Disciples*`, `D+D`, etc.) are not part of this
project.

1. Create an empty **public** repository (GitHub Pages is free for public repositories; private
   repositories need a paid plan).
2. Publish this folder with git or GitHub Desktop:

   ```bash
   git init
   git add .
   git commit -m "Mars Arachnid Defense — web build"
   git branch -M main
   git remote add origin https://github.com/<user>/<repo>.git
   git push -u origin main
   ```

   `.gitignore` keeps `.godot/` and local logs out; `web/`, `.nojekyll` and
   `export_presets.cfg` are committed on purpose.
3. In the repository open **Settings → Pages**, choose **Deploy from a branch**, branch
   **main**, folder **/ (root)**, then **Save**.
4. Wait for **“Your site is live at …”**, then open `https://<user>.github.io/<repo>/`
   (keep the trailing slash).

**Do not use the GitHub website uploader for this repository.** GitHub's browser uploader rejects
files larger than **25 MB**, and `web/index.wasm` is **39.5 MB**. Git and GitHub Desktop accept it
(Git's hard per-file limit is 100 MB). Do **not** move the wasm to Git LFS — Pages would serve the
LFS pointer instead of the binary.

No special headers are required: the export is single-threaded, so it runs on plain GitHub Pages
without COOP/COEP. This was verified under a `/repo/` sub-path with a plain static server that sends
no cross-origin headers.

Run the preflight before every deployment:

```bash
node tools/check-pages.mjs
```

It checks the required files, exact filename case (Pages is case-sensitive), relative links,
`.nojekyll`, the single-threaded export and the 25 MB upload limit.

To rebuild the web export after changing the game:

```bash
# one-time: install the matching export templates from the Godot editor
# (Editor → Manage Export Templates) or the official .tpz archive
godot --headless --path . --export-release "Web" web/index.html
```

The `Web` preset in `export_presets.cfg` excludes tests, tools and Markdown from the `.pck`.
After a re-export, commit `web/`, let Pages rebuild, and hard-reload (Ctrl+F5) because the export
is cached briefly.

## Requirements

- **Godot 4.4 or newer** (the project is configured for Godot 4 features and was built and verified with **Godot 4.7.2 stable**).
- Windows, Linux or macOS with a GPU that supports OpenGL 3.3 (the project uses the GL Compatibility renderer).

## Open and run

1. Start Godot 4.4+.
2. Choose **Import**, select this folder's `project.godot`, and confirm.
3. Press **F5** (Run Project).

The main scene is `res://scenes/main/Boot.tscn`; it hands control to `res://scenes/main/MainMenu.tscn` on the first idle frame. You can also run individual scenes from the editor, for example `res://scenes/level/Level_01.tscn`.

From a terminal:

```bash
godot --path .                       # run the game
godot --editor --path .              # open the editor
godot --headless --path . --quit-after 2   # parse/boot smoke test
```

Progress is saved to `user://mars_arachnid_save.json` (on Windows: `%APPDATA%\Godot\app_userdata\Mars Arachnid Defense\`). Delete that file, or use **Settings → Reset Campaign Progress**, to start over.

## Controls

| Input | Action |
| --- | --- |
| Left mouse | Build on a buildable cell, select a tower, confirm a targeted ability |
| Right mouse | Cancel build mode, ability targeting or selection |
| `1`–`9`, `0` | Select tower type from the shop (Pulse, Siege, Flame, Tesla, Missile, Cryo, Rail, Command Relay, Mine Layer, Orbital Lance) |
| `Q` | Orbital Strike (area damage) |
| `W` | EMP Pulse (stun and disable) |
| `E` | Reinforcement Drones (temporary attacking drones) |
| `R` | Emergency Repair (restore base integrity) |
| `T` | Supply Drop (instant credits) |
| `Space` | Send the next wave early for a bonus |
| `U` | Upgrade the selected tower |
| `X` / `Delete` | Sell the selected tower |
| `Tab` | Cycle through placed towers |
| `Esc` | Cancel the current action, otherwise pause |
| `M` | Mute or unmute all audio |
| `F1` / `F2` / `F3` | Simulation speed 1x / 2x / 3x |

HUD buttons also expose Send Wave, speed control and pause. Buttons are sized for touch, and Godot's default mouse-from-touch emulation makes the click-to-place flow usable on touch screens.

## Campaign

- **15 sectors**: five Easy, five Medium and five Very Hard, each with its own two-road crossing layout, blocked cells, economy, terrain theme and 6–14 waves.
- **10 towers**, each with three upgrades: Pulse Turret, Siege Cannon, Flame Vent, Arc Coil, Missile Battery, Cryo Emitter, Rail Sniper, Command Relay, Mine Layer and Orbital Lance.
- **10 enemy types**: Dust Scout, Regolith Worker, Marauder, Acid Spitter, Brood Nurse, Burrower, Shieldbearer, Sand Flyer, Elite Ravager and the Brood Tyrant boss.
- **5 abilities** with cooldowns and limited charges, unlocked progressively.
- Stars are awarded from remaining base integrity. Each sector unlocks the next on victory.

## Project structure

```text
project.godot              Project settings, autoloads, input map, 1600x900 viewport
index.html                 Browser launcher for GitHub Pages (embeds the Web build)
start.bat / start.sh       One-click local server and browser (Windows / macOS+Linux)
web/                       Godot Web export served by GitHub Pages
.nojekyll                  Tells GitHub Pages not to run Jekyll
.gitattributes             Keeps wasm/pck/images byte-exact in git
export_presets.cfg         "Web" export preset (single-threaded, no secrets)
README.md                  This file
FEATURE_AUDIT.md           Feature-by-feature audit, evidence and limitations
PROGRESS_MARS.md           Implementation tracker for the desktop build
PROGRESS_DEPLOY.md         Tracker for the audit, Web export and Pages delivery
Defender.md                Original specification

assets/
  audio/                   37 generated WAV files (SFX + Mars ambience)
  fonts/, textures/        UI font and project icon
resources/
  towers/                  10 TowerData .tres files, each with 3 UpgradeData sub-resources
  enemies/                 10 EnemyData .tres files
  abilities/               5 AbilityData .tres files
  levels/                  15 LevelData .tres files (routes, economy, content, theme)
  waves/                   WaveData .tres files (spawn entries, timing, rewards)
scenes/
  main/                    Boot, MainMenu, LevelSelect, VictoryScreen, DefeatScreen
  level/                   Level_01.tscn … Level_15.tscn
  towers/                  10 tower scenes, Projectile, ProximityMine
  enemies/                 10 enemy scenes
  fx/                      Muzzle, explosion, frost, tesla, missile, heal, acid, EMP, orbital, drone
  ui/                      HUD, shop, tower cards/panel, ability bar, banners, settings, help, pause
scripts/
  autoload/                EventBus, SaveManager, GameState, AudioManager
  core/                    Grid, paths, economy, damage, targeting, waves, abilities, level base
  towers/                  Tower, projectile, mine, data resources, visuals
  enemies/                 Enemy, health bar, data resource, visuals
  fx/                      Combat FX, damage numbers, drones, orbital strike
  ui/                      Screen controllers and shared UIStyle
tests/
  TestRunner.tscn          Mechanics and resource suite
  PlaythroughTest.tscn     All-level victory check with test-only funding
  FairPlayTest.tscn        All-level victory check using only normal economy
  FlowTest.tscn            Settings persistence, mute, pause, victory/defeat wiring
  RestartTest.tscn         Real scene-reload restart check
  ScreenshotTest.tscn      Rendered UI captures
tools/
  build_data.py            Regenerates tower/enemy/ability/level/wave .tres files
  build_scenes.py          Regenerates the repetitive scene files
  build_audio.py           Synthesizes the WAV assets
  serve.mjs                Dependency-free static server for the Web build
  web-shot.mjs             Headless-Chrome smoke test and screenshot for the Web build
  check-pages.mjs          Static GitHub Pages readiness check
```

The scenes under `resources/` and `scenes/` are ordinary editable Godot resources and scenes. Nothing is baked into a monolithic script. `LevelBase.gd` orchestrates the managers, while towers, enemies, projectiles, effects and UI screens are separate scenes that can be opened, duplicated and tuned in the editor.

## Data-driven editing

### Add a new tower

1. Create `resources/towers/tower_<id>.tres` with a `TowerData` script and three `UpgradeData` sub-resources (or copy an existing tower and change the values).
2. Set `id`, `display_name`, `cost`, combat fields, `visual_style`, `primary_color`, `shortcut`, `projectile_scene_path` and `scene_path`.
3. Duplicate `scenes/towers/TowerPulse.tscn` as `scenes/towers/Tower<Name>.tscn`, point its root `tower_data` export at the new resource, and adjust the visual style.
4. Add the id to `LevelBase.TOWER_IDS` in `scripts/core/LevelBase.gd`. The shop and `get_all_tower_data()` build themselves from that list.
5. Add the id to `available_towers` in the `LevelData` resources where it should appear.
6. Open the tower scene and confirm the range indicator, muzzle marker and audio player are present.

### Add a new enemy

1. Create `resources/enemies/enemy_<id>.tres` with an `EnemyData` script (copy an existing one).
2. Set health, speed, armor, bounty, leak damage, resistances, `immune_to`, and any of `flying`, `burrowed`, `shield`, `heal_*`, `ranged_*`, `is_elite`, `is_boss`.
3. Duplicate an enemy scene under `scenes/enemies/`, point `scene_path` in the resource at it, and choose a `visual_style`.
4. Add the id to `LevelBase.ENEMY_IDS`.
5. Reference the enemy id from `SpawnEntry` sub-resources inside wave resources.

### Create or edit a level

1. Copy `resources/levels/level_01.tres` to a new `LevelData` resource and edit `level_number`, text, credits, base health, `grid_width`/`grid_height`, `path_a` and `path_b`.
2. `path_a` and `path_b` are arrays of grid coordinates (`Vector2` in cell units) from the left edge to the right edge. Give them at least one crossing and keep both paths inside the grid. `blocked_cells` are optional `Vector2i` cells that cannot be built on.
3. Set `available_towers`, `unlocked_abilities`, `wave_data_list`, theme colors and `briefing`.
4. Duplicate `scenes/level/Level_01.tscn`, rename it `Level_XX.tscn`, and assign the new `LevelData` to its root `level_data` export. The scene already contains terrain, grid overlay, path network, gates, base core, camera, HUD and pause menu.
5. Register the scene in `GameState.LEVEL_SCENES` and the resource in `GameState.LEVEL_DATA_PATHS`. Level select reads from those arrays.
6. Run `TestRunner` and `FairPlayTest` after changing routes or economy.

### Edit wave data

Wave files live in `resources/waves/`. Each `WaveData` has a delay, an optional early-call bonus, a clear bonus and a list of `SpawnEntry` sub-resources. Each spawn entry selects an enemy id, a route (`path_id` 0 or 1), a count, spacing and start delay. Edit them in the Godot inspector, or change the generators in `tools/build_data.py` and regenerate.

### Regenerate authored content (optional)

Python 3 is only needed if you want to rebuild the repetitive assets; the game itself does not need Python.

```bash
python tools/build_data.py      # rewrite resources/*.tres
python tools/build_scenes.py    # rewrite the generated tower/enemy/level/UI scenes
python tools/build_audio.py     # rewrite assets/audio/*.wav
```

Treat the generated `.tres` and `.tscn` files as editable source once you start tuning in the editor; re-running a generator overwrites those files.

## Tests and verification

Run the suites headlessly from the project folder:

```bash
godot --headless --path . --fixed-fps 60 res://tests/TestRunner.tscn
godot --headless --path . --fixed-fps 60 res://tests/PlaythroughTest.tscn
godot --headless --path . --fixed-fps 60 res://tests/FairPlayTest.tscn
godot --headless --path . --fixed-fps 60 res://tests/FlowTest.tscn
godot --headless --path . --fixed-fps 60 res://tests/RestartTest.tscn
```

Rendered UI captures (requires a display/GPU, do not pass `--headless`):

```bash
godot --path . res://tests/ScreenshotTest.tscn
```

Browser smoke test (Node 20+, Chrome/Edge installed):

```bash
node tools/serve.mjs 8787 --open
node tools/web-shot.mjs "http://127.0.0.1:8787/web/index.html" "tests/web_build_1600x900.png" 1600 900 4000
```

The script waits for the engine canvas, reports console errors and saves a screenshot. To test the launcher page end to end, point it at `index.html` and pass a setup expression that clicks `#playBtn`.

GitHub Pages preflight (no browser or network needed):

```bash
node tools/check-pages.mjs
```

Results from the final verification pass are recorded in `FEATURE_AUDIT.md`. In short: 661 mechanics checks with 0 failures, 35 flow checks with 0 failures, a real restart reload, 15/15 scripted victories with test funding, 15/15 victories using only the normal economy, and a browser build that boots, builds a tower, starts a wave, fights and persists settings across a page reload.

## Known limitations

- Verification is automated and scripted, not a human playtest. The balance bot plays all sectors with normal economy, but human difficulty perception may differ.
- Headless runs may print `ObjectDB instances were leaked` / `resources still in use` warnings during engine shutdown. Assertions finish and the game exits normally; the warnings are an exit-time cleanup limitation of the headless harness, not a gameplay failure.
- The design viewport is 1600x900 with `canvas_items` stretch and `expand` aspect. A 1280x720 window renders the same layout scaled by 0.8 (verified legible); extreme aspect ratios and very small windows are not separately art-directed.
- Art is procedural vector-style drawing and audio is synthesized. It is deliberately readable and original, but not hand-painted or recorded.
- Touch support relies on Godot's mouse-from-touch emulation rather than custom multi-touch gestures.
- The local save is a single JSON file with no cloud sync or multiple profiles. The Web build stores it in the browser's IndexedDB for that site origin; clearing site data resets progress.
- The Web build requests 2D MSAA, which GLES3/WebGL does not support. Chrome logs one warning and the engine falls back; rendering is unaffected.
- The Web build transfers about 40 MB of WebAssembly on first load. It is cached by the browser afterwards, but a slow connection will take a while.
- Opening `index.html` from the file system cannot run the game. Browsers block `fetch()` of local `.wasm`/`.pck` files (`Failed to fetch`); use `start.bat`, `start.sh`, `tools/serve.mjs` or GitHub Pages. The launcher detects this and explains it instead of starting a broken iframe.
- The committed `web/` build is a snapshot. Re-export it after code or resource changes if you deploy through GitHub Pages.
- GitHub Pages needs a **public** repository on the free plan. Publish with git or GitHub Desktop: the website uploader rejects files over 25 MB, and `index.wasm` is 39.5 MB. Do not use Git LFS; Pages would serve the pointer, not the wasm.
- Pages publishes the repository root, including source and docs. The ~50 MB repository is far below Pages' 1 GB site limit, but every first-time player downloads about 40 MB of WebAssembly.
