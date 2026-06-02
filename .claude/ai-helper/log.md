# Development Log

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
