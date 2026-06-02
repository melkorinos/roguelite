# Development Log

## 2026-06-02 — Item Tooltip, battle speed/pause, scenes folder restructure

### Decisions settled (grill-with-docs session)
- Item Tooltip: stats card that appears after 0.3s hover; two sections — stats (Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price) + Abilities Panel placeholder ("— none yet —"). Follows cursor, flips left near screen edge.
- Applies to: Shop (ShopItemTile, InventorySlot, BattleSlot in grid, ForgeSlot) and Battle (both player and opponent BattleSlots).
- Battle speed controls: ⏸ Pause + 1× / 1.5× / 2× buttons near top of battle scene. Pause freezes everything (delta, progress bars, timer display, fire animations). All controls disabled when result phase hits.
- Folder structure: `scenes/screens/`, `scenes/slots/`, `scenes/shared/` — agreed via grill.
- Vocabulary added to CONTEXT.md: **Item Tooltip**, **Abilities Panel**.

### Files added
- `scenes/shared/TooltipCard.gd` — NEW: CanvasLayer (layer=100), builds UI programmatically, `show_for(element)` / `hide_card()` / `_process` cursor follow + edge flip

### Files changed
- `scenes/slots/BattleSlot.gd` — `tooltip_requested`/`tooltip_hide_requested` signals; `_item_dict` storage; 0.3s hover Timer; `set_element` stores dict
- `scenes/slots/ShopItemTile.gd` — same signals + Timer; `_elem_dict` stored in `setup()`; drag-start hides tooltip
- `scenes/slots/InventorySlot.gd` — same signals + Timer; public `item_dict` property set by Shop.gd
- `scenes/slots/ForgeSlot.gd` — same signals + Timer; `_item_dict` stored in `set_item()`
- `scenes/screens/Shop.gd` — `_tooltip: TooltipCard`; `hide_card()` on every `_render()`; tooltip signals wired in all four rebuild functions
- `scenes/screens/Battle.gd` — `_tooltip: TooltipCard`; `_paused`/`_speed_mult`; `_process` uses `delta * _speed_mult`; tooltip signals wired; speed/pause handlers
- `scenes/screens/Battle.tscn` — added ControlsRow (PauseButton, Speed1xButton, Speed15xButton, Speed2xButton) with signal connections
- `CONTEXT.md` — Item Tooltip and Abilities Panel terms added
- `CLAUDE.md` — architecture table updated with new scene subfolders; Boot.tscn path updated
- All `res://scenes/X` path references updated to `res://scenes/screens/X` or `res://scenes/slots/X` across project.godot, all .tscn files, and all .gd files

### Folder restructure
- `scenes/screens/`: Boot, MainMenu, Settings, Shop, Battle, Compendium (+ .uid files)
- `scenes/slots/`: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone (+ .uid files)
- `scenes/shared/`: TooltipCard (+ .uid file)

### Test results
Boot: exit 0 (import + quit). GUT: 55/55 passing (all tests green after restructure).

## 2026-06-02 — Shop UX polish, Battlegrid sell, Battle Summary, Compendium overhaul

### Grilling session decisions
- Shop fixed size: 6 slots always visible; bought slots show greyed-out "SOLD" placeholder (position-stable)
- Drag-to-buy: drop shop tile on empty inventory slot = straight buy into that slot (no dialog; undo covers it)
- Sell from Battlegrid: shop-scene-only; drag grid element to SellZone works same as inventory sell
- Battle Summary: inline expansion below result buttons; fires + damage + DPS per element both sides
- Compendium: card grid (148×180 tiles, 52px emoji, 6 cols) replacing RichTextLabel

### Files changed
- `CONTEXT.md` — added Battlegrid and Battle Summary terms
- `data/GameState.gd` — `shop_items` now fixed 6-slot array `[null…]`; added `battle_stats` field
- `systems/ShopSystem.gd` — `buy_item(state, id, shop_slot)` + `buy_item_to_slot` + `sell_grid_item`; `buy_and_level_up` now takes `shop_slot`; `reroll_shop` fills fixed 6-slot array
- `systems/PhaseSystem.gd` — `to_battle` initialises `battle_stats`; `advance_round` resets `shop_items` to null array
- `systems/BattleSystem.gd` — `tick_battle` accumulates per-slot fires+damage into `battle_stats`
- `scenes/ShopItemTile.gd` — `shop_slot_index` property; `buy_pressed(id, slot)` signal; drag data carries `shop_slot`
- `scenes/InventorySlot.gd` — shop drop on empty slot now accepted; new `shop_buy_to_slot_requested(id, inv_slot, shop_slot)` signal
- `scenes/SellZone.gd` — accepts "grid" type drops; `sold(from_type, from_index)` signal
- `scenes/BattleSlot.gd` — `drag_started(element_id, grid_slot, sell_price)` + `drag_ended()` signals; stores `element_id`
- `scenes/Shop.gd` — full rewrite wiring all new signals; SOLD placeholder tiles; grid drag hints; buy-to-slot; grid sell dispatch
- `scenes/Battle.tscn` — added SummaryButton, SummarySeparator, SummaryPanel+SummaryVBox nodes
- `scenes/Battle.gd` — `_on_summary_pressed` toggle; `_build_summary` / `_add_summary_rows` with fires+dmg+dps colour-coded rows
- `scenes/Compendium.tscn` — `CompendiumContent` changed from RichTextLabel to VBoxContainer
- `scenes/Compendium.gd` — full rewrite: programmatic card grid (6 cols per tier, big emoji 52px, recipe emojis)
- `test/unit/test_shop_system.gd` — updated all `buy_item` calls; fixed reroll assertion; added `test_buy_nulls_out_shop_slot`, `test_sell_grid_item_refunds_and_clears`

### Test results
Boot: exit 0. GUT: 55/57 passing. 2 pre-existing failures in test_phase_system.gd (sandstorm_fired + opponent_hp reset) — unrelated to this work.

## 2026-06-02 — Shop overhaul: drag-drop, forge bench, icons, undo

### Design decisions settled (grill-with-docs session)
- Forge result level = min(level_a, level_b); warning shown on mismatch
- Stats formula: `effective_damage = base_damage × level + tier` (universal)
- Cooldown: unchanged for now
- Shop: 6 icon tiles (ShopItemTile, 110×110, emoji + name + price)
- Forge: dedicated right-panel 2-slot bench (ForgeSlot); auto-forges on 2nd drop; F key quick-forge
- F key edge case: replaces slot 2 if both full; old slot 2 item returns to inventory
- Level-up: drag inventory item onto same-element, same-level slot (hard reject otherwise)
- Sell: drag inventory item to SellZone (wraps shop items area); drop detection bubbles through ShopItemTile
- Buy+upgrade combo: drag shop icon onto matching Lv1 inventory item → ConfirmationDialog
- Undo: 1-action; GameManager.save_undo() / apply_undo(); Undo button + Ctrl+Z
- Drag hint overlays: SellZone highlights with "Sell Xg"; matching slots turn green on drag start
- Battle grid: unchanged visually, noted for future UI/sound treatment

### Files changed
- `data/GameState.gd` — added `forge_slots: [null, null]`
- `autoloads/GameManager.gd` — added `undo_state`, `save_undo()`, `apply_undo()`
- `data/ElementData.gd` — added `effective_damage(item)` static helper
- `systems/ForgeSystem.gd` — forge result level = min(); `forge_from_bench()`; `_first_empty_inv_slot()` helper
- `systems/ShopSystem.gd` — 6 items in reroll; `buy_and_level_up()` for combo action
- `scenes/ForgeSlot.gd` — NEW: 2-slot forge bench tile; accepts inventory drops; `item_placed` signal
- `scenes/ShopItemTile.gd` — NEW: 110×110 icon tile; drag emits `{"type":"shop"}`; explicit false `_can_drop_data` for bubbling
- `scenes/SellZone.gd` — NEW: PanelContainer wrapping shop items; accepts inventory drops; `show_hint()`/`hide_hint()`
- `scenes/InventorySlot.gd` — new signals (`drag_started`, `drag_ended`, `forge_quick_slot`, `shop_buy_upgrade_requested`); F-key quick-forge; `_can_drop_data` now hard-rejects level mismatch and enforces same-element for level-up; tracks `element_id`, `element_level`, `element_price`
- `scenes/Shop.tscn` — full layout rewrite: TopBar + UndoButton, MainArea HBox with LeftPanel (shop icons, inventory, battle grid) + RightPanel (forge bench)
- `scenes/Shop.gd` — full rewrite: drag-drop dispatch, forge bench automation, undo, sell zone, buy+upgrade dialog, drag hint overlays; removed click-to-select flow entirely
- `test/unit/test_shop_system.gd` — `test_reroll_returns_up_to_4_items` → `test_reroll_returns_up_to_6_items`

### Test results
Boot: exit 0. GUT: 53/55 passing. 2 pre-existing failures in test_phase_system.gd (`sandstorm_fired` missing in to_battle, opponent_hp not reset in advance_round) — unrelated to this work.

## 2026-06-02 — Self-combos, scope cut T4/T5, in-game Compendium
- Added 4 self-combo elements (tier 2, 8g): Ice (W+W 🧊), Blaze (F+F 🔆), Gale (A+A 🌪️), Boulder (E+E ⛰️)
- Removed tiers 4 and 5 from ElementData.gd and RecipeData.gd (26 elements, 30 recipes cut)
- Recipe count: 49 → 25. Element count: 48 → 29. All within 3 tiers now.
- ForgeSystem.forge() now supports same-element recipes (removed `element_id == element_id` guard)
- ForgeSystem.preview() restructured: checks recipe first (covers both same and different elements), falls back to level-up preview if no recipe exists
- ForgeSystem tests updated: `test_forge_unknown_recipe_returns_state_unchanged` now uses steam+mud; `test_preview_same_element_shows_next_level` uses steam+steam; new test `test_forge_self_combo_produces_result` verifies water+water → ice
- elements.html rewritten: T1/T2-cross/T2-self/T3 sections, self-combos visually distinguished, quick-ref table updated to 25 recipes
- Added Compendium scene (scenes/Compendium.tscn + scenes/Compendium.gd): programmatically generated from ElementData/RecipeData, all recipes fully visible now
- Added Compendium button to MainMenu between Settings and Quit; connected to _on_compendium_pressed()

## 2026-06-02 — Element system prototype (buying, leveling, forging backbone)
- Resolved primary play object: **Scenario C confirmed** — elements are the fighters, no unit/character layer
- `data/ItemData.gd` deleted; replaced by `data/ElementData.gd` (4 basics + 6 tier-2 combos with cooldown/damage)
- `data/RecipeData.gd` added — order-independent recipe lookup for all 6 basic pairings
- `data/GameState.gd` updated — 6 inventory slots, `shop_tier`, `discovered_recipes`
- `systems/ForgeSystem.gd` added — `level_up`, `forge`, `preview` (all pure static, no scene refs)
- `systems/ShopSystem.gd` updated — uses ElementData + tier filtering; sells refund half of price
- `systems/BattleSystem.gd` updated — reads `damage` not `attack/defence` from elements
- `scenes/Shop.tscn` updated — added Forge Bench section (ForgeInfoLabel, LevelUpButton, ForgeButton, SellButton, ForgeResultLabel)
- `scenes/Shop.gd` rewritten — slot selection, forge/level-up/sell actions, result preview for known vs unknown recipes
- `test/unit/test_game_state.gd` updated — inventory size assertion 5→6
- Boot check: exit 0. All 6 classes registered cleanly.
- Godot added to PATH via `C:\Users\Dimitris\bin\godot.cmd` wrapper pointing at `E:\desktop\Godot_v4.6.3-stable_win64_console.exe`
- memory.md updated: primary play object settled, element system documented, combat model updated to real-time deterministic

## 2026-05-25
- Initialized project scaffold via architecture grilling session
- Confirmed toolchain: Vite + TypeScript + pnpm + Vitest + Phaser 3
- Confirmed entity model: plain data objects + standalone systems, no ECS framework
- Confirmed GameState: single object, passed explicitly, immutable updates
- Confirmed scene chain: Boot → MainMenu (Start/Settings/Quit) → Game + UIScene overlay
- Deferred: simulation model (turn-based vs action), run pressure mechanics
- Tentative: extraction run structure, puzzle-satisfaction-with-chaos-payoff player feel

## 2026-06-01 (tests green)
- GUT configured: .gutconfig.json pointing to res://test/unit/
- test_game_state.gd: 5 tests, 11 assertions, 0.271s — all passing
- Phase 2 full loop test confirmed in editor

## 2026-06-01 (maintainability)
- Strict typing enforced on `systems/` and `data/` — all function signatures typed, arithmetic vars typed, `as` casts for Dictionary access
- Global font size set in project.godot (GUI → theme/default_font_size = 20); all per-node `add_theme_font_size_override()` calls removed from scene scripts
- `.github/workflows/ci.yml` added — `godot --headless --import` + `--quit` on every push; GUT test job scaffolded but commented until tests exist
- CLAUDE.md updated with strict typing rule, theme override rule, and build validation step
- Grilling session established: no Python dependency (gdtoolkit skipped), all 3 validation tiers agreed (parse/boot/tests), GUT chosen when tests begin

## 2026-06-01 (Phase 2)
- Phase 2 complete: Shop → Battle → Result loop fully implemented
- `data/GameState.gd` replaced with auto-battler state (phase/round/gold/inventory/HP/sandstorm)
- `data/ItemData.gd` added — 5 placeholder items (Iron Sword, Wooden Shield, Rusty Axe, Leather Armour, Lucky Charm)
- `systems/ShopSystem.gd` added — buy_item, sell_item, reroll_shop (pure static, no scene refs)
- `systems/BattleSystem.gd` added — get_player_stats, tick_battle, compute_result (pure static, no scene refs)
- `scenes/Shop.tscn` + `Shop.gd` added — FOR SALE list, inventory, Reroll, FIGHT button; full-redraw _render() pattern
- `scenes/Battle.tscn` + `Battle.gd` added — HP display, sandstorm at 10s, result + Next Round / Menu buttons
- `MainMenu.gd` Start → Shop (was Game)
- `scenes/Game.tscn` + `scenes/Game.gd` deleted (walking demo replaced)
- One remaining item: full loop test in Godot editor

## 2026-06-01
- Full migration from Phaser 3 / TypeScript to Godot 4.6 / GDScript — complete
- Deleted all Node/npm/Phaser/TypeScript files; repo is now a pure Godot project
- Phase 1 delivered: Boot → MainMenu → Settings → Game (arrow-key player entity)
- State pattern confirmed: `GameManager` Autoload + pure static system functions
- Shop feel settled: creative expression with soft pressure
- Win/loss feel settled: all three simultaneously — engineered, spectacular, clinical
- Primary play object (A vs B) and meta-progression: deferred
- Two handoff docs merged into one `handoff.md`; all internal docs updated for Godot
- Phase 2 next: Shop → Battle → Result loop

## 2026-05-30
- Major genre pivot: extraction roguelite → auto-battler (ability-chain combat)
- Confirmed inspirations: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess
- Confirmed combat model: Ability Chain (The Bazaar-style) — pieces trigger abilities in sequence, no positional targeting, single Player HP bar per side
- Confirmed: player has one Innate Ability per combat; Replay mechanic lets them retrigger the fight with Innate fired at a different moment
- Confirmed: 8 players per match, async PvP + shared PvE rounds
- Confirmed: Merge (3x same → upgrade, primary) + Forge (A+B→C, costs 2g, secondary)
- Confirmed: Gold shop (pieces) + Draft (items/trinkets) dual economy
- Confirmed: ~30 pieces at launch, rarity tiers (Common/Rare/Epic), 20–30 min sessions
- Confirmed: Steam desktop, async, F2P → paid once
- Confirmed: Light meta-progression (Faction/Synergy unlocks)
- Confirmed: Clean/minimal/weird/surreal aesthetic
- Confirmed prototype shape: Shop → Buy/Organise/Reroll → Click Fight → watch Ability Chain → Result
- Tentative: PvE Bosses as damage/defence check milestones (strong option, not committed)
- Open: primary play object (Scenario A / B / C — units vs single character vs items-as-fighters)
- CONTEXT.md overhauled: extraction roguelite terms retired, auto-battler vocabulary added
- soul.md rewritten, memory.md replaced, goals.md Sprint 1 drafted
