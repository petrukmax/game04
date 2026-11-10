# Mars Arachnid Defense — Complete Godot Tower Defense Prompt

You are an expert game designer, gameplay programmer, technical artist, UI designer, and QA engineer. Build a complete, polished, playable 2D top-down tower defense game in Godot 4, called Mars Arachnid Defense. The game must be a finished, balanced, replayable strategy experience, not a mockup, prototype fragment, or list of suggestions.

The player defends the first human outpost on Mars from waves of hostile arachnids. The game is inspired by the general structure and readability of classic fantasy tower defense games, but all names, creatures, visual designs, interface art, audio, levels, and mechanics must be original. Do not copy assets, exact layouts, enemy designs, or interface artwork from any existing game or film.

All player-facing text, controls, tooltips, menus, notifications, documentation, and feature-audit notes must be in English. Code comments, scene names, folder names, resource names, and documentation must also be in English for maintainability.

## 1. Core vision

Mars Arachnid Defense is a top-down, grid-based tower defense game set on a hostile red planet. Two main roads cross the map from left to right and intersect near the center. Hostile arachnids advance along these roads toward the human base on the right side of the map. The player builds defensive towers on buildable grid cells beside the roads, manages limited credits, upgrades towers, uses abilities at critical moments, and survives 15 increasingly difficult waves.

The experience must offer

- Clear top-down strategy place towers, anticipate enemy routes, upgrade at the right time, and survive escalating waves.
- Two long, readable enemy paths that cross in the middle of the map, creating natural chokepoints and tactical decisions.
- A visible square grid across the entire playable map.
- Towers may be placed only on empty, buildable grid cells that are not on either road.
- Ten distinct tower types with different roles, ranges, damage types, targeting behavior, upgrade paths, strengths, and weaknesses.
- Fifteen handcrafted levels with explicit difficulty progression levels 1–5 are easy, levels 6–10 are medium, and levels 11–15 are very difficult.
- A meaningful economy early levels provide enough credits to learn, while later levels require careful planning, tower synergy, sellingrebuilding decisions, and efficient ability use.
- Enemy variety fast scouts, armored walkers, swarmers, ranged spitters, healers, burrowers, shielded units, flying units, elite variants, and bosses.
- A readable military-science-fiction interface inspired by the supplied reference image dark industrial panels, amber and red warning accents, compact tactical HUD, clear tower cards, wave information, credits, lives, and pause controls.
- Procedurally generated or locally authored visual and audio assets; no external runtime asset downloads, no CDN dependencies, and no required online services.
- A project structured specifically for Godot modular scenes, reusable components, editable nodes, exported resources, and data-driven level definitions. The player must be able to open the project in the Godot editor and move, replace, duplicate, rename, or tune individual scenes, towers, enemies, props, UI elements, and level objects.

Prioritize correctness, balance, readability, and completion first. Visual polish, particle effects, sound design, and optional content come after the core game is stable.

## 2. Inspect before building

If a Godot project already exists

1. Read the project structure, `project.godot`, main scene, autoloads, level scenes, tower scenes, enemy scenes, wave data, UI scenes, and scripts.
2. Identify the actual playable entry point and determine which features already work.
3. Preserve working systems, approved art direction, existing level layouts, and user-requested behavior.
4. Extend the active project in place. Do not create a competing duplicate project folder merely to avoid integrating changes.
5. Identify incomplete, broken, unbalanced, or missing systems before adding new content.
6. Keep unrelated files and prior work intact.

If starting from scratch, create the complete baseline inventory with every required feature marked as missing, then implement the full specification below. Adapt exact coordinates, colors, enemy stats, and wave values when testing shows that balance or readability requires it, but preserve the required structure and scope.

## 3. Godot technical delivery

Use Godot 4.x with GDScript. The project must be openable and runnable directly from Godot without external plugins, paid assets, online account requirements, or mandatory build steps.

### Project structure

Use a clear, modular project structure similar to this

```text
res
  project.godot
  README.md
  FEATURE_AUDIT.md
  PROGRESS.md
  scenes
    main
      Main.tscn
      Boot.tscn
      MainMenu.tscn
      LevelSelect.tscn
      PauseMenu.tscn
      VictoryScreen.tscn
      DefeatScreen.tscn
    level
      LevelBase.tscn
      Level_01.tscn
      Level_02.tscn
      Level_03.tscn
      Level_15.tscn
      GridOverlay.tscn
      PathNetwork.tscn
      BaseCore.tscn
      SpawnGate.tscn
    towers
      TowerRoot.tscn
      TowerGun.tscn
      TowerCannon.tscn
      TowerFlamer.tscn
      TowerTesla.tscn
      TowerMissile.tscn
      TowerFrost.tscn
      TowerSniper.tscn
      TowerSupport.tscn
      TowerMineLayer.tscn
      TowerOrbital.tscn
    enemies
      EnemyRoot.tscn
      Scout.tscn
      Worker.tscn
      Warrior.tscn
      Spitter.tscn
      Healer.tscn
      Burrower.tscn
      Shieldbearer.tscn
      Flyer.tscn
      Elite.tscn
      Boss.tscn
    ui
      HUD.tscn
      TowerShop.tscn
      TowerPanel.tscn
      WaveBanner.tscn
      AbilityBar.tscn
      Tooltip.tscn
      DamageNumber.tscn
    fx
      MuzzleFlash.tscn
      Explosion.tscn
      FrostBurst.tscn
      TeslaArc.tscn
      MissileTrail.tscn
      DeathBurst.tscn
      DustCloud.tscn
  scripts
    autoload
      GameState.gd
      AudioManager.gd
      SaveManager.gd
      EventBus.gd
    core
      LevelManager.gd
      WaveManager.gd
      EconomyManager.gd
      GridManager.gd
      PathManager.gd
      TargetingSystem.gd
      DamageSystem.gd
      AbilityManager.gd
    towers
      Tower.gd
      TowerData.gd
      TowerUpgrade.gd
      Projectile.gd
      AreaEffect.gd
    enemies
      Enemy.gd
      EnemyData.gd
      EnemyMovement.gd
      EnemyAI.gd
      EnemyHealth.gd
    ui
      HUDController.gd
      TowerShopController.gd
      TowerPanelController.gd
      WaveBannerController.gd
      TooltipController.gd
  resources
    towers
      tower_gun.tres
      tower_cannon.tres
      tower_flamer.tres
      tower_tesla.tres
      tower_missile.tres
      tower_frost.tres
      tower_sniper.tres
      tower_support.tres
      tower_mine_layer.tres
      tower_orbital.tres
    enemies
      enemy_scout.tres
      enemy_worker.tres
      enemy_warrior.tres
      enemy_spitter.tres
      enemy_healer.tres
      enemy_burrower.tres
      enemy_shieldbearer.tres
      enemy_flyer.tres
      enemy_elite.tres
      enemy_boss.tres
    levels
      level_01.tres
      level_02.tres
      level_15.tres
    waves
      wave_data_level_01.tres
      wave_data_level_15.tres
  assets
    audio
    fonts
    textures
```

This structure is a required architectural target. Exact file names may be adjusted, but the project must remain modular, readable, and editable in the Godot editor.

### Scene-first architecture

Every gameplay object must be a separate, editable Godot scene or reusable component. Do not build the game as one enormous monolithic script or one giant scene containing all gameplay.

Required scene separation

- Each tower is its own `.tscn` scene with its own visual root, range indicator, muzzle point, projectile spawn point, animation player or animation player placeholder, audio player, and script.
- Each enemy type is its own `.tscn` scene with its own body, legs, health bar, status-effect anchor, path follower, animation, audio, and script.
- Each projectile, explosion, beam, mine, frost field, support aura, and visual effect is its own reusable scene.
- The HUD, tower shop, tower inspection panel, wave banner, ability bar, tooltip, damage numbers, pause menu, victory screen, and defeat screen are separate scenes.
- Each level is its own `.tscn` scene. Level scenes must contain editable road segments, spawn gates, base core, grid overlay, decorative props, camera limits, wave data reference, and level-specific settings.
- Towers, enemies, projectiles, and effects must be movable, duplicable, renamed, disabled, replaced, and tuned directly in the Godot editor.

### Data-driven design

Store tower stats, enemy stats, upgrades, wave compositions, level settings, and ability definitions in exported Godot resources (`Resource`  custom `Resource` classes), not hardcoded inside gameplay scripts.

At minimum, define

- `TowerData` id, display name, description, cost, sell value, damage type, base damage, attack rate, range, projectile speed, splash radius, slow amount, armor penetration, target priority, upgrade costs, upgrade stat changes, visual scene path, projectile scene path, sound events, and maximum level.
- `EnemyData` id, display name, description, max health, speed, armor, resistance types, bounty, leak damage, flying state, burrow state, shield amount, healing aura, spawn weight, visual scene path, and optional special behavior.
- `WaveData` wave index, enemy spawn entries, spawn delay, group size, spawn interval, path assignment, healthdamage scaling, reward, and optional boss configuration.
- `LevelData` level id, display name, starting credits, base health, available towers, unlocked abilities, path layout reference, grid dimensions, wave data list, difficulty rating, environment theme, and completion rewards.
- `UpgradeData` upgrade level, cost, stat modifiers, new behavior flags, visual changes, and short English description.

The game must remain playable if a designer edits a `.tres` file in the Godot inspector changing tower damage, enemy health, wave composition, level credits, or path layout must immediately affect gameplay without requiring code changes.

### Simulation and rendering separation

Separate authoritative gameplay simulation from presentation

- `GridManager` owns buildable cells, occupied cells, road cells, blocked cells, tower placement validation, and grid coordinates.
- `PathManager` owns enemy waypoints, road intersections, path distances, enemy progress, and leak detection.
- `WaveManager` owns wave sequencing, enemy spawning, wave completion, early-wave bonus, and level progression.
- `EconomyManager` owns credits, tower purchase cost, upgrade cost, sell refunds, wave rewards, and interest or bonus rules if implemented.
- `DamageSystem` owns damage calculation, armor, resistances, shields, status effects, healing, and death.
- `TargetingSystem` owns target acquisition, range checks, target priority, flyingground filtering, and line-of-sight rules where applicable.
- Visual nodes, particles, animations, camera shake, floating numbers, and sound effects must never determine damage, targeting, enemy progress, wave completion, or victorydefeat.

Use a fixed simulation step where appropriate, for example 160 second, with delta-time clamping to prevent large frame spikes from breaking movement, projectiles, or status timers.

### Single-threaded mode

The game must run in a predictable single-threaded execution model

- Do not use `Thread`, `Mutex`, `WorkerThreadPool`, background asset generation, or asynchronous gameplay logic for core simulation.
- Use Godot’s normal main-loop processing, signals, timers, and scene tree.
- Keep enemy movement, targeting, projectile collision, damage, wave progression, and economy updates on the main thread.
- Use object pooling or controlled instantiationremoval for projectiles, effects, damage numbers, and enemies.
- Avoid per-frame allocations in hot paths where practical.
- Ensure that restarting a level, returning to the menu, advancing to the next level, pausing, and resuming do not leak nodes, timers, audio players, particles, signals, or input connections.

## 4. Map, camera, and grid

### Camera and view

Use a fixed or gently adjustable top-down camera with a slight perspective or angled overhead view. The entire battlefield must be readable without excessive camera movement.

The map should feel like a Martian military outpost

- Red-orange regolith, dusty plains, rocky terrain, scattered stones, cracked ground, and dry channels.
- Human structures landing pads, habitat modules, storage containers, solar arrays, antenna masts, cargo crates, barricades, and defensive lighting.
- A dark blue-black sky or deep space gradient above the horizon if the camera angle reveals it.
- Dust haze, distant hills, and subtle atmospheric depth.
- Warm sunlight with long shadows and restrained red-orange ambient light.

Do not make the map visually noisy. Roads, buildable cells, enemies, towers, and the base must remain instantly readable.

### Map layout

Each level must contain

- A large playable map divided into a visible square grid.
- Two main enemy roads running generally from left to right across the full map.
- The two roads must intersect, ideally near the center, creating a recognizable crossing or junction.
- A spawn area on the left side of the map.
- The human base or core structure on the right side of the map.
- Clear boundaries so enemies cannot leave the map or bypass the base through undefined space.
- Enough buildable cells beside both roads to allow multiple viable defensive strategies.
- Decorative terrain that never blocks enemy movement, hides towers, or creates false buildable cells.

The two roads may be straight, gently curved, or composed of connected waypoints, but they must both cross the map from left to right. They may converge, split, overlap at a central intersection, or form a crossing pattern, provided enemy routes remain readable and strategically meaningful.

### Grid system

The entire map is divided into a uniform square grid.

Requirements

- Define a grid cell size appropriate for tower placement, for example 1.0 x 1.0 world units, 2.0 x 2.0 units, or another consistent scale.
- Render a subtle but visible grid overlay during building mode.
- Each cell must have an explicit state `EMPTY`, `BUILDABLE`, `ROAD`, `BLOCKED`, `OCCUPIED`, or `DECORATION_ONLY`.
- A tower may be placed only on a cell marked `BUILDABLE` and currently `EMPTY`.
- Cells belonging to either road must be marked `ROAD` and must reject tower placement.
- Cells occupied by an existing tower must be marked `OCCUPIED`.
- Cells covered by mandatory scenery, base structures, spawn gates, rocks, cliffs, or other impassable objects must be marked `BLOCKED`.
- Hovering over a valid cell must show a clear placement preview tower footprint, range circle, cost, and validinvalid color.
- Hovering over an invalid cell must show a clear reason “Road”, “Occupied”, “Blocked”, or “Not enough credits”.
- Tower placement must snap to the grid.
- Towers must never overlap roads, other towers, base structures, or mandatory obstacles.
- The grid must be data-driven so a designer can change road placement, blocked cells, and buildable cells in the Godot editor.

### Tower placement rule

This rule is mandatory

- Towers cannot be placed on either road.
- Towers can be placed only on empty buildable cells adjacent to or near the roads.
- A tower must be able to attack enemies on at least one road; otherwise its placement should still be allowed only if it has a strategic support role, such as a global buff tower, mine layer, radar tower, or economy tower.
- The placement system must validate range, cell state, credits, tower availability, and level-specific restrictions before confirming construction.
- Placement must never partially overlap a road, another tower, or an impassable object.

## 5. Core gameplay loop

The standard loop is

1. The player enters a level with a fixed amount of starting credits and base health.
2. The player inspects the map, identifies road routes and chokepoints, and builds initial towers.
3. The player presses Start Wave.
4. Enemies spawn from the left-side gates and travel along the two roads toward the base.
5. Towers attack enemies according to their range, targeting rules, damage type, and special behavior.
6. Enemies that reach the base damage the base and disappear.
7. When all enemies in the wave are defeated or have leaked, the wave ends.
8. The player receives credits based on enemy kills, wave completion, and optional early-call bonus.
9. The player builds new towers, upgrades existing towers, sells unnecessary towers, or saves credits.
10. The player starts the next wave.
11. After surviving all waves, the level is complete.
12. If base health reaches zero, the level is failed and the player may retry.

The player must be able to build and upgrade towers between waves. Building during an active wave must also be allowed, provided the interface remains readable and the action is intentional.

## 6. Towers

Implement at least 10 distinct tower types. Each must have a clear tactical role, readable visual identity, meaningful upgrades, and a reason to exist in the late game.

### Tower roster

 Tower  Role  Base behavior  Upgrade direction 
------------
 Pulse Turret  Basic single-target damage  Fast kinetic shots against ground enemies  Higher fire rate, damage, range, armor penetration 
 Siege Cannon  Heavy single-target damage  Slow explosive shell with splash damage  Larger splash, more damage, armor break 
 Flame Vent  Close-range area denial  Short-range cone or circular burn damage  Burn damage, wider cone, longer burn duration 
 Arc Coil  Chain lightning  Hits one target, then chains to nearby enemies  More chains, higher damage, brief stun chance 
 Missile Battery  Anti-swarm and anti-air  Homing missiles, effective against grouped and flying enemies  More missiles, splash radius, air damage 
 Cryo Emitter  Crowd control  Slows enemies in an area or on hit  Stronger slow, larger radius, freeze chance 
 Rail Sniper  Long-range precision  Very long range, high single-target damage  Armor piercing, critical damage, execution bonus 
 Command Relay  Support and economy  Buffs nearby towers or generates credits  Larger aura, stronger buff, interest bonus 
 Mine Layer  Trap-based area defense  Places mines on nearby road cells  More mines, larger blast, armor reduction 
 Orbital Lance  Late-game ultimate tower  Charges a powerful delayed orbital strike  Faster charge, larger strike, burn aftereffect 

All ten tower types are required. Additional towers may be added only if they are fully implemented, balanced, documented, and integrated into level progression.

### Tower rules

- Every tower must display its current range before and after placement.
- Every tower must show its upgrade cost, next-upgrade preview, current level, damage type, and sell value.
- Every tower must support at least three upgrade levels, or a clearly documented upgrade path.
- Upgrades must provide meaningful improvements, not only small numeric increases.
- Selling a tower must refund a predictable percentage of its total invested cost, for example 60–75 percent.
- Towers must not block roads.
- Towers must have readable attack feedback muzzle flash, recoil, projectile, impact effect, sound, and damage number where appropriate.
- Tower attacks must respect enemy armor, resistances, shields, flying status, and burrowed status where relevant.
- Tower targeting must be configurable per tower first, last, strongest, weakest, closest, flying-first, or highest-health.
- The player must be able to change targeting priority for towers that support it.
- Tower range indicators must not obscure the map or remain visible during active combat unless intentionally selected.

### Example starting values

Use these as a starting balance framework, then tune through testing

 Tower  Cost  Damage type  Range  Role 
---------------
 Pulse Turret  100  Kinetic  Medium  Reliable early damage 
 Siege Cannon  180  Explosive  Medium  Groups and armored enemies 
 Flame Vent  140  Fire  Short  Chokepoint area denial 
 Arc Coil  220  Electric  Medium  Groups and chains 
 Missile Battery  260  Explosive  Long  Swarms and flyers 
 Cryo Emitter  200  Frost  Medium  Slow and control 
 Rail Sniper  300  Kinetic  Very long  High-value and armored targets 
 Command Relay  250  Support  Aura  Economy and tower buffs 
 Mine Layer  180  Explosive  Road-adjacent  Trap-based burst damage 
 Orbital Lance  500  Energy  Long  Bosses and dense waves 

These values are starting references, not fixed final balance. The final economy must be validated through actual playtesting.

## 7. Enemies

Implement at least 10 enemy types, including normal enemies, special enemies, elite variants, and bosses. Enemies must be visually distinct at a glance through silhouette, size, color, leg count, armor, glow, movement style, and attack behavior.

### Enemy roster

 Enemy  Role  Behavior 
---------
 Scout  Fast weak enemy  Moves quickly, appears in groups, low health 
 Worker  Basic swarm enemy  Slow, cheap, numerous, low damage 
 Warrior  Standard melee threat  Balanced health, speed, and armor 
 Spitter  Ranged threat  Stops or slows near towers to spit acid; damages towers or applies corrosion 
 Healer  Support enemy  Heals nearby arachnids; must be prioritized by the player 
 Burrower  Ambusher  Travels underground, immune to most attacks while burrowed, emerges near towers or at intersections 
 Shieldbearer  Defensive enemy  Has a rechargeable shield that absorbs damage before health 
 Flyer  Air threat  Ignores ground obstructions and requires anti-air capability 
 Elite  Mini-boss  Larger, tougher, with a special ability such as armor, speed burst, or summoning 
 Boss  Level-ending threat  Large, durable, multi-phase, with visible abilities and a clear weakness 

### Enemy behavior requirements

- Enemies must follow road waypoints smoothly and predictably.
- Enemies must not walk through towers, base structures, rocks, or other impassable terrain.
- Enemies must not cut across the map unless their type explicitly allows it, such as a burrowing enemy with a defined emergence point.
- Enemies must have readable health bars or damage feedback.
- Enemies must show status effects clearly burning, slowed, frozen, stunned, corroded, shielded, healed, or marked.
- Enemies must award credits only once when killed.
- Enemies that reach the base must apply leak damage exactly once and then be removed.
- Enemy movement must remain stable when towers are built, sold, upgraded, or destroyed.
- Enemy pathfinding must support intersections, merging routes, and split routes.
- Enemies must not stall, vibrate, overlap permanently, or become unreachable.
- Boss enemies must have visible health bars, named abilities, telegraphed attacks, and fair counterplay.

### Damage and resistances

Use clear damage types

- Kinetic
- Explosive
- Fire
- Electric
- Frost
- Corrosive
- Energy

Each enemy type must have explicit resistances and weaknesses. For example

- Armored enemies resist kinetic damage but take more explosive or corrosive damage.
- Swarm enemies are vulnerable to splash, chain, and area effects.
- Flying enemies cannot be hit by ground-only towers.
- Burrowed enemies are immune to most direct attacks until they emerge.
- Shielded enemies require shield damage before health damage.
- Healers must be targetable and dangerous enough that ignoring them creates a real problem.

Damage calculation must be transparent and testable

1. Determine base damage.
2. Apply tower upgrades and buffs.
3. Apply enemy armor or resistance.
4. Apply shields.
5. Apply status effects.
6. Apply final damage to health.
7. Clamp damage to a minimum of 1 when a hit connects, unless an explicit immunity rule applies.
8. Award credits and score only once per killed enemy.

## 8. Waves and progression

The game contains 15 levels. Each level consists of multiple waves, culminating in a final wave that may include an elite enemy or boss.

### Difficulty curve

 Level range  Difficulty  Design goal 
---------
 1–5  Easy  Teach tower placement, basic enemy types, upgrades, selling, and wave timing 
 6–10  Medium  Introduce armored enemies, flyers, healers, burrowers, shieldbearers, and route pressure 
 11–15  Very difficult  Require planned economies, tower synergy, ability timing, upgrades, and precise defense 

Levels 11–15 must be genuinely challenging. The player should not be able to win them by placing a few towers and waiting. They must require

- Efficient early-game credit spending.
- Correct tower composition.
- Upgrades at the right time.
- Selling and rebuilding when necessary.
- Use of abilities during dangerous moments.
- Awareness of both roads and the central intersection.
- Preparation for flyers, burrowers, healers, shields, and bosses.
- No excessive reliance on a single overpowered tower.

### Wave design rules

- Every level must have a clear wave count, for example 8–15 waves depending on level length.
- Early waves must introduce one new concept at a time.
- Later waves must combine familiar threats in demanding ways.
- Enemies must spawn from both roads, not always from the same route.
- The central intersection must create meaningful tactical decisions.
- Some waves must contain a large number of weak enemies.
- Some waves must contain a small number of durable enemies.
- Some waves must force the player to deal with multiple enemy types simultaneously.
- Boss waves must be climactic but fair.
- A wave must not become impossible because of bad luck; spawn timing, enemy composition, and path assignment must be deterministic or controllable.
- The player must receive enough credits between waves to make meaningful decisions, but not enough to trivialize later levels.

### Economy rules

- Enemies award credits when killed.
- Completing a wave awards a fixed completion bonus.
- Calling the next wave early may award an optional interest or early-call bonus.
- Selling a tower refunds part of its invested cost.
- Tower upgrades cost more than the original tower.
- Later levels start with limited credits and require careful spending.
- The economy must be visible at all times.
- The player must never receive duplicate rewards for the same enemy, wave, or level completion.

## 9. Abilities

Implement at least three player abilities. Abilities must be limited, readable, and strategically important, especially in levels 11–15.

Suggested abilities

 Ability  Effect  Cooldown 
---------
 Orbital Strike  Player selects an area; after a short delay, it deals heavy explosive damage  Long cooldown 
 EMP Pulse  Stuns or slows all enemies in a selected area; disables shields briefly  Medium cooldown 
 Reinforcement Drones  Temporarily deploys autonomous drones that attack enemies near a selected road section  Medium cooldown 
 Emergency Repair  Restores a portion of base health; limited uses per level  Very limited 
 Supply Drop  Grants a burst of credits; limited uses per level  Very limited 

Requirements

- Abilities must have clear icons, cooldown timers, credit costs if applicable, targeting indicators, and visual feedback.
- Abilities must not be required to complete early levels.
- Abilities must become important tools in later levels.
- Ability effects must be visible and understandable.
- Ability cooldowns must persist correctly through pause, restart, and level transitions.
- Abilities must never create infinite loops, duplicate rewards, or unbounded effects.

## 10. Interface and reference image

Use the supplied reference image, `Sniprarapmok.jpg`, as a layout and readability reference only. Do not copy its exact artwork, icons, colors, fonts, logos, or proprietary visual style.

The interface should feel like a compact military command console for a Martian outpost

- Dark industrial panels.
- Warm amber highlights.
- Red warning accents.
- Off-white technical text.
- Clear rectangular tower cards.
- Compact health and resource displays.
- Readable icons and short labels.
- Strong contrast between gameplay field and interface.

### Required HUD

The HUD must include

- Current credits.
- Base health or integrity.
- Current level number and name.
- Current wave number and total waves.
- Next wave preview.
- Start Wave  Call Early button.
- Pause button.
- Speed control 1x, 2x, and optionally 3x.
- Tower shop with at least 10 tower cards.
- Selected tower panel with stats, upgrade button, sell button, targeting mode, and range display.
- Ability bar with cooldown indicators.
- Wave banner when a wave begins or ends.
- Damage numbers or hit feedback.
- Clear victory and defeat screens.

### Tower shop

The tower shop must show

- Tower icon or readable silhouette.
- Tower name.
- Cost.
- Short role description.
- Lockedunlocked state.
- Disabled state when the player cannot afford it.
- Keyboard shortcuts where practical.
- Drag-and-drop placement or click-to-place placement; both are acceptable if implementation is reliable.

### Tower inspection

When a tower is selected, show

- Tower name and level.
- Current damage, attack rate, range, splash, slow, armor penetration, or other relevant stats.
- Next upgrade cost.
- Next upgrade preview.
- Sell value.
- Targeting priority.
- Upgrade button.
- Sell button.
- Clear disabled-state explanations.

### Menus

Implement

- Main menu.
- Level select.
- Pause menu.
- Victory screen.
- Defeat screen.
- Settings for volume, screen shake, and optional colorblind-friendly feedback.
- Help or controls screen.
- Level-complete summary.

The main menu must allow the player to start or continue a campaign, select unlocked levels, view controls, adjust audio, and quit or return to the desktop where appropriate.

## 11. Controls

### Mouse and keyboard

 Input  Action 
------
 Left click  Select tower, place tower, confirm ability target 
 Right click  Cancel placement, cancel targeting, deselect 
 Mouse move  Preview placement, inspect cells and towers 
 `1`–`0`  Select tower types from the shop 
 `Q`, `W`, `E`, `R`  Activate abilities 
 `Space`  Start next wave or call early 
 `Esc`  Pause, close menu, or cancel action 
 `Tab`  Cycle tower selection 
 `Delete` or `X`  Sell selected tower 
 `U`  Upgrade selected tower 
 `1x  2x  3x`  Change game speed 
 `M`  Mute or unmute audio 

### Touch support

Provide touch equivalents for

- Selecting towers.
- Placing towers.
- Upgrading and selling.
- Starting waves.
- Using abilities.
- Pausing.
- Changing game speed.

Touch targets must be large enough to use reliably. Critical buttons must not be hidden behind tooltips or placed where fingers obscure the battlefield.

## 12. Visual direction

### Mars environment

The game should look like a hostile but readable Martian frontier

 Element  Direction 
------
 Ground  Rust-red regolith, dusty orange-brown terrain, scattered rocks 
 Roads  Dark compacted soil, tracked metal, cracked concrete, or reinforced landing strips 
 Human base  Modular habitat domes, metal landing pads, solar panels, antennas, cargo containers 
 Towers  Military-industrial metal, dark gray hulls, amber lights, red warning strips 
 Enemies  Biological arachnid forms dark chitin, red-orange markings, pale joints, glowing eyes 
 UI  Dark graphite panels, amber text, red alerts, off-white labels 
 Effects  Dust, sparks, fire, electric arcs, frost vapor, missile trails, orbital beams 

### Tower visuals

Towers must be readable from above

- Pulse Turret compact rotating turret with twin barrels.
- Siege Cannon heavy armored turret with a large barrel.
- Flame Vent low wide nozzle with fuel tanks and heat glow.
- Arc Coil tall coil with electric arcs and capacitor nodes.
- Missile Battery box launcher with visible missile cells.
- Cryo Emitter cylindrical cooling unit with frost vents.
- Rail Sniper long elevated rail barrel with stabilizers.
- Command Relay antenna array with holographic field ring.
- Mine Layer low deployable dispenser with hatch and indicator lights.
- Orbital Lance large dish or targeting array with charging beam.

### Enemy visuals

Enemies must read as alien arachnids, not generic insects

- Multiple articulated legs.
- Low, wide bodies.
- Visible mandibles or mouthparts.
- Distinct silhouettes for each type.
- Bioluminescent markings for special enemies.
- Clear visual difference between ground, flying, burrowed, shielded, and healer enemies.
- Boss enemies must be visibly larger and more threatening.

Use low-poly or stylized 2D2.5D assets that remain readable at gameplay distance. Avoid visual clutter, excessive particles, or effects that hide enemy health and tower range.

## 13. Audio

Use original, locally stored or procedurally generated audio. No background music is required, but atmospheric ambience and sound effects are strongly recommended.

Required sound categories

- UI click, hover, confirm, error, and cancel.
- Tower placement.
- Tower upgrade.
- Tower sell.
- Tower attack sounds by type kinetic shot, cannon blast, flame burst, electric arc, missile launch, frost pulse, rail shot, support pulse, mine deployment, orbital charge.
- Enemy spawn, movement, hit, death, shield break, burrow, emerge, and boss roar.
- Base damage warning.
- Wave start and wave complete.
- Victory and defeat stingers.
- Ability activation and impact.

Audio rules

- Initialize audio safely.
- Prevent overlapping unbounded sound playback.
- Respect mute and volume settings.
- Pause or silence audio when appropriate.
- Do not allow delayed frames to create a backlog of sounds.
- Keep audio non-blocking and lightweight.

## 14. Persistence and progression

Implement local save data for

- Unlocked levels.
- Completed levels.
- Best stars or rating per level.
- Total credits earned.
- Total enemies defeated.
- Settings.
- Audio preferences.
- Campaign progress.

Save data must be versioned and validated. If save data is missing, corrupt, inaccessible, or outdated, the game must recover safely without crashing or blocking play.

A level is complete only after all waves are survived and the base remains intact. Partial progress within a level does not need to persist unless explicitly designed.

## 15. Performance and lifecycle

The game must remain stable during long sessions and repeated restarts.

Required lifecycle guarantees

- Restarting a level removes all enemies, projectiles, effects, mines, temporary buffs, floating numbers, and audio players.
- Returning to the main menu clears level-specific state.
- Pause freezes gameplay simulation, wave timers, enemy movement, projectile travel, status timers, and ability cooldowns.
- Resuming restores the exact gameplay state.
- Window focus loss must not cause runaway simulation or missed input.
- Effects and projectiles must be removed after their lifetime.
- Dead enemies must be removed from targeting, pathing, and wave-completion checks.
- No memory leak should occur after repeated level restarts.
- The game must run smoothly with a reasonable number of enemies, towers, projectiles, and effects.
- Use shared materials, textures, scenes, and audio streams where practical.
- Use object pooling for high-frequency objects where it improves stability.

## 16. Level design requirements

Create 15 distinct levels. Do not create 15 copies of the same map with only different enemy counts.

Each level must vary in at least some of the following

- Road layout.
- Intersection position.
- Number of spawn gates.
- Buildable-cell distribution.
- Chokepoints.
- Enemy composition.
- Boss type.
- Starting credits.
- Base health.
- Available towers.
- Environmental theme.
- Wave count.
- Difficulty rating.

Suggested campaign structure

 Level  Theme  New mechanic 
---------
 1  Landing Zone  Basic towers, single road pressure 
 2  Supply Route  Two roads, first upgrade decision 
 3  Canyon Junction  Central intersection, grouped enemies 
 4  Relay Station  Flame towers, slow effects, early swarm 
 5  Ore Field  First mini-boss, selling and rebuilding 
 6  Broken Pipeline  Armored enemies, corrosion, splash towers 
 7  Dust Basin  Flyers and anti-air requirements 
 8  Excavation Site  Burrowers and ambush pressure 
 9  Solar Array  Healers and shieldbearers 
 10  Command Ridge  Mixed waves, route pressure, mini-boss 
 11  Red Divide  Tight economy, difficult tower choices 
 12  Stormline  Fast enemies, slows, and chokepoint defense 
 13  Deep Crater  Heavy armor, burrowers, flyers, and healers 
 14  Black Ridge  Elite waves, limited buildable space, boss pressure 
 15  First Bastion  Final multi-phase boss, full tower roster, very difficult completion 

The first five levels must be approachable. Levels 6–10 must require growing mastery. Levels 11–15 must demand planning, efficient credit use, and tower synergy.

## 17. Mandatory feature-gap audit

After the game is playable, perform a mandatory audit before declaring it complete. Do not stop at a list of missing features; implement the selected fixes and verify them.

Create `FEATURE_AUDIT.md` with this structure

 Feature or defect  Current state and evidence  Player benefit  Priority  Decision  Acceptance check  Final status 
---------------------

Classify findings as

- `Working`
- `Partial`
- `Missing`
- `Broken`

Use priorities

- P0 broken progression, invalid placement, enemies bypassing roads, duplicate rewards, crashes, softlocks, or other completion blockers.
- P1 missing required mechanics, major UI gaps, unreadable combat, absent victorydefeat flow, balance problems, or AI defects.
- P2 focused polish that improves clarity, readability, or replay value without destabilizing the game.
- Future larger content ideas outside the current release.

## 18. Verification requirements

Before final delivery, verify the actual game, not merely the design document.

Test at minimum

- Tower placement on valid cells.
- Tower rejection on road cells, occupied cells, blocked cells, and cells with insufficient credits.
- Tower upgrades, sell refunds, range updates, and targeting changes.
- Enemy spawning on both roads.
- Enemy movement through intersections.
- Enemy leak damage and base health reduction.
- Enemy death rewards awarded exactly once.
- Flying enemies requiring appropriate towers.
- Burrowed enemies emerging predictably.
- Healers healing nearby allies.
- Shieldbearers absorbing damage before health.
- Status effects burn, slow, freeze, stun, corrosion, and shield break.
- Projectile collision, lifetime, splash radius, and cleanup.
- Wave completion detection.
- Early wave bonus, if implemented.
- Credits, upgrades, and sell refunds.
- Level victory and defeat.
- Restart behavior.
- Pause and resume.
- Save and load behavior.
- Audio mute and volume.
- UI readability at common resolutions.
- Performance during dense late-game waves.
- All 15 levels are completable without debug cheats or unintended exploits.

Record actual results. Do not claim a playthrough, performance measurement, or completed test that was not performed. If a tool or environment is unavailable, state the exact limitation and complete the available checks.

## 19. GitHub-ready delivery

The project must be ready to upload to GitHub.

Provide

1. A complete Godot 4 project.
2. `project.godot` with correct main scene and autoload configuration.
3. A `README.md` with
   - Game title.
   - Short description.
   - Required Godot version.
   - How to open the project.
   - How to run the game.
   - Controls.
   - Project structure.
   - How to add a new tower.
   - How to add a new enemy.
   - How to create or edit a level.
   - How to edit wave data.
   - Known limitations.
4. `.gitignore` excluding Godot cache, imported assets, temporary files, and editor-generated files that should not be committed.
5. `FEATURE_AUDIT.md`.
6. `PROGRESS.md` with checked-off implementation blocks.
7. Modular scenes and scripts, with no oversized monolithic files.
8. Editable resources for towers, enemies, levels, and waves.
9. A clear main entry scene.
10. No external runtime dependencies, CDN links, paid assets, or required online services.

The project must open cleanly in Godot, run from its documented entry point, and remain editable in the Godot editor.

## 20. Final delivery

Deliver a complete, playable, balanced, and polished tower defense game. The final version must include

- A playable main menu and level select.
- Fifteen completable levels.
- Two crossing roads from left to right.
- A visible square buildable grid.
- Strict road-placement restrictions.
- Ten fully implemented tower types.
- At least ten enemy types, including special enemies and bosses.
- Tower upgrades, selling, targeting, and range feedback.
- A meaningful credit economy.
- Fifteen-level difficulty progression.
- Abilities with cooldowns and clear effects.
- A readable military-science-fiction interface inspired by the supplied reference image.
- Original assets, audio, enemies, towers, and level design.
- Modular Godot scenes that can be individually moved, edited, duplicated, and tuned in the editor.
- Data-driven tower, enemy, wave, and level configuration.
- GitHub-ready project structure and documentation.
- A completed feature audit and verification results.

The final experience must feel like a complete, strategic, readable, challenging tower defense game easy to understand in the first levels, demanding careful planning by the final levels, and satisfying to master across the full campaign.