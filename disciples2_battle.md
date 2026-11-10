# Ashen Crown — Disciples II-Style Tactical Battle

You are a game designer, gameplay programmer, UI artist, and QA engineer. Build a complete, playable browser prototype whose **entire game is one combat system**, designed the way combat works in **Disciples II: turn-based, initiative-driven, formation-based party battles** presented from a high-angle 2.5D battlefield with an ornate dark-fantasy interface.

The deliverable is a working game, not a mockup, a design document, or a list of suggestions. Think critically about what the prototype lacks, implement the missing pieces, and verify the result before declaring it complete.

**All player-facing text, controls, notifications, menus, help, result screens, documentation, and audit notes must be in English.** Original names, original art, and original audio only. The reference screenshots define layout and feature intent, not assets to copy.

## 1. Outcome and priorities

Create an original dark-fantasy tactical battle game in the browser. The player commands a party of four heroes against waves of enemies in three linked encounters, using an initiative queue, two combat rows, basic attacks, class abilities, statuses, damage types, and a boss. Every battle must be readable, deterministic, and finishable.

The experience should offer:

- A battle that starts quickly from a title screen and teaches its controls through play.
- An initiative order that is visible at all times and resolves predictably once per round.
- A two-row formation where the front rank protects the back rank from melee.
- Meaningful choices between basic attacks, abilities, defending, waiting, and changing rows.
- Distinct heroes and enemies with recognizable silhouettes, portraits, and combat roles.
- Damage types, resistances, armor, critical hits, statuses, and readable floating numbers.
- Enemy AI that uses the same rules as the player, including abilities, healing, and target choice.
- The screenshot-derived interface: right-side unit tower with health bars, bottom-corner active/target portraits, and a central action medallion.
- Three encounters with different battlefields, enemy compositions, and a final boss.
- Procedural graphics and sound effects with no external image or audio assets.
- A mandatory feature-gap audit followed by implementation and a second verification pass.

Prioritize correctness and readable turn flow first, tactical depth and AI second, interface fidelity and visual polish third, and extra content fourth. A beautiful battlefield whose turn order can desynchronize does not satisfy the task.

## 2. Inspect the project before changing it

If a game already exists:

1. Read the project instructions and locate the actual entry point, battle simulation, renderer, UI, audio, data, and tests.
2. Inspect the current implementation and play it in a browser when tools permit.
3. Identify which features work, which are partial, which are missing, and which are broken.
4. Preserve working features, approved art direction, and the latest user-requested behavior.
5. Extend the active game in place. Keep one primary entry point and do not create a competing copy of the game.
6. Keep unrelated files and existing user work intact.

If starting from scratch, record the same baseline inventory with every feature marked as missing, then implement the complete required feature set below.

Adapt numerical values when measured playability requires it. Explain intentional departures from the reference game in the feature audit.

## 3. Technical delivery

- Use `index.html` as the primary entry point.
- Use vanilla JavaScript with ES modules and Three.js for the battlefield, unless an existing project already has a suitable rendering architecture.
- Keep the project runnable without a build step, account, backend, or external service.
- Vendor the rendering library locally and pin its version. The finished game must not depend on a CDN connection.
- Generate models, textures, portraits, and audio procedurally.
- Organize code into small, clearly named modules. A single monolithic script is not acceptable for this scope.
- Separate the authoritative battle simulation from rendering and UI. Mesh animation, camera movement, floating text, and effect timing must never decide damage, targeting, turn order, or death.
- Store unit templates, abilities, encounters, formations, and rewards as explicit data shared by simulation, renderer, and UI.
- Use a deterministic seeded random generator for combat rolls so tests can reproduce a battle exactly.
- Handle unavailable WebGL, audio, or browser storage gracefully. Storage and sound failures must not block play.
- Expose a small inspection API for automated battle checks, for example `window.__combat.snapshot()`.
- Keep debugging controls and internal identifiers out of the player interface.

### Modular architecture

Organize the prototype into these modules (names may differ, responsibilities may not):

1. `Core` — application state machine, round orchestration, presentation queue, lifecycle.
2. `Renderer` — Three.js renderer, camera, lighting, battlefield assembly, screen projection.
3. `Input` — mouse, keyboard, and touch routing; target picking; cancellation.
4. `Entities` — unit instances, stats, statuses, slots, and visual bindings.
5. `Combat` — turn order, targeting rules, damage formulas, abilities, statuses, victory checks.
6. `AI` — enemy decision-making using only public combat rules.
7. `Level` — encounter definitions, formation placement, battlefield theme, rewards.
8. `UI` — title, initiative tower, unit panels, action medallion, tooltips, overlays, log.
9. `Audio` — procedural sound effects and mute handling.
10. `Assets` — procedural models, materials, textures, portraits, and effects.
11. `Tests` — deterministic simulation checks independent of the browser.

### Development stages

Proceed in runnable increments, keeping the game playable after each one:

1. **Setup** — file structure, local Three.js, scene with battlefield ground and camera.
2. **Core loop** — state machine (`title`, `playing`, `paused`, `victory`, `defeat`, `campaign`), fixed-step presentation clock, round orchestration.
3. **Simulation** — units, formations, initiative order, actions, damage, death, victory checks, seeded RNG.
4. **Combat depth** — abilities, cooldowns, statuses, resistances, critical hits, healing, row changes.
5. **AI** — target scoring, ability conditions, healer logic, boss behavior, deterministic decisions.
6. **Battlefields** — three encounters with procedural terrain, ruins, props, and distinct palettes.
7. **Interface** — initiative tower, corner portraits, action medallion, targeting, floating numbers, log.
8. **Presentation** — unit models, idle/attack/cast/hit/death animation, spell effects, camera feedback.
9. **Audio and polish** — procedural effects, mute, help, victory summary, restart, performance pass.

## 4. Visual direction

### Overall composition

Build a high-angle 2.5D battlefield that reads like a dark-fantasy diorama: rough earth or marsh underfoot, ruined architecture behind the combatants, a low horizon, and a narrow band of sky. The camera is fixed for a battle and frames both formations. Use warm dusk light, deep shadows, and selective glowing magic.

The interface is deliberately ornate but legible: aged parchment labels, dark bronze frames, gem-like accent diamonds, and portrait medallions. It should feel handcrafted, not like a flat web dashboard.

Suggested palette:

| Element | Direction |
| --- | --- |
| Sky / horizon | Muted amber fading to cold slate |
| Earth | Dark umber `#3A2F28`, dry clay `#6B5540` |
| Moss and marsh | Desaturated olive `#4A5233` |
| Stone ruins | Cold gray-brown `#5D5A52` |
| Bone accents | Parchment `#E3D7B8` |
| UI metal | Aged bronze `#6B5533`, near-black `#14110E` |
| UI text | Warm bone `#EDE2C4` |
| Damage | Blood red `#C43A32` |
| Healing | Pale gold-green `#A8D98A` |
| Spirit and frost | Spectral teal `#8FE7D4` |
| Fire | Ember orange `#FF8A2A` |
| Poison | Sickly green `#9BC24B` |
| Enemy accent | Oxblood `#8F2B2B` |

### Battlefield and scenery

Each encounter has its own readable battlefield:

- A broad playable ground area covering both formations, with a clear center lane.
- Ruined walls, broken columns, arches, dead trees, gravestones, or marsh reeds placed behind and beside the combat lane.
- Distant silhouettes that establish place without competing with units.
- Ground texture generated procedurally: cracked earth, wet mud, flagstones, or ash.
- Sparse particles: drifting embers, mist, or floating spores.
- No scenery inside the combat lane that hides a unit's feet or health bar.

Keep the camera framing consistent between encounters. The player's party occupies the left half, enemies the right half, front ranks closer to the center. Units never overlap the interface panels at common aspect ratios.

### Unit readability

Every unit must be identifiable at a glance from silhouette, palette, and weapon:

- Heroes: warden with sword and shield, ranger with bow, pyromancer with staff, priest with censer or holy symbol.
- Enemies: brigand, crossbowman, ghoul, bog lurker, cultist, skeleton warrior, bone adept, and the Hollow King boss.
- Use low-poly, faceted geometry with cloth, leather, bone, and metal materials. Keep faces stylized and original.
- Eyes and magic use emissive materials so they read against dark ground.
- The boss is visibly larger and has a unique crowned silhouette.
- Dead units leave a short dissipating effect and are removed from the field; they never remain clickable.

### Screenshot-derived interface contract

The reference images (`1.jpg`, `2.jpg`, `3.jpg`) define the following layout, which the prototype must reproduce in spirit:

| Reference element | Required interpretation |
| --- | --- |
| Right-side vertical stack of portrait cards with green/red health bars and numbers | The initiative tower: every combatant in the current round, ordered top to bottom, with portrait, name, HP bar, HP value, and a marker for the active unit. Dead units are dimmed. |
| Two large portraits in the bottom corners with names, levels, hit points, and attack type | Active-unit panel on the left, current-target panel on the right. Show level, HP, attack type, and active statuses. |
| Central circular medallion with four small sigils and a large gem | The action medallion: Attack, Ability, Defend, Wait, and Change Row around a central confirm gem. |
| Floating red damage number over a struck unit | Floating combat text for damage, healing, critical hits, statuses, and immunities. |
| Bright white beam, green ground flames, ghostly silhouettes | Bounded spell effects: holy beam, poison/fire ground burst, spirit rise. Effects never hide formations for long. |
| Dark ornate frames, parchment plates, bronze ornament | CSS frames, corner ornaments, parchment labels, and gem accents. Do not copy specific artwork. |
| High-angle battlefield with a low horizon and ruins | Three.js battlefield camera and procedural ruin silhouettes. |

## 5. Controls and interaction

### Stable controls

| Input | Action |
| --- | --- |
| Mouse move | Inspect units; show name, HP, statuses, and intent tooltip |
| Left click on a unit | Inspect it; when targeting, confirm it if valid |
| Left click on an action | Open or execute that action |
| `1` | Attack |
| `2` | Open the ability list |
| `Q` / `E` | Cycle abilities while the list is open |
| `3` | Defend |
| `4` | Wait (delay to the end of the round) |
| `5` | Change row |
| `Tab` / `Shift+Tab` | Cycle valid targets |
| `Enter` / `Space` | Confirm the highlighted target or action |
| `Esc` | Cancel targeting, close a menu, or open pause |
| `H` | Toggle help |
| `M` | Toggle sound |
| `F` | Toggle fast presentation |
| `R` | Restart the current battle after confirmation |

Provide touch equivalents for every action. Target selection must work by tapping a unit. Keep the action medallion reachable with one thumb and never place critical buttons under the turn tower.

### Interaction rules

- Actions are enabled only during a living player unit's turn.
- Selecting Attack or an ability enters targeting mode; valid targets are outlined and invalid ones are dimmed.
- Melee actions cannot select protected back-rank units while any front-rank enemy lives. The tooltip explains why a target is invalid.
- Healing and buffs target allies and never allow targeting a dead unit.
- `Esc` cancels targeting without consuming the turn.
- Clicking the active unit or a disabled action produces a short, non-blocking explanation instead of silence.
- After an action resolves, the turn advances automatically. There is no separate "end turn" step after attacking.
- During enemy turns, actions are disabled and the interface shows whose turn it is.
- Hover and keyboard focus must expose the same information; action buttons have accessible labels.
- Pausing freezes presentation timers and blocks new input. Resuming returns to the same point in the turn.

## 6. Turn, initiative, and action contracts

### Round structure

Combat is turn-based and organized into rounds.

1. At the start of a round, every living unit is sorted by `initiative` descending.
2. Ties are broken deterministically: side (allies first), then slot order, then unit id.
3. Each living unit acts exactly once per round, in that order.
4. A unit's turn begins with status resolution (damage over time, stun check, guard expiry).
5. The unit performs one action, then its cooldowns and durations tick down at the end of its turn.
6. When the order is exhausted, a new round begins and the queue is rebuilt.
7. Dead units are removed from the queue immediately.

Waiting moves the unit to the end of the current round order once. It cannot be used twice in the same round. A unit that waits still acts later in that round unless it is the last combatant.

### Actions

| Action | Behavior | Ends turn |
| --- | --- | --- |
| Attack | Basic weapon attack using the unit's damage range and type. Melee respects rank protection; ranged and magic can hit any target. | Yes |
| Ability | A class-specific action with cooldown, targeting rules, and optional area effect. | Yes |
| Defend | Gain guard: incoming damage reduced by 50% until the unit's next turn. | Yes |
| Wait | Move to the end of this round's order. | Yes, then acts again later |
| Change Row | Swap between front and back rank within the same column if the destination slot is free. | Yes |

### Targeting contracts

- **Front protection:** melee attacks and melee abilities may target the enemy front rank only while at least one front-rank unit is alive. When the front rank is empty, the back rank becomes reachable.
- **Ranged and magic:** basic ranged attacks and spells may target any living enemy, but the UI must still show cover status.
- **Reach:** a unit may have a `reach` trait that lets it ignore front protection. Use it sparingly and label it.
- **Allies:** heals, shields, and buffs target living allies only. Self-targeting is allowed when the ability permits it.
- **Areas:** an area ability declares its shape (`front`, `all`, `single`). Damage is rolled separately for each victim. Area damage cannot critically hit more than once per action.
- **Dead targets:** invalid. Any queued target that dies before resolution is replaced by the next valid target or the action is cancelled without cost.
- **No friendly fire:** area abilities only affect the opposing side unless explicitly designed otherwise.

### Determinism and ordering

- Use a fixed simulation step for time-based presentation, but resolve combat actions atomically.
- Consume random numbers only inside damage, critical-hit, and AI tie-breaking functions.
- A given encounter, seed, and sequence of player choices must always produce the same result.
- Validate every action against the current actor, phase, cooldown, target validity, and victory state. Reject invalid actions without mutating state.
- Resolve an action in this order: validation → cost/cooldown → animation event emission → damage/healing → status application → death → victory check → turn end.
- Never let a visual death, projectile arrival, or floating number determine whether a unit can act.

### Required guarantees

- The initiative tower always matches the simulation's actual queue, including after Wait, death, and round rollover.
- A dead unit never receives a turn, a heal, or a buff.
- A skipped stunned turn is visibly communicated and still ticks durations.
- Cooldowns are per unit, never shared between allies.
- Damage cannot be negative; healing cannot exceed maximum HP.
- Victory triggers exactly once, after the last enemy death animation is queued.
- Defeat triggers exactly once, after the last ally death.
- Restarting a battle rebuilds units from templates and clears every transient status, cooldown, queued effect, and log entry.

## 7. Author a teachable first battle

Design the campaign as three linked encounters. The first must teach without a wall of text; later encounters combine familiar rules.

| Encounter | Battlefield | Enemy composition | Teaching purpose |
| --- | --- | --- | --- |
| I — Ruined Watchtower | Cracked earth, broken tower, dusk | Two brigands, one crossbowman, one ghoul | Attack, targeting, front protection, healing, status damage |
| II — Sunken Marsh | Mud, reeds, drowned statues, mist | Two bog lurkers, one cultist, one marsh archer | Area abilities, cleanse/heal pressure, ranged threats |
| III — Bone Cathedral | Flagstones, bone arches, cold light | Hollow King boss, two skeleton warriors, one bone adept | Boss abilities, focus fire, healer denial, final victory |

### Encounter I layout

Use a 2×3 formation per side.

- Ally front: Ji'An (Warden), Dain (Shieldbearer).
- Ally back: Tsok-Tsok (Ranger), Ilman (Pyromancer), Amuntia (Priest).
- Enemy front: Brigand, Ghoul.
- Enemy back: Brigand, Crossbowman.

If the party size is four, keep the warden and one melee ally in front, and the ranger and priest in the back. The player's first turn should offer a safe, obvious attack. The first enemy turn should demonstrate that the crossbowman can reach the back rank while the brigands cannot.

The player must be able to win without using abilities, but using them must be clearly better. Do not require a specific secret or lucky critical hit.

### Encounter pacing

- Open with a brief battle title card that names the encounter and states the objective in one line.
- Show one contextual hint during the first player turn, then retire it.
- Introduce the first healer pressure in Encounter II and the boss ability in Encounter III.
- Keep enemy counts between four and five so the initiative tower fits without scrolling at common heights.
- Between battles, show a compact victory summary and heal the party partially. Preserve levels and rewards.
- The whole campaign should take roughly 10–15 minutes for a new player.

## 8. Units, formations, stats, and abilities

### Formations

- Each side has six slots: front-left, front-center, front-right, back-left, back-center, back-right.
- Melee units benefit from standing in front; fragile casters benefit from the back.
- A unit can change rows only into an empty slot in the same column. If that slot is occupied, the action is disabled with an explanation.
- Shifting rows is visible as a short walk animation and updates the rank used by targeting immediately.
- Empty slots are allowed; formations do not need to be full.
- Unit placement is data, not inferred from render positions.

### Stats

Each unit has these explicit stats:

| Stat | Meaning |
| --- | --- |
| `maxHp` | Maximum hit points |
| `damage` | Minimum and maximum base damage |
| `damageType` | `physical`, `fire`, `cold`, `holy`, `poison` |
| `initiative` | Turn order weight, higher acts earlier |
| `armor` | Flat reduction against physical damage; partial reduction against magic |
| `resist` | Percentage resistance per damage type |
| `critChance` | Chance for a 1.6× critical hit |
| `range` | `melee`, `ranged`, or `magic` |
| `abilities` | One or two class abilities |
| `level` | Displayed level and scaling source |
| `xp` | Experience toward the next level |

### Hero roster

| Hero | Role | Range | Signature abilities |
| --- | --- | --- | --- |
| Ji'An, the Warden | Durable leader, front line | Melee | War Cry: party damage buff; Shield Bash: damage and stun |
| Tsok-Tsok, the Ranger | Single-target and area physical damage | Ranged | Piercing Shot: armor-piercing hit; Rain of Arrows: area damage |
| Ilman, the Pyromancer | Fire damage and burn | Magic | Firebolt: heavy single hit; Flame Wave: front-rank area and burn |
| Amuntia, the Priest | Healing, holy damage, support | Magic | Mend: strong heal; Smite: holy damage, extra against undead |

### Enemy roster

| Enemy | Role | Behavior |
| --- | --- | --- |
| Brigand | Melee bruiser | Attacks the lowest-HP reachable hero; guards when nearly dead |
| Crossbowman | Ranged chip damage | Focuses back-rank casters when possible |
| Ghoul | Melee poison | Applies poison with its attack; relentless |
| Bog Lurker | Melee poison tank | Uses a poison burst when two heroes are adjacent in rank |
| Cultist | Magic support | Heals or weakens; retreats in rank when threatened |
| Marsh Archer | Ranged poison | Targets the healer first |
| Skeleton Warrior | Melee undead | Resists cold and poison; straightforward attacker |
| Bone Adept | Undead healer | Heals the boss; tries to stay in the back rank |
| The Hollow King | Boss | Soul Rend area damage and self-heal; Terror stun; enrages below half HP |

### Ability rules

- Every ability declares cooldown in rounds, target side, target shape, damage or healing range, status, and a short player-facing description.
- Cooldowns begin after the ability is used and tick at the end of the user's turns.
- An ability on cooldown is disabled in the UI with the remaining rounds visible.
- Healing cannot revive. Revive is out of scope for this release.
- Buffs and debuffs stack only when explicitly allowed; otherwise refresh duration.
- Statuses have a source unit, a remaining duration, and a visible icon.

## 9. Damage, resistances, statuses, and death

### Damage formula

Use a transparent formula and expose the result in the log:

1. Roll base damage uniformly between the ability's minimum and maximum.
2. Apply the attacker's damage modifiers (War Cry, weaken).
3. Apply critical hit multiplier when the roll succeeds.
4. Subtract mitigation: full armor for physical, 35% of armor for magic and ranged elemental damage.
5. Apply the target's percentage resistance for the damage type.
6. Apply guard (50% reduction).
7. Clamp to a minimum of 1.
8. Apply absorption shields before HP loss, and report absorbed damage separately.

Damage types: `physical`, `fire`, `cold`, `holy`, `poison`.

- Undead take +50% holy damage and 50% less poison damage.
- Marsh creatures resist poison.
- Constructs, if added later, resist poison heavily and take extra physical damage.
- Resistance is capped between -50% and 75%.

### Status effects

| Status | Effect | Duration | Notes |
| --- | --- | --- | --- |
| Poison | Damage at turn start, ignores armor | 3 turns | Stacks refresh; does not stack damage |
| Burn | Damage at turn start | 2 turns | Fire-themed; reduced by resist |
| Stun | Skip the next action | 1 turn | Cleared after the skipped turn |
| Weaken | −25% outgoing damage | 2 turns | Refreshes, does not stack |
| Guard | −50% incoming damage | Until next own turn | Applied by Defend |
| War Cry | +30% outgoing damage | 2 turns | Party-wide buff |
| Shield | Absorbs a fixed amount | Until depleted or 3 turns | Absorbed damage is shown separately |
| Enrage | +25% damage, −10% armor | Until battle end | Boss only, below 50% HP |

Damage over time triggers at the start of the affected unit's turn, before it acts. If it kills the unit, the turn is skipped and the queue advances. Status icons and remaining durations must be visible in the unit panels and tooltips.

### Death and battle end

- A unit at 0 HP dies immediately in the simulation and is removed from the queue.
- Play a short collapse or dissolve animation, then hide the mesh. Do not block input longer than the presentation window.
- Dead units cannot be targeted, healed, buffed, or inspected as valid targets.
- Victory is declared when every enemy is dead. Defeat is declared when every hero is dead.
- Both outcomes are checked after every damage, heal, and status tick.
- On victory, stop the queue, disable actions, show the summary, and award rewards once.
- On defeat, show a retry panel that restores the encounter from its initial data.

## 10. Enemy AI and encounter pacing

### Decision model

Enemy AI uses a small, inspectable state machine and only public combat information:

1. **Skip** if stunned or dead.
2. **Support:** if an ally is below 55% HP and a heal is available, heal the most wounded ally.
3. **Area:** if an area ability is available and hits at least two valid targets, use it.
4. **Buff/debuff:** use a party buff on round one, or a weaken/stun ability against a dangerous hero.
5. **Attack:** choose the best valid target by a weighted score.
6. **Defend:** if below 20% HP and no better action is available, guard.
7. **Wait:** rarely, to let a support unit act first; never as a stall loop.

Target scoring considers:

- Reachability under the front-rank rule.
- Low current HP (finish wounded units).
- Back-rank casters and healers (priority threats).
- The unit that threatened the AI last.
- Small deterministic tie-break noise from the seeded RNG.

The AI must not read hidden information, ignore cooldowns, or act twice. It may use the same abilities as the player and must show the same telegraphs.

### Boss behavior

The Hollow King has two phases:

- **Phase 1 (above 50% HP):** alternates melee pressure with Soul Rend when two or more heroes are valid, and Terror against the highest-damage hero.
- **Phase 2 (at or below 50% HP):** gains Enrage once, uses Soul Rend more often, and prioritizes the healer.

Boss abilities have clear names, cooldowns, and visible cast feedback. The boss must remain beatable by a party that uses healing and focus fire.

### Pacing rules

- Never spawn a new enemy mid-battle; all combatants are placed at the start.
- Enemy turns resolve with a readable delay, not instantly chained.
- Do not let three enemy turns pass without a visible log entry.
- If the player has no valid action (all abilities on cooldown, no target), Wait and Defend remain available.
- A battle must not deadlock because of an empty rank, a dead actor, or a skipped stun.

## 11. Rewards, progression, and persistence

### Rewards

Award once per completed battle:

| Reward | Value |
| --- | --- |
| Experience per enemy | Based on enemy tier |
| Gold per enemy | Based on enemy tier |
| Encounter clear bonus | Fixed per encounter |
| Boss clear bonus | Larger fixed reward |

Experience thresholds trigger level-ups between battles. A level-up increases maximum HP by 10%, base damage by 8%, and heals the unit to full. Show the gains in the victory summary.

### Between battles

- Show final party HP, experience gained, gold gained, level-ups, and a single primary button to continue.
- Heal each surviving hero by 40% of maximum HP; revive fallen heroes at 30% HP for the next encounter.
- Preserve levels, XP, gold, and campaign progress in memory.
- Save best campaign results, including total rounds and heroes lost, using versioned and validated local storage.
- Handle missing, corrupt, unavailable, or full storage without interrupting play.
- Provide a campaign-complete screen with total rounds, total damage dealt, and a replay action.

## 12. HUD, turn queue, and battle log

### Initiative tower

- Fixed to the right edge, styled as a vertical bronze frame with portrait cards.
- Each card shows portrait, name, level, HP bar, HP numbers, and status icons.
- The active unit's card is highlighted with a gem marker and a warmer frame.
- Cards are ordered by the current round queue; units that already acted are marked.
- Dead units are removed after their death presentation, not left clickable.
- If the queue exceeds the available height, scroll inside the tower rather than shrinking text below readability.

### Corner unit panels

- Bottom-left: the acting hero, or the last acting hero during enemy turns.
- Bottom-right: the current hovered or selected target.
- Each panel shows a large portrait, name, level, hit points, attack type, and status icons.
- Clicking a unit updates the right panel; it does not accidentally confirm an action unless targeting is active.

### Action medallion

- Bottom center, framed as a circular bronze medallion.
- Five actions: Attack, Ability, Defend, Wait, Change Row.
- The center gem confirms a highlighted target or opens the selected action.
- Ability selection opens a compact list with name, description, cooldown, and target type.
- Disabled actions remain visible with a reason on hover/focus.
- The medallion must not cover the front ranks.

### Floating text and log

- Damage floats above the struck unit in blood red; critical hits are larger and gold-edged.
- Healing floats in pale green; absorbed damage in slate blue; statuses in their associated color.
- Text rises, fades, and is removed within one second. Cap simultaneous floats.
- Keep a compact combat log at the left edge with the last four events.
- Log entries use short, factual sentences: `Tsok-Tsok hits Brigand for 34.` / `Brigand is poisoned.` / `Ji'An falls.`

### Menus and overlays

| State | Main text | Main action |
| --- | --- | --- |
| Title | `Ashen Crown` | `Begin Campaign` |
| Help | `How to Play` | `Close` |
| Pause | `Battle Paused` | `Resume` |
| Victory | `Victory` | `Continue` |
| Defeat | `Defeat` | `Retry Battle` |
| Campaign complete | `The Hollow King Falls` | `Play Again` |

Use the rendered battlefield as the backdrop. Keep overlays compact, scroll internally when necessary, and never hide the primary action on small screens.

## 13. Animation and effects

### Unit animation states

Implement at least these presentation states:

- Idle breathing and cloth sway.
- Turn-ready stance with a subtle ground ring.
- Melee attack: wind-up, lunge, weapon arc, recovery.
- Ranged attack: draw or aim, release, recoil.
- Cast: raise focus, glow, projectile or beam, recovery.
- Hit: short recoil and emissive flash; heavy hits shake the camera slightly.
- Guard: shield or arms raised, muted stance.
- Status affliction: tinted pulse for poison, burn, or stun.
- Death: collapse, fade, and a brief spirit rise.
- Row change: short walk between ranks.
- Victory: surviving heroes raise weapons; defeat: the party slumps.

Animations are cosmetic. They must not move authoritative positions, change damage timing, or decide when a turn ends. The presentation queue waits for the authored animation duration, not for mesh intersection tests.

### Spell effects

- Fire: additive ember burst, orange point light, short ground scorch.
- Holy: vertical white-gold beam and expanding ring.
- Poison: low green ground flame and drifting spores.
- Physical: small spark and dust at impact.
- Boss: dark violet shockwave with bone fragments.
- Effects are bounded in count and lifetime, and removed after playback.
- Never obscure the initiative tower or the action medallion.

## 14. Audio

Use the Web Audio API to synthesize concise original sound effects:

- UI click, action confirm, invalid action.
- Sword swing, arrow release, spell cast, holy chime, poison gurgle.
- Physical impact, critical hit, heal, shield absorb.
- Unit death, undead rise, boss roar.
- Round start, victory sting, defeat sting, campaign fanfare.

Rules:

- Initialize audio only after a user gesture.
- One audio owner; no overlapping loops or unbounded nodes.
- Mute affects every sound and persists in local storage when available.
- Pause and hidden-tab suspension silence pending effects.
- A delayed frame must not play a backlog of missed sounds.
- No background music is required; if ambient sound is added, it must be quiet, optional, and mute-aware.

## 15. Performance and lifecycle

- Reuse geometries, materials, portraits, and textures across units and battles.
- Cap device pixel ratio and use modest shadow settings.
- Remove finished effects, floating text, and dead meshes.
- Dispose of per-encounter resources without destroying shared assets.
- Restarting or advancing encounters must not accumulate listeners, timers, lights, meshes, or DOM nodes.
- Pause and page-hidden handling must stop presentation timers and clear stuck hover/targeting states.
- Keep the camera fixed during combat; small hit shake is the only camera motion.
- UI updates should be batched per event, not rebuilt every animation frame.
- Expose a deterministic snapshot for tests and keep production logging out of the interface.

## 16. Verify the baseline before enrichment

Test the real simulation and the actual browser build. Record evidence, not intentions.

| Area | Required evidence |
| --- | --- |
| Initiative | Order matches initiative, ties resolve deterministically, Wait moves once, round rollover rebuilds correctly |
| Formations | Melee cannot reach back rank while front lives; back rank becomes valid after front death; row change updates targeting |
| Actions | Attack, abilities, defend, wait, and row change consume exactly one turn and reject invalid use |
| Damage | Formula bounds, armor, resistance, critical hits, guard, shields, healing cap, minimum 1 |
| Statuses | Poison/burn tick timing, stun skip, weaken, guard expiry, refresh behavior, durations visible |
| Death | Dead units leave the queue, cannot be targeted or healed, and do not receive turns |
| AI | Uses only legal actions, respects cooldowns and rank protection, heals allies, focuses threats, never stalls |
| Encounters | All three battles are winnable with the provided party and without debug protection |
| Campaign | Victory rewards once, experience and levels apply, healing between battles, final screen |
| Interface | Tower matches queue, corner panels update, action medallion states, targeting, tooltips, log, responsive layout |
| Presentation | Attack, cast, hit, death, and spell effects play, terminate, and never block turn flow |
| Audio | Gesture gating, mute, pause, hidden tab, no backlog, no errors |
| Lifecycle | Repeated restarts, pause/resume, encounter advance, and cleanup of effects and listeners |
| Determinism | Identical seed and choices reproduce identical damage, deaths, and outcome |

Use Node-based simulation tests for the pure combat module and real browser interaction for UI, rendering, and audio. Do not claim a browser playthrough, sound playback, or performance measurement that was not performed. If a tool is unavailable, state the exact limitation and complete the remaining checks.

## 17. Mandatory pre-final feature-gap audit

This phase is required after the campaign is playable and before final delivery. Do not stop after writing the list. Implement the selected improvements, then verify them.

### A. Inspect the playable candidate

Play all three encounters and review the code. Ask concrete questions:

- Does the first battle teach Attack, targeting, rank protection, and healing through play?
- Is it always obvious whose turn it is and what will happen next?
- Are front and back ranks readable from the battlefield and the interface?
- Do abilities feel distinct, and are cooldowns and target rules understandable without guessing?
- Does the AI ever cheat, stall, repeat a useless action, or ignore its healer?
- Are damage numbers, statuses, and deaths visible at a glance?
- Does the initiative tower ever disagree with the actual turn?
- Do the corner panels and action medallion match the reference layout without hiding combat?
- Is the boss fight tense but fair, with a clear phase change?
- Are there dead buttons, placeholder text, silent actions, or incomplete animations?
- Does the layout survive narrow portrait and short landscape viewports?

### B. Produce a concrete feature list

Write a concise English audit in `FEATURE_AUDIT.md` using this table:

| Feature or defect | Current state and evidence | Player benefit | Priority | Decision | Acceptance check | Final status |
| --- | --- | --- | --- | --- | --- | --- |
| Example: back-rank protection | Melee currently hits any slot | Makes formation choices meaningful | High | Implement | Melee rejects back rank while a front unit lives and accepts it after the front dies | Pending |

Classify findings as `Working`, `Partial`, `Missing`, or `Broken`. Do not list working features as missing. Keep factual observations separate from design ideas.

Priorities:

- **P0:** broken turn flow, illegal targeting, duplicate rewards, deadlocks, or other completion blockers.
- **P1:** missing required mechanics, major UI gaps, unreadable combat, absent victory flow, or AI defects.
- **P2:** focused polish that improves clarity or replay value without destabilizing the campaign.
- **Future:** larger content or ideas outside this release.

### C. Select and implement

Fix every P0 item and complete missing required P1 behavior. Then choose a small, coherent set of P2 improvements justified by the audit. Examples: clearer status icons, better target previews, a damage preview in the tooltip, improved boss phase feedback, or a battle-speed control.

Do not add features merely to lengthen the list. Do not force extra classes, a fourth encounter, an inventory system, or a campaign map into a finished combat prototype. Within scope, proceed from the audit to implementation without asking whether to continue.

### D. Re-test and update the audit

For every implemented item:

1. Verify its own acceptance check.
2. Check interactions with turn order, death, healing, statuses, pause, restart, and campaign progression.
3. Run the relevant simulation regression tests.
4. Inspect the actual browser appearance and controls.
5. Update the final status with implementation location and evidence.

Run a complete regression pass after the last gameplay change, including all three encounters, the victory/defeat flow, mobile layout, audio lifecycle, and deterministic replay.

### E. Final gate

The version is ready only when:

- Every required feature works.
- Every selected addition is implemented and verified.
- No P0 issue or unresolved selected item remains.
- Deferred ideas have explicit reasons and are not presented as completed.
- English UI and documentation match actual controls and mechanics.
- All performed tests and material limitations are reported accurately.

## 18. Deliver the final version

Leave the primary game ready to launch from its documented entry point. Provide:

1. The finished game and all local runtime files.
2. A short English README with launch instructions, controls, architecture, and validation commands.
3. The completed feature audit with implemented, verified, and intentionally deferred items.
4. Deterministic simulation tests and concise verification results.
5. A `PROGRESS.md` context-recovery file with checked-off work blocks.

In the final response, identify the playable entry point, summarize the meaningful implemented features, state what was tested, and disclose any material verification limitation.

The final experience should feel like a complete, self-contained dark-fantasy battle: immediately understandable, tactically satisfying, visually readable, technically dependable, and polished through an actual inspect–implement–verify cycle.
