# Handoff — Auto-Battler Prototype

## Status

| Phase | Goal | Status |
|-------|------|--------|
| Phase 1 — Setup | Godot 4 project, Main Menu, 1 controllable entity | **COMPLETE** |
| **Phase 2 — Prototype** | Shop → Battle → Result loop, full playable round | **THIS HANDOFF** |

---

## What exists (Phase 1 output)

```
project.godot                      ← Godot 4.6, 1280×720, canvas_items stretch
autoloads/
  GameManager.gd                   ← global state holder (Autoload)
data/
  GameState.gd                     ← create() factory — EXPAND in Phase 2
scenes/
  Boot.tscn + Boot.gd              ← transitions to MainMenu — keep unchanged
  MainMenu.tscn + MainMenu.gd      ← Start / Settings / Quit — update Start target
  Settings.tscn + Settings.gd      ← placeholder — keep unchanged
  Game.tscn + Game.gd              ← walking demo — REPLACE with Shop + Battle
```

**Architecture rule (hard):** Scene scripts (`.gd` attached to `.tscn`) handle rendering and input only. Nothing in `systems/` or `data/` may reference scene nodes or the SceneTree.

**State pattern:** `GameManager.state = SomeSystem.fn(GameManager.state, args)` → `_render()`

---

## Read these first

| File | Purpose |
|------|---------|
| [soul.md](soul.md) | Game identity and player fantasy |
| [memory.md](memory.md) | All settled design decisions |
| [goals.md](goals.md) | Sprint checklist |
| [../../CONTEXT.md](../../CONTEXT.md) | Domain vocabulary — use in variable names and node names |

---

## What to build

### 1. Replace `data/GameState.gd`

Expand the state for the auto-battler loop. Replaces the Phase 1 walking-demo state entirely.

```gdscript
class_name GameState

static func create() -> Dictionary:
    return {
        "phase": "shop",              # "shop" | "battle" | "result"
        "round": 1,
        "player_hp": 30,
        "opponent_hp": 20,
        "gold": 10,
        "inventory": [null, null, null, null, null],  # 5 slots
        "shop_items": [],             # populated on Shop scene ready
        "battle_timer": 0.0,
        "sandstorm_fired": false,
    }
```

### 2. Add `data/ItemData.gd`

Five placeholder items. Stats are prototype-only — not final balance.

```gdscript
class_name ItemData

static func all_items() -> Array:
    return [
        { "id": "a", "name": "Iron Sword",     "price": 10, "attack":  3, "defence":  0 },
        { "id": "b", "name": "Wooden Shield",  "price":  8, "attack":  0, "defence":  2 },
        { "id": "c", "name": "Rusty Axe",      "price": 14, "attack":  4, "defence": -1 },
        { "id": "d", "name": "Leather Armour", "price":  9, "attack":  0, "defence":  3 },
        { "id": "e", "name": "Lucky Charm",    "price":  6, "attack":  1, "defence":  1 },
    ]
```

### 3. Add `systems/ShopSystem.gd`

Pure static functions. No scene node references.

```gdscript
class_name ShopSystem

# Deducts gold, places item in first empty inventory slot.
# Returns state unchanged if gold insufficient or inventory full.
static func buy_item(state: Dictionary, item_id: String) -> Dictionary:
    ...

# Removes item from slot, refunds floor(price / 2) gold.
static func sell_item(state: Dictionary, slot_index: int) -> Dictionary:
    ...

# Costs 2 gold. Picks 5 random items from ItemData.all_items().
# Returns state unchanged if gold < 2.
static func reroll_shop(state: Dictionary) -> Dictionary:
    ...
```

### 4. Add `systems/BattleSystem.gd`

Pure static functions. No scene node references.

The opponent for this prototype is a dummy: 20 HP, 2 attack, 1 defence. Values are not meaningful — exist only to make the result screen work.

```gdscript
class_name BattleSystem

# Sums attack and defence from non-null inventory slots.
static func get_player_stats(inventory: Array) -> Dictionary:
    # returns { "attack": int, "defence": int }

# Advances battle_timer by delta seconds.
# At battle_timer >= 10.0: sets sandstorm_fired = true, deals 10 damage to both HPs.
# At battle_timer >= 11.0 and sandstorm fired: sets phase = "result".
static func tick_battle(state: Dictionary, delta: float) -> Dictionary:
    ...

# Returns "player_wins" | "opponent_wins" | "draw"
static func compute_result(state: Dictionary) -> String:
    ...
```

### 5. Add `scenes/Shop.tscn` + `scenes/Shop.gd`

Layout (1280×720 canvas):

```
┌──────────────────────────────────────────────┐
│  Round 1     Gold: 10g      HP: 30/30        │  ← top bar Label nodes
├──────────────────────────────────────────────┤
│  FOR SALE                                    │
│  [Iron Sword      10g  +3atk          ] Buy  │
│  [Wooden Shield    8g  +2def          ] Buy  │
│  [Rusty Axe       14g  +4atk  -1def   ] Buy  │
│  [Leather Armour   9g  +3def          ] Buy  │
│  [Lucky Charm      6g  +1atk  +1def   ] Buy  │
│                              [Reroll — 2g]   │
├──────────────────────────────────────────────┤
│  INVENTORY  (5 slots)                        │
│  [Iron Sword] [empty] [empty] [empty] [empty]│  ← click item to sell
├──────────────────────────────────────────────┤
│                                   [► FIGHT]  │
└──────────────────────────────────────────────┘
```

`Shop.gd` behaviour:
- `_ready()`: if `state.shop_items` is empty, call `ShopSystem.reroll_shop` with free first roll (skip cost). Call `_render()`.
- `_render()`: rebuild all labels/buttons from `GameManager.state` — full redraw every time, no partial caching.
- Buy button → `GameManager.state = ShopSystem.buy_item(state, item_id)` → `_render()`
- Inventory slot (occupied) → `GameManager.state = ShopSystem.sell_item(state, index)` → `_render()`
- Reroll → `GameManager.state = ShopSystem.reroll_shop(state)` → `_render()`
- FIGHT → `GameManager.state.phase = "battle"` → `change_scene_to_file("res://scenes/Battle.tscn")`

### 6. Add `scenes/Battle.tscn` + `scenes/Battle.gd`

Layout:

```
┌──────────────────────────────────────────────┐
│  BATTLE — Round 1                            │
├──────────────────────────────────────────────┤
│  YOUR ITEMS              OPPONENT            │
│  Iron Sword (+3atk)      [Dummy Fighter]     │
│  Leather Armour (+3def)                      │
│                                              │
│  YOUR HP: 30             OPP HP: 20          │
│                                              │
│  ⏱ 10s until SANDSTORM...                   │
│  [SANDSTORM hits! -10 to both]  ← t=10s     │
├──────────────────────────────────────────────┤
│  Result: YOU WIN / YOU LOSE / DRAW           │  ← visible after sandstorm
│                        [Next Round]  [Menu]  │
└──────────────────────────────────────────────┘
```

`Battle.gd` behaviour:
- `_process(delta)`: `GameManager.state = BattleSystem.tick_battle(state, delta)` → `_render()`. Stop calling once `state.phase == "result"`.
- Sandstorm label: hidden until `state.sandstorm_fired == true`.
- Result + buttons: hidden until `state.phase == "result"`.
- Next Round button: `state.round += 1`, reset `player_hp`, `opponent_hp`, `battle_timer`, `sandstorm_fired`, set `phase = "shop"`, `change_scene_to_file("res://scenes/Shop.tscn")`.
- Menu button: `GameManager.state = GameState.create()`, `change_scene_to_file("res://scenes/MainMenu.tscn")`.

### 7. Update `scenes/MainMenu.gd`

Change the Start button to go to Shop instead of Game:

```gdscript
func _on_start_pressed() -> void:
    GameManager.state = GameState.create()
    get_tree().change_scene_to_file("res://scenes/Shop.tscn")
```

### 8. Delete `scenes/Game.tscn` + `scenes/Game.gd`

The walking demo is replaced by the Shop + Battle loop. Remove both files once Shop is running.

---

## Final file structure after Phase 2

```
project.godot
autoloads/
  GameManager.gd
data/
  GameState.gd          ← replaced (auto-battler state)
  ItemData.gd           ← new
scenes/
  Boot.tscn + Boot.gd
  MainMenu.tscn + MainMenu.gd   ← Start now goes to Shop
  Settings.tscn + Settings.gd
  Shop.tscn + Shop.gd           ← new
  Battle.tscn + Battle.gd       ← new
systems/
  ShopSystem.gd         ← new
  BattleSystem.gd       ← new
```

---

## Execution order

1. Replace `data/GameState.gd` with auto-battler state
2. Add `data/ItemData.gd`
3. Add `systems/ShopSystem.gd`, implement and verify logic manually
4. Add `systems/BattleSystem.gd`, implement and verify logic manually
5. Build `scenes/Shop.tscn` + `Shop.gd`, verify buy / sell / reroll cycle
6. Build `scenes/Battle.tscn` + `Battle.gd`, verify sandstorm fires at 10s
7. Update `MainMenu.gd` Start target to Shop
8. Delete `Game.tscn` + `Game.gd`
9. Full loop test: MainMenu → Shop → buy items → FIGHT → sandstorm → result → Next Round → Shop

**Done when:** A complete round plays through without errors. The result screen shows win/loss/draw. Next Round returns to the shop with round counter incremented.

---

## What is NOT in scope

- Faction or synergy system
- Merge or Forge mechanics
- Ability Chain combat (sandstorm is the placeholder battle resolution)
- Draft system
- Rarity tiers
- Real item balance
- Meta-progression
- Async multiplayer / backend
