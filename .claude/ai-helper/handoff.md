# Handoff

## Status

| Phase | Goal | Status |
|-------|------|--------|
| Phase 1 — Setup | Godot 4 project, Main Menu, 1 controllable entity | **COMPLETE** |
| Phase 2 — Core loop | Shop → Battle → Result, full playable round | **COMPLETE** |
| Phase 3 — Maintainability | Strict typing, GUT tests, CI, global theme | **COMPLETE** |
| **Phase 4 — ?** | TBD | **NEXT** |

---

## Current file structure

```
project.godot                        ← Compatibility renderer, 1280×720, canvas_items stretch
autoloads/
  GameManager.gd                     ← global state holder (Autoload)
data/
  GameState.gd                       ← auto-battler state factory (strictly typed)
  ItemData.gd                        ← 5 placeholder items (strictly typed)
scenes/
  Boot.tscn + Boot.gd
  MainMenu.tscn + MainMenu.gd        ← Start → Shop
  Settings.tscn + Settings.gd
  Shop.tscn + Shop.gd                ← FOR SALE, inventory, Reroll, FIGHT
  Battle.tscn + Battle.gd            ← HP display, sandstorm timer, result screen
systems/
  ShopSystem.gd                      ← buy_item, sell_item, reroll_shop (strictly typed)
  BattleSystem.gd                    ← tick_battle, compute_result, get_player_stats (strictly typed)
addons/gut/                          ← test framework
test/unit/
  test_game_state.gd                 ← 5 tests, 11 assertions, passing
.github/workflows/ci.yml             ← import + boot check + GUT on every push
.gutconfig.json                      ← points to res://test/unit/
```

---

## Architecture rules (hard)

- Scene scripts handle rendering and input only — no logic
- `systems/` and `data/`: strict typing mandatory (all signatures, arithmetic locals, `as` casts on Dictionary access)
- State pattern: `GameManager.state = SomeSystem.fn(GameManager.state, args)` → `_render()`
- No per-node font size overrides — use global default; override only for exceptions
- Run `godot --headless --import && godot --headless --quit` before closing any task

---

## Read these first

| File | Purpose |
|------|---------|
| [soul.md](soul.md) | Game identity and player fantasy |
| [memory.md](memory.md) | All settled design decisions |
| [goals.md](goals.md) | Sprint checklist |
| [../../CONTEXT.md](../../CONTEXT.md) | Domain vocabulary |

---

## What is NOT in scope yet

- Primary play object decision (Scenario A / B — units vs single character)
- Real Ability Chain combat (sandstorm is placeholder)
- Faction / synergy system
- Merge and Forge mechanics
- Draft system
- Innate Ability + Replay mechanic
- Real item balance / rarity tiers
- Opponent AI (currently a dummy)
- Meta-progression
- Async multiplayer / backend
- Steam integration (GodotSteam — late phase, requires custom editor)
- Web export setup
