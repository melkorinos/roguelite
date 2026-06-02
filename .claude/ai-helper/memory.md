# Memory — Settled Design Decisions

## Core identity
Auto-battler. Build synergies, break the system, lose to your exact counter, master meta over dozens of sessions. Insps: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess. Steam desktop, async PvP, 20–30 min sessions. Visual: clean, minimal, weird, surreal.

## Entity + state model
Plain data objects + standalone static fns. No class inheritance. Systems take `GameState` dict, return new dict — no mutation. `GameManager.state` global. `GameState.create()` in `data/GameState.gd`.

## Match structure
8 players, last standing wins. Each round: Shop phase → combat phase. Mixed PvP + PvE (fixed schedule).
- **Player HP**: in-battle only. Resets to 30 in `to_battle()`. Not a match resource.
- **Lives**: starts 10; hard loss (opp HP≥70% start)→–3, medium (30–70%)→–2, close (<30%)→–1. 0=eliminated.
- **Win condition**: 10 wins = victory. Draw = player win (opponent async). Both end match → MainMenu.
- **Gold income**: +5g per round via `advance_round()`. No streak/interest yet.

## Combat model
Real-time deterministic. Elements fire on individual cooldown timers → deal `effective_damage` to opponent HP bar. Discrete ticks; result pre-computed, played back visually. Ties: top-left first. RNG seeded at combat start → reproducible.

## Ability Chain + Innate + Replay
Abilities activate in sequence; no positional targeting — whole Composition vs opponent. Player fires one Innate Ability once per combat. After loss: spend Replay token, retrigger with Innate at different moment; new result replaces original. Tokens: finite per-match resource.

## Element system (prototype scope: 3 tiers, 29 elements, 25 recipes)
- T1 (4, 5g): Water, Fire, Air, Earth
- T2 cross (6, 8g): Steam, Rain, Mud, Smoke, Lava, Dust
- T2 self (4, 8g): Ice(W+W), Blaze(F+F), Gale(A+A), Boulder(E+E)
- T3 (15, 12g): Cloud, Geyser, Fog, Rainbow, Storm, Plant, Swamp, Brick, Ash, Acid, Obsidian, Volcano, Sand, Sandstorm, Clay
- **Level up**: same element ×2 same level → level+1. Drag-drop. No recipe needed.
- **Forge**: 2 elements at bench → recipe → new element at level 1. Self-combos valid.
- `effective_damage = base_damage × level + tier` (universal, via `ElementData.effective_damage(item)`).
- Forge result level = `min(level_a, level_b)`. Warning shown on mismatch.
- `discovered_recipes[]` in GameState tracks recipe history. All visible now; shadow TBD.

## Shop UX (all item moves via ShopSystem.transfer)
- `ShopSystem.transfer(state, from_loc, to_loc)` — `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1=first empty.
- Buy (click)→first empty inv. Buy (drag to empty slot)→that slot. Buy (drag to matching Lv1)→ConfirmDialog level-up.
- Sell: drag inv or grid item to SellZone → half-price refund.
- Forge bench: 2 ForgeSlots (right panel); auto-forge on 2nd drop; F-key quick-forge; slot 2 replaced if both full.
- Undo: 1-action, Ctrl+Z + button. GameManager.save_undo()/apply_undo().
- Shop: 5 rotating slots, SOLD placeholder on buy, reroll costs 2g. Drag hints on drag-start.

## Scene structure
- `scenes/screens/`: Boot, MainMenu, Settings, Shop, Battle, Compendium
- `scenes/slots/`: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone
- `scenes/shared/`: TooltipCard

## Rendering boundary
Scene scripts: rendering + input only. Nothing in `systems/` or `data/` may reference SceneTree. All state mutations in system layer via `GameManager.state = SomeSystem.fn(GameManager.state, args)`.

## UI conventions
- **UIScale**: all font-size deviations via `UIScale.apply(node, UIScale.CONST)`. No bare integers or direct `add_theme_font_size_override()`.
- **Item Tooltip**: TooltipCard (CanvasLayer 100), 0.3s hover per slot, cursor-follow + edge-flip. Stats: Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price. Abilities Panel placeholder.
- **Battle speed/pause**: `_speed_mult` (1×/1.5×/2×) + `_paused`. All controls disabled on result.
- **Battle Summary**: fires+dmg+DPS per element both sides. Toggle below result buttons.

## Godot lifecycle rule
`_ready()` fires on `add_child()`, not `.new()`. Set plain properties before `add_child`; call child-node methods only after.

## Board + synergies (partially TBD)
Grid shape TBD. Adjacency bonuses apply at setup, not during combat. Each element has own buff direction. Opponent board fully visible before fight; player can rearrange. Faction threshold synergies (N of same→bonus) + passive ability interactions as emergent synergies.

## Steam + backend seams (identified, not yet built)
- **OpponentProvider**: extract `create_opponent_grid` behind seam. LocalDaySeeded now; BackendHTTP later — no PhaseSystem changes needed.
- **AchievementSystem**: pure static `check(state, profile)` in `advance_round()`. Covers Steam achievements + internal milestones via same seam.
- **PlayerProfile autoload**: `user://profile.cfg`. Fields: total_damage, matches_won, achievements[], milestones{}, discovered_recipes[].
- **PlatformLayer autoload**: isolates GodotSteam. SteamAdapter (desktop) / NoOpAdapter (web). Required — GodotSteam needs custom engine build, incompatible with web export.
- **Opponent snapshot**: collapse flat fields → `opponent_snapshot {player_id, name, grid, source, day}`.

## Deferred / TBD
- Grid shape + adjacency buff logic
- Trinkets (passive run bonuses; primary PvE drop source)
- Identity pick ("I am playing Water this run") — bonuses TBD
- Meta-progression shape (unlock-gated vs cosmetic vs XP) — dedicated session needed
- Internal milestones rewards (seam exists via AchievementSystem)
- PvE Bosses (damage/defence check → milestone unlock) — strong option, not committed
- Merge mechanic (3×same→upgrade) — not yet implemented
- Replay token economy
