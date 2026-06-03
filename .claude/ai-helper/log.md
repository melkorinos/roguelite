# Development Log

## 2026-06-03 — Floating combat labels + shop section color separation

### Floating damage/effect numbers in battle
- `BattleSystem.tick_battle()`: fire events now include `damage`, `effect`, and `is_miss` fields
- `Battle.gd`: `_process_fire_events()` now calls `_spawn_float_labels(slot, event)` per event
- `_float_label()` spawns a Label above the firing slot, Tweens it 52px upward over 0.85s while fading; auto-freed after animation
- All 12 T1 effects have distinct colors: burn=orange, poison=lime, heal/leech=green, shock=electric-blue, blind=gray, curse=purple, weaken=teal, armor=silver, cleanse=yellow, haste=cyan; damage=red; miss=dim-gray
- Miss events no longer trigger `play_fire_animation()` (blinded elements don't visually fire)

### Shop section color separation
- `ThemeData.gd`: added `SHOP_FORSALE_*`, `SHOP_INVENTORY_*`, `SHOP_BATTLEGRID_*` constants (warm amber / cool blue / warm red respectively)
- `Shop.gd` `_apply_theme()`: per-section StyleBoxFlat applied to SellZone (PanelContainer), InventoryRow (HBoxContainer), BattleGrid (GridContainer) via Container "panel" stylebox override
- `SELL_BG/BORDER` updated to match warm-amber FOR SALE theme
- Forge panel remains deep purple; shop left panel no longer gets a single flat override

### Test result
238/238 passing.

## 2026-06-03 — Visual overhaul: elemental area colors + tier-colored item tiles

### Goal
Replace default gray Godot theme with distinct elemental color identities per area, and tier-colored item borders to support playtesting readability.

### New file
- `data/ThemeData.gd` — single-source color config. All scene backgrounds, panel tints, tier colors, label accents, slot styles live here. Tweak one file to change the entire visual identity.

### Files changed
- `scenes/screens/MainMenu.tscn` — deep indigo-black background `Color(0.05, 0.03, 0.11)`
- `scenes/screens/Shop.tscn` — dark navy merchant background `Color(0.06, 0.07, 0.12)`
- `scenes/screens/Battle.tscn` — dark crimson war background `Color(0.09, 0.04, 0.07)`
- `scenes/screens/Compendium.tscn` — dark teal library background `Color(0.04, 0.09, 0.12)`
- `scenes/screens/MainMenu.gd` — added `_ready()`: title label purple tint
- `scenes/screens/Shop.gd` — added `_apply_theme()`: forge panel purple background (via Container "panel" stylebox), shop section blue tint, all section headers colored; SOLD tile uses ThemeData
- `scenes/screens/Battle.gd` — added header/player/opponent label color overrides; summary headers use ThemeData
- `scenes/screens/Compendium.gd` — card borders + tier headers via ThemeData tier functions
- `scenes/slots/ShopItemTile.gd` — tier-based border + bg color in `setup()`; stored `_style` ref
- `scenes/slots/BattleSlot.gd` — panel StyleBoxFlat added; tier colors in `set_element()`/`_apply_empty()`; progress bar styled (dark bg + blue fill)
- `scenes/slots/ForgeSlot.gd` — ThemeData FORGE_SLOT colors (deep purple)
- `scenes/slots/SellZone.gd` — ThemeData SELL colors
- `scenes/slots/InventorySlot.gd` — Button style overrides (normal/hover/pressed/focus/disabled) with panel look

### Color scheme summary
| Area | Vibe | Key color |
|---|---|---|
| Main Menu | Cosmic void | deep indigo `#0D0809` |
| Shop | Merchant hall | dark navy |
| Battle | War chamber | dark crimson |
| Forge (panel) | Alchemy bench | deep purple |
| Compendium | Arcane library | dark teal |
| T1 items | Common | green border |
| T2 items | Uncommon | blue border |
| T3 items | Rare | gold border |

### Build result
Headless import + boot check: clean (exit 0).

## 2026-06-03 — T4 expansion: 10 new elements, 30 new recipes (132 elements, 169 recipes)

### Design decisions (grill-with-docs session)
- T4 scale: mythological, astronomical, geological epoch — beyond natural phenomena
- T4 recipe rule: T3+T3 only, 3 convergence paths per element
- T4 elements: Ice Age, Maelstrom, Tectonic, Supernova, Singularity, World Tree, Pandemic, Ragnarok, Primordial, Aether
- Price: 16g. Compendium label: "Tier 4 — Phenomena"

### Files changed
- `data/ElementData.gd` — 122 → 132 elements; 10 T4 entries
- `data/RecipeData.gd` — 139 → 169 recipes; 30 T4 recipes, comment updated
- `scenes/screens/Compendium.gd` — TIER_NAMES extended with tier 4 entry
- `test/unit/data/test_element_data.gd` — tier range test updated 1–3 → 1–4

### Test result
279/279 passing.

## 2026-06-03 — T3 expansion: 17 new elements, 46 new recipes, legacy recipe redesign (122 elements, 139 recipes)

### Design decisions (grill-with-docs session)
- T3 recipe rule settled: all T3 requires T2+T2 — no T1+T2 paths allowed
- All 11 existing T1+T2 T3 recipes redesigned to T2+T2 equivalents (e.g. rain+fire→rainbow became rain+solar→rainbow)
- Convergence mechanic: 2–3 distinct T2+T2 ingredient pairs per T3 element
- T3 scale = natural wonders and large-scale phenomena; T4 reserved for cosmic/mythological
- Thunderhead renamed → Tempest; Sanguine Tide renamed → Hemorrhage; Canker renamed → Underrot; Crimsonfield renamed → Carnage

### New T3 elements (17)
Frost: Glacier, Blizzard, Tundra
Nature: Rainforest, Ancient Grove
Storm: Hurricane, Tempest
Earth: Mountain, Tsunami
Light/Dark: Eclipse, Voidrift
Fungus: Plague, Underrot
Fire: Inferno
Blood: Hemorrhage, Carnage
Metal: Meteorite

### Files changed
- `data/ElementData.gd` — 105 → 122 elements; 17 new T3 entries with cluster comments
- `data/RecipeData.gd` — 93 → 139 recipes; 11 T1+T2 swapped to T2+T2, 46 new T3 recipes added, comment updated
- `.claude/ai-helper/memory.md` — element/recipe counts updated, T3 design rules documented

### Test result
279/279 passing (no new tests needed — test_all_recipes_produce_findable_elements validated all 46 new result IDs automatically).

## 2026-06-03 — Full T2 expansion: Blood, Frost, and all cross-combos (105 elements, 93 recipes)

### Design decisions
- Water+Water renamed Ice → **Sea** (ice evoked Frost; sea leaves ocean/T3 space)
- Air+Air renamed Gale → **Gust** (preserves Tornado/Storm at T3)
- Frost+Frost self-combo added as **Freeze** (intermediate between Frost T1 and Glacier/Tundra at T3)
- Metal+Earth renamed Ore → **Flint**
- Fungus cross-combos renamed: Sonar → Sporeflow, Resonance → Fireshroom, Howl → Haze, Tremor → Rootrot, Echo → Mycelium
- 15 Group-G combos use placeholder names (e.g. "Blood+Nature") pending next brainstorm
- T3 convergence design intent established: Frost+Water (Blackice) + Frost+Air (Razorwind) → Blizzard at T3

### Files changed
- `data/ElementData.gd` — 67 → 105 elements; 8 renames + 38 new T2 elements
- `data/RecipeData.gd` — 55 → 93 recipes; 8 result-ID renames + 38 new recipes
- `test/unit/systems/test_forge_system.gd` — updated 5 test assertions for renamed IDs (ice→sea, gale→gust)

### Test result
279/279 passing.

## 2026-06-03 — Status Effects system + T1 expansion to 12 elements

### Design session (grill-with-docs)
Resolved all open questions via grilling passes:
- Unified model: each element IS its damage type (no separate damage-type layer)
- All statuses apply to player-side total (not per-element)
- Poison permanent; all other timed effects use ticks_remaining; Burn ramps down; Weaken active only while ticks > 0
- Shock: hyperbolic CD slow `50n/(n+5)`, asymptotes at 50%
- CONTEXT.md updated with Effect + Status vocabulary

### T1 roster changes (10 → 12)
- Sound 🔊 retired → replaced by Fungus 🍄 (Poison)
- Added Blood 🩸 (Leech) + Frost 🌨️ (Weaken)
- All 12 T1 elements now carry `"effect"` field
- RecipeData: 5 sound-based recipes switched to fungus ingredient

### New files
- `systems/StatusSystem.gd` — `empty_statuses`, `apply_effect`, `tick`, `compute_incoming_damage`, `slow_pct`
- `test/unit/systems/test_status_system.gd` — 43 tests

### Modified files
- `data/ElementData.gd` — effect fields, Sound→Fungus, Blood+Frost
- `data/RecipeData.gd` — sound→fungus in 5 recipes
- `data/GameState.gd` — player_statuses, opponent_statuses, status_tick_timer
- `systems/PhaseSystem.gd` — resets statuses in to_battle()
- `systems/BattleSystem.gd` — full effect pipeline behind FeatureFlags.status_effects; shock CD scaling, blind miss roll, _apply_element_effect() helper
- `test/unit/data/test_element_data.gd` — T1 count 10→12

### Test result
279/279 passing (83 new tests added).

## 2026-06-03 — T2 cross-combo expansion (Lightning/Nature/Light/Dark/Metal/Sound × original 4)

### Design decisions (grill-with-docs)
- 24 new T2 cross-combos added: each of the 6 new T1s × {Water, Fire, Air, Earth}
- 15 new-to-new pairs (e.g. Lightning+Sound) explicitly deferred — see ADR 0001
- Full name list: Surge, Arc, Static, Lodestone, Bloom, Ember, Pollen, Root, Prism, Solar, Aurora, Crystal, Abyss, Blight, Miasma, Shade, Rust, Molten, Shrapnel, Ore, Sonar, Resonance, Howl, Tremor

### Files changed
- `data/ElementData.gd` — 24 new T2 elements added (all tier:2, price:8)
- `data/RecipeData.gd` — 24 new cross-combo recipes; header count updated to 55
- `test/unit/data/test_element_data.gd` — count assertion updated 41→65
- `.claude/ai-helper/memory.md` — element system section updated
- `.claude/ai-helper/elements-reference.html` — ELEMENTS + RECIPES arrays + recipe group slices updated
- `docs/adr/0001-t2-cross-combo-scope.md` — NEW: records 24-of-39 scope decision

### Test result
223/223 passing.

## 2026-06-03 — Housekeeping, brainstorm tooling, feature flags

### Internal docs review + consistency pass
- `memory.md` — merged duplicate element system sections (stale count 29→41 elements, 25→31 recipes); merged duplicate OpponentProvider + PlayerProfile sections; added pointer to ideas.md for full backlog
- `goals.md` + `handoff.md` — removed stale links to deleted architecture review HTML; updated handoff build plan with ✅/⬜ status
- `domain.md` — corrected wrong file paths (`docs/soul.md` → `.claude/ai-helper/soul.md`)
- `CONTEXT.md` — split Merge (future 3-copy mechanic) from Level Up (current 2-copy, live in code); added Element as current prototype term; clarified Rarity vs Tier 1/2/3

### New files
- `.claude/ai-helper/ideas.md` — consolidated future feature backlog from all scattered locations (memory.md deferred, goals.md deferred, soul.md optional, CONTEXT.md optional)
- `.claude/ai-helper/elements-reference.html` — interactive brainstorm board: element cards with DPS bars, forge recipe reference, design note cards with open questions
- `data/FeatureFlags.gd` — playtest toggle class; one `static var` per design experiment (all false by default)

### Test reorganisation
- Moved 9 test files from flat `test/unit/` into subfolders mirroring the source tree: `test/unit/data/`, `test/unit/systems/`, `test/unit/autoloads/`
- Updated `.gutconfig.json` `dirs` array to list all three subdirs
- Updated CLAUDE.md GUT run command; CI unchanged (uses `-gdir=test/` which recurses)

### Elements reference updates
- Added 2 battle-system note cards to elements-reference.html: **Ability Chain Combat** (indigo) + **Innate Ability & Replay** (violet)
- Added feature flag toggles to all 5 note cards — state persisted in localStorage, "Flags active" counter in header

## 2026-06-02 — Steam + async PvP infrastructure (OpponentProvider, AchievementSystem, PlayerProfile)

### Files created
- `data/GhostFixtures.gd` — 3 static Ghost snapshots (tier 1/2/3); used as test fixtures and OpponentProvider fallback
- `systems/OpponentProvider.gd` — `get_opponent(context)`: LocalDaySeededAdapter (Fisher-Yates shuffle seeded by `hash(day+round)`), fixture fallback on empty pool
- `systems/AchievementSystem.gd` — `check(state, profile, event) -> Dictionary`: 5 achievements (ACH_FIRST_WIN, ACH_FIRST_FORGE, ACH_CLUTCH, ACH_SURVIVOR, ACH_DAMAGE_20K), recipe merge, damage accumulation
- `autoloads/PlayerProfile.gd` — ConfigFile autoload (`user://profile.cfg`), 3 sections (stats/progress/discovery), `to_dict()`/`from_dict()` for AchievementSystem integration
- `test/unit/test_opponent_provider.gd` — 10 tests
- `test/unit/test_achievement_system.gd` — 23 tests
- `test/unit/test_player_profile.gd` — 20 tests (uses `preload().new()` to bypass singleton)

### Files modified
- `data/GameState.gd` — added `opponent_snapshot: {}` field; `create()` accepts optional `seed_recipes` param
- `systems/PhaseSystem.gd` — `to_battle(state, opponent_snapshot)`: stores snapshot, reads grid from it
- `test/unit/test_phase_system.gd` — updated all `to_battle` calls to pass `GhostFixtures.get_fixture(1)`; added 2 new tests for snapshot storage
- `test/unit/test_battle_system.gd` — updated all `to_battle` calls to pass fixture
- `scenes/screens/Shop.gd` — `_on_fight_pressed` calls OpponentProvider; `_execute_forge` fires forge_discovered achievement if new recipe found
- `scenes/screens/Battle.gd` — `_on_next_round_pressed` calls AchievementSystem.check() + saves profile; immediate save on new achievement, batch save at match end
- `autoloads/GameManager.gd` — `create()` seeded with `PlayerProfile.get_discovered_recipes()`
- `project.godot` — registered `PlayerProfile` autoload (before GameManager)

### Test result
196/196 passing (56 new tests added).

## 2026-06-02 — T1 expansion, tier weights, HP fix, ESC menu, tooltip polish

### Design decisions settled (grill-with-docs session — 6 questions)
- **T1 items expanded** to 10: original 4 + Lightning ⚡, Nature 🌿, Light ☀️, Dark 🌑, Metal ⚙️, Sound 🔊
- **T1 self-combos**: all 10 T1 elements now have a self-combo → Plasma, Forest, Radiance, Void, Steel, Echo
- **Shop tier weights**: shifted toward T3/T4 — T2=65/35, T3=45/35/20, T4=25/30/30/15
- **Level 2 Reward** design: gold + flat stat boost choice; deferred implementation
- **ESC Pause Menu**: Resume, Settings, Forfeit Run, Quit to Main Menu, Quit to Desktop

### Files changed
- `data/ElementData.gd` — 6 new T1 + 6 new T2 self-combo results (20 T2 elements total)
- `data/RecipeData.gd` — 6 new self-combo recipes (10 total)
- `data/UIScale.gd` — TOOLTIP_ constants +5% (17/14/12/13)
- `systems/PhaseSystem.gd` — `advance_round()` resets `player_hp = 30`
- `systems/ShopSystem.gd` — `_tier_thresholds()` + `_pick_tier()` + weighted `reroll_shop()`
- `scenes/shared/TooltipCard.gd` — emoji stat keys (▲⬆⏱⚔💥💰); panel 230px wide
- `scenes/shared/PauseOverlay.gd` — NEW CanvasLayer pause menu (layer 110)
- `scenes/screens/Shop.gd` — PauseOverlay + ESC handler + pause signal handlers
- `scenes/screens/Battle.gd` — PauseOverlay + ESC handler; simulation pauses with overlay
- `test/unit/test_phase_system.gd` — HP test renamed to assert reset
- `test/unit/test_shop_system.gd` — 3 new tier-weight tests

## 2026-06-02 — Architecture refactors (improve-architecture)
- **Candidate 1**: ElementData.effective_damage now used by BattleSystem + TooltipCard. Was inconsistent: tooltip showed dmg×lv+tier, battle dealt dmg×lv. Fixed. Formula lives in one place.
- **Candidate 2**: ShopSystem 6 buy/swap fns → 1 `transfer(state, from_loc, to_loc)`. from/to: `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1=first empty. Shop.gd updated. test_shop_system.gd rewritten. 138/138 passing.

## 2026-06-02 — Match persistence: Lives + win goal + gold income
- Player HP in-battle only (resets to 30 in to_battle). Lives starts 10; hard loss→–3, medium→–2, close→–1; 0=eliminated. 10 wins=victory. +5g/round in advance_round.
- GameState: +lives, +wins, +opponent_starting_hp. PhaseSystem + Battle + Shop updated. 140/140 passing.

## 2026-06-02 — UIScale + system-layer mutations + shop overhaul + battle summary
- UIScale.gd: named constants + apply(node, size). All bare font overrides gone.
- ShopSystem: swap_inv_to_grid/swap_grid_to_inv/swap_within_grid (later collapsed to transfer). ForgeSystem: move_to_forge_slot, forge_quick_slot, remove_from_forge_slot.
- Shop full rewrite: drag-drop dispatch, SOLD placeholders, forge bench, undo (Ctrl+Z), sell zone, buy+upgrade ConfirmDialog, drag hints.
- BattleSystem: battle_stats accumulated per slot (fires+dmg). Battle: Summary toggle (fires+dmg+DPS). Pause + 1×/1.5×/2× speed controls.

## 2026-06-02 — Item Tooltip + scene folder restructure
- TooltipCard.gd: CanvasLayer layer=100, 0.3s hover timer per slot, cursor-follow + edge-flip. All slot types emit tooltip_requested/hide_requested.
- Folders split: scenes/screens/, scenes/slots/, scenes/shared/. All res:// paths updated.

## 2026-06-02 — Element system + forge + self-combos + scope cut
- Scenario C confirmed: elements are fighters. ItemData→ElementData (29 elements, 25 recipes, 3 tiers). RecipeData: order-independent lookup. ForgeSystem: level_up, forge, preview.
- Self-combos added (W+W→Ice, F+F→Blaze, A+A→Gale, E+E→Boulder). Tiers 4+5 removed.
- GameManager: undo_state, save_undo, apply_undo. Compendium scene added (programmatic card grid).

## 2026-06-01 — Godot migration + Phase 2 loop + maintainability baseline
- Migrated Phaser3/TS → Godot 4.6/GDScript. Phase 1: Boot→MainMenu→Settings. Phase 2: Shop→Battle→Result loop.
- Pure static systems: ShopSystem (buy/sell/reroll), BattleSystem (tick/compute_result), PhaseSystem.
- Strict typing on systems/+data/. UIScale baseline. GUT installed. CI (import+quit+tests).

## 2026-05-30 — Genre pivot + design foundations
- Pivot: extraction roguelite → auto-battler. Confirmed: Ability Chain combat, Innate Ability + Replay, 8-player async PvP, Merge+Forge, dual economy (Gold+Draft), ~30 pieces, Steam desktop.
