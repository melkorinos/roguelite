# Memory — Settled Design Decisions

## Core identity
Auto-battler. Build synergies, break the system, lose to your exact counter, master meta over dozens of sessions. Insps: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess. Steam desktop, async PvP, 20–30 min sessions. Visual: clean, minimal, weird, surreal.

## Entity + state model
Plain data objects + standalone static fns. No class inheritance. Systems take `GameState` dict, return new dict — no mutation. `GameManager.state` global. `GameState.create()` in `data/GameState.gd`.

## Feature flags (`data/FeatureFlags.gd`)
Static class, `static var` (not `const`) so flags flip at runtime. All false by default.
- `status_effects`, `hidden_recipes`, `efficiency_scoring`, `ability_chain`, `innate_ability`

## Match structure
8 players, last standing wins. Each round: Shop phase → combat phase. Mixed PvP + PvE (fixed schedule).
- **Player HP**: in-battle only. Resets to 30 in `to_battle()`. Not a match resource.
- **Life**: starts 100; hard loss (opp HP≥70%)→–30, medium (30–70%)→–20, close (<30%)→–10. 0=eliminated.
- **Win condition**: 10 wins = victory. Draw = player win (opponent async). Both end match → MainMenu.
- **Gold income**: +5g per round via `advance_round()`. No streak/interest yet.
- **Rounds unbounded**: match ends at 10 wins OR 0 Life.

## Combat model
Real-time deterministic. Elements fire on individual cooldown timers. Discrete ticks; result pre-computed, played back visually. Ties: top-left first. RNG seeded at combat start → reproducible.
Status effects on fire via `_apply_element_effect()`; real-time tick via 1s `status_tick_timer`.

## Innate + Replay
Player fires one Innate Ability once per combat at a chosen moment. After loss: spend Replay token, retrigger with Innate at different moment. Tokens: finite per-match. Economy TBD.

## Element system (132 elements, 169 recipes, 4 tiers)
- **T1 (12, 5g):** Water💧Cleanse, Fire🔥Burn, Air🌬️Haste, Earth🌍Armor, Lightning⚡Shock, Nature🌿Heal, Light☀️Blind, Dark🌑Curse, Metal⚙️Plating, Fungus🍄Poison, Blood🩸Leech, Frost🌨️Weaken. *(Sound retired → Fungus)*
- **T2 (78, 8g):** self-combos (12), originals cross (6), extended cross (24), Blood cross (11), Frost cross (10), extended-to-extended (15). 15 Group-G combos use placeholder names pending brainstorm.
- **T3 (32, 12g):** **T2+T2 only** — no T1+T2 paths. 2–3 convergence paths per element.
- **T4 (10, 16g):** **T3+T3 only**. 3 convergence paths. Compendium label: "Tier 4 — Phenomena".
- `effective_damage = base_damage × level + tier`. Forge result level = `min(level_a, level_b)`.
- **Merge**: same element ×2 same level → level+1. Drag-drop. No recipe needed.
- `discovered_recipes[]` in GameState. All visible now; shadow TBD.

## Shop UX (all item moves via ShopSystem.transfer)
- `ShopSystem.transfer(state, from_loc, to_loc)` — `{"zone":"shop"|"inventory"|"grid","slot":int}`; slot=-1=first empty.
- Buy (click)→first empty inv. Drag to matching Lv1→ConfirmDialog level-up. Sell→SellZone→half-price refund.
- Forge bench: 2 ForgeSlots; auto-forge on 2nd drop; F-key quick-forge; slot 2 replaced if both full.
- Undo: 1-action, Ctrl+Z + button. Shop: 5 rotating slots, SOLD placeholder, reroll costs 2g.

## Shop tier distribution (settled 2026-06-02)
`ShopSystem._tier_thresholds(shop_tier)` (cumulative) + `_pick_tier()`. Max element tier is T4.
- T1: 100% T1  |  T2: 65/35  |  T3: 45/35/20  |  T4: 25/30/30/15

## Level 2 Reward (design settled, not yet implemented)
Merging to level 2: flat gold payout + player choice (+1 base damage OR −0.5 s cooldown).

## Scene structure
- `scenes/screens/`: Boot, MainMenu, Settings, Shop, Battle, Compendium
- `scenes/slots/`: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone
- `scenes/shared/`: TooltipCard, PauseOverlay

## Rendering boundary
Scene scripts: rendering + input only. Nothing in `systems/` or `data/` may reference SceneTree.
All state mutations: `GameManager.state = SomeSystem.fn(GameManager.state, args)` → `_render()`.

## UI conventions
- **UIScale**: font-size deviations via `UIScale.apply(node, UIScale.CONST)`. No bare integers or direct `add_theme_font_size_override()`.
- **ThemeData.gd**: single-source color config. Never hardcode `Color()` in slot/screen scripts.
- **Item Tooltip**: TooltipCard (CanvasLayer 100), 0.3s hover, cursor-follow + edge-flip. Stats: Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price.
- **Battle speed/pause**: `_speed_mult` (1×/1.5×/2×) + `_paused`. Controls disabled on result.
- **Battle Summary**: fires+dmg+DPS per element both sides. Toggle below result buttons.

## Pause Menu (settled 2026-06-02)
ESC in Shop or Battle → PauseOverlay (CanvasLayer 110). Resume, Settings, Forfeit Run (→eliminated→MainMenu), Quit to Main Menu, Quit to Desktop. Battle simulation pauses.

## Godot lifecycle rule
`_ready()` fires on `add_child()`, not `.new()`. Set plain properties before `add_child`; call child-node methods only after.

## Board + synergies (partially TBD)
Battlegrid size TBD. Adjacency bonuses apply at setup, not during combat. Faction threshold synergies. Full design deferred — see `ideas.md`.

## Steam + backend seams
- **OpponentProvider** (`systems/`): `get_opponent(context)` → Ghost snapshot `{player_id, player_name, round, grid, acquired_day, source}`. LocalDaySeededAdapter + GhostFixtures fallback.
- **AchievementSystem** (`systems/`): `check(state, profile, event) → Dictionary`. Events: round_win/loss, match_win/eliminated, forge_discovered. 5 achievements.
- **PlayerProfile** autoload (`user://profile.cfg`): sections stats/progress/discovery. Master for `discovered_recipes`.
- **GhostFixtures** (`data/`): 3 prebuilt Ghost snapshots (tier 1/2/3). Test fixtures + deterministic fallback.
- **PlatformLayer** (identified, not built): SteamAdapter / NoOpAdapter for web.

## Status Effects (implemented 2026-06-03, gated by FeatureFlags.status_effects)
**Effect** = passive string on element dict; fires on cooldown expiry. **Status** = ongoing condition in `player_statuses`/`opponent_statuses` (flat dict, shared per side). Reset in `to_battle()`.
T1 mechanics: burn (ramp stacks, tick dmg), poison (permanent stacks), armor (absorb), plating (flat reduction, never depletes), blind (miss roll, cap 50%), shock (CD slow 50n/(n+5)), heal (instant HP), cleanse (remove 1 debuff stack), curse (amplify tick dmg), leech (heal = dmg dealt), weaken (timed stacks, reduce attacker dmg).
**StatusSystem API**: `empty_statuses`, `apply_effect`, `tick`, `compute_incoming_damage`, `slow_pct`.

## Balance tooling (settled 2026-06-03)
**BalanceSystem** (`systems/`, gated by `FeatureFlags.efficiency_scoring`). Two axes: DPS Score (`effective_damage / cooldown`) + Effect Score (hardcoded table, T1 only; T2/T3 = 0 pending design). Board score = sum of 4 slots. Dev panel in Compendium. ADR: `docs/adr/0002-two-axis-efficiency-scoring.md`.

## Deferred / TBD
Backlog in `.claude/ai-helper/ideas.md`. Key: T2 placeholder names (8 Group-G combos remaining), T2/T3 action design, Level 2 Reward impl, Innate Ability economy, Faction synergy + grid adjacency, Draft system, Meta-progression shape, PlatformLayer, Battlegrid size. Code renames pending: `"effect"` field → `"action"`, `effect_score` → `action_score`.
