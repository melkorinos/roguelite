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
- **Rounds unbounded**: match ends at 10 wins OR 0 lives, not after a fixed count. Can exceed 10 rounds (e.g. 9 losses + 10 wins = 19 PvP rounds minimum, plus PvE rounds).

## Combat model
Real-time deterministic. Elements fire on individual cooldown timers → deal `effective_damage` to opponent HP bar. Discrete ticks; result pre-computed, played back visually. Ties: top-left first. RNG seeded at combat start → reproducible.

## Ability Chain + Innate + Replay
Abilities activate in sequence; no positional targeting — whole Composition vs opponent. Player fires one Innate Ability once per combat. After loss: spend Replay token, retrigger with Innate at different moment; new result replaces original. Tokens: finite per-match resource. *(Combat is still placeholder; real Ability Chain is deferred.)*

## Element system (41 elements, 31 recipes, 3 tiers)
- **T1 (10, 5g):** Water 💧, Fire 🔥, Air 🌬️, Earth 🌍, Lightning ⚡, Nature 🌿, Light ☀️, Dark 🌑, Metal ⚙️, Sound 🔊
- **T2 cross (6, 8g):** Steam, Rain, Mud, Smoke, Lava, Dust — only the original 4 T1s (Water/Fire/Air/Earth) have cross-combos; Lightning/Nature/Light/Dark/Metal/Sound cross-combos deferred
- **T2 self (10, 8g):** Ice, Blaze, Gale, Boulder, Plasma, Forest, Radiance, Void, Steel, Echo — all 10 T1s have a self-combo
- **T3 (15, 12g):** Cloud, Geyser, Fog, Rainbow, Storm, Plant, Swamp, Brick, Ash, Acid, Obsidian, Volcano, Sand, Sandstorm, Clay
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

## Shop tier distribution (settled 2026-06-02)
Weighted probability per slot. Curve shifted toward T3/T4 at high tiers:
- T1: 100% T1
- T2: 65% T1, 35% T2
- T3: 45% T1, 35% T2, 20% T3
- T4: 25% T1, 30% T2, 30% T3, 15% T4
- T5: 15% T1, 20% T2, 25% T3, 25% T4, 15% T5

Implemented via `ShopSystem._tier_thresholds(shop_tier)` (cumulative thresholds) + `_pick_tier()`.

## Level 2 Reward (design settled, not yet implemented)
Merging to level 2 grants: flat gold payout + player choice of flat stat boost (+1 base damage OR −0.5 s cooldown). Healing/armour/status deferred.

## ShopSystem.transfer() (settled 2026-06-02)
Unified movement API: `transfer(state, {zone, slot}, {zone, slot})`. Zones: "shop", "inventory", "grid". slot=-1 on `to` means first empty. Shop→inventory: straight buy, buy+level-up (same element lv1 target), or reject. All legacy functions delegate to transfer().

## Scene structure
- `scenes/screens/`: Boot, MainMenu, Settings, Shop, Battle, Compendium
- `scenes/slots/`: BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone
- `scenes/shared/`: TooltipCard, PauseOverlay

## Rendering boundary
Scene scripts: rendering + input only. Nothing in `systems/` or `data/` may reference SceneTree. All state mutations in system layer via `GameManager.state = SomeSystem.fn(GameManager.state, args)`.

## UI conventions
- **UIScale**: all font-size deviations via `UIScale.apply(node, UIScale.CONST)`. No bare integers or direct `add_theme_font_size_override()`.
- **Item Tooltip**: TooltipCard (CanvasLayer 100), 0.3s hover per slot, cursor-follow + edge-flip. Stats: Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price. Abilities Panel placeholder.
- **Battle speed/pause**: `_speed_mult` (1×/1.5×/2×) + `_paused`. All controls disabled on result.
- **Battle Summary**: fires+dmg+DPS per element both sides. Toggle below result buttons.

## Pause Menu (settled 2026-06-02)
ESC in Shop or Battle opens PauseOverlay (CanvasLayer layer=110). Options: Resume, Settings, Forfeit Run (→ eliminated → MainMenu), Quit to Main Menu, Quit to Desktop. Battle simulation pauses while overlay is open.

## Godot lifecycle rule
`_ready()` fires on `add_child()`, not `.new()`. Set plain properties before `add_child`; call child-node methods only after.

## Board + synergies (partially TBD)
Grid shape TBD (Battlegrid described as 2×2 in CONTEXT.md). Adjacency bonuses apply at setup, not during combat. Each element has own buff direction. Opponent board fully visible before fight; player can rearrange. Faction threshold synergies (N of same→bonus) + passive ability interactions as emergent synergies. Full design deferred — see `ideas.md`.

## Steam + backend seams (settled 2026-06-02)

### OpponentProvider
- Static class `systems/OpponentProvider.gd`. Seam between PhaseSystem and opponent source.
- `static func get_opponent(context: Dictionary) -> Dictionary` — returns full Ghost snapshot `{player_id, player_name, round, grid, acquired_day, source}`.
- **Ghost**: snapshot of a real player's Composition used as async opponent. Target for backend adapter.
- **Ghost Pool**: set of Ghosts available per context (day, round, shop_tier).
- Context: `{"day": int, "round": int, "shop_tier": int}`. Each round in a match gets a distinct but reproducible board via `hash(day_string + str(round_num))`.
- LocalDaySeeded: filters ElementData by `shop_tier`, seeds with hash, produces 4-element grid.
- `PhaseSystem.to_battle(state, opponent_snapshot: Dictionary) -> Dictionary` — stores snapshot as `state["opponent_snapshot"]`, reads `["grid"]` for combat. Battle.gd calls OpponentProvider first, passes snapshot in.
- Damage accumulates on both round_win AND round_loss (all combat output counts toward ACH_DAMAGE_20K).

### AchievementSystem
- Pure static `AchievementSystem.check(state, profile, event: String) → Dictionary` in `systems/`. Returns updated profile dict. No side effects inside the function.
- `event` values: `"round_win"`, `"round_loss"`, `"match_win"`, `"match_eliminated"`, `"forge_discovered"`.
- Called from scene layer (Battle.gd / Shop.gd) after `PhaseSystem.advance_round()` returns. Caller saves profile and calls PlatformLayer.
- Also merges current-match `discovered_recipes` into returned profile on every call — one call, fully updated profile back.
- First achievements: `ACH_FIRST_WIN`, `ACH_FIRST_FORGE`, `ACH_CLUTCH`, `ACH_SURVIVOR`, `ACH_DAMAGE_20K`.

### PlayerProfile
- Autoload `autoloads/PlayerProfile.gd`, persists to `user://profile.cfg`.
- Three ConfigFile sections:
  - `[stats]` — `total_damage_dealt`, `matches_played`, `matches_won`
  - `[progress]` — `achievements_unlocked` (comma-separated IDs)
  - `[discovery]` — `discovered_recipes` (comma-separated element IDs)
- Master for `discovered_recipes` — GameState gets snapshot at match start; merges back at match end.
- Save: immediate on achievement unlock; batch save at match end (victory/eliminated).
- Milestones and meta-progression fields added in a future session.

### Ghost Fixtures
- `data/GhostFixtures.gd` — one prebuilt Ghost snapshot per shop_tier (3 fixtures: tier 1, 2, 3). Serve as unit test fixtures AND deterministic fallback if day-seeded generation fails. Each fixture is a valid Ghost snapshot dict with `source: "fixture"`.

### PlatformLayer autoload (identified, not yet built)
- Isolates GodotSteam. SteamAdapter (desktop) / NoOpAdapter (web). Required — GodotSteam needs custom engine build, incompatible with web export.

### Opponent Snapshot in GameState (identified, not yet built)
- Collapse flat opponent fields → `state["opponent_snapshot"] = {player_id, player_name, round, grid, source, acquired_day}`.

## Deferred / TBD
Full brainstorm backlog lives in `.claude/ai-helper/ideas.md`. Key items with near-term implementation implications:

- T2 cross-recipe expansion for Lightning, Nature, Light, Dark, Metal, Sound (6 T1s with no cross-combos yet)
- Damage types and status effects as element passives — see `.claude/ai-helper/elements-reference.html`
- Open-ended forging as discovery mechanic — see `.claude/ai-helper/elements-reference.html`
- Level 2 Reward implementation (design settled above)
- Ability Chain combat (real, not placeholder — major chunk)
- Innate Ability + Replay token economy
- Merge mechanic: 3× same → upgrade (distinct from the current 2-copy level-up; not yet implemented)
- Faction synergy system + grid adjacency logic
- Draft system (Items / Trinkets as separate from Elements)
- Meta-progression shape — dedicated session needed
- PlatformLayer autoload (SteamAdapter / NoOpAdapter)
