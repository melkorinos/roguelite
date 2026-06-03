# Memory — Settled Design Decisions

## Core identity
Auto-battler. Build synergies, break the system, lose to your exact counter, master meta over dozens of sessions. Insps: Super Auto Pets, HBG, The Bazaar, Dota Auto Chess. Steam desktop, async PvP, 20–30 min sessions. Visual: clean, minimal, weird, surreal.

## Entity + state model
Plain data objects + standalone static fns. No class inheritance. Systems take `GameState` dict, return new dict — no mutation. `GameManager.state` global. `GameState.create()` in `data/GameState.gd`.

## Feature flags (`data/FeatureFlags.gd`)
Static class with one `static var` per design experiment, all `false` by default. Use `static var` (not `const`) so flags can be flipped at runtime from a debug console or dev menu without reloading.
Check at any code boundary before activating deferred behaviour: `if FeatureFlags.status_effects: ...`
- `status_effects` — Burn/Poison/Heal/Slow/Blind etc. on elements
- `hidden_recipes` — forge recipes hidden until discovered (Compendium unlock)
- `efficiency_scoring` — dev-only balance score printed to output panel
- `ability_chain` — real Ability Chain combat (replaces placeholder tick loop)
- `innate_ability` — player Innate Ability + Replay token mechanic

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

## Element system (67 elements, 55 recipes, 3 tiers)
- **T1 (12, 5g):** Water 💧 Cleanse, Fire 🔥 Burn, Air 🌬️ Haste, Earth 🌍 Armor, Lightning ⚡ Shock, Nature 🌿 Heal, Light ☀️ Blind, Dark 🌑 Curse, Metal ⚙️ Plating, Fungus 🍄 Poison, Blood 🩸 Leech, Frost 🌨️ Weaken. **Sound retired** → replaced by Fungus.
- **T2 cross original (6, 8g):** Steam, Rain, Mud, Smoke, Lava, Dust — Water/Fire/Air/Earth pairs only
- **T2 cross extended (24, 8g):** Lightning/Nature/Light/Dark/Metal/Fungus × {Water, Fire, Air, Earth}
  - Lightning: Surge 💫, Arc 🌠, Static 💠, Lodestone 🧲
  - Nature: Bloom 🌸, Ember 🪵, Pollen 🌼, Root 🌱
  - Light: Prism 💎, Solar 🌞, Aurora 🌌, Crystal 🔮
  - Dark: Abyss 🌊, Blight 🥀, Miasma ☣️, Shade 🌘
  - Metal: Rust 🟤, Molten 🔶, Shrapnel 💥, Ore ⛏️
  - Fungus: Sonar 📡, Resonance 〰️, Howl 🐺, Tremor 🫨 *(names pending rename)*
- **T2 self (10, 8g):** Ice, Blaze, Gale, Boulder, Plasma, Forest, Radiance, Void, Steel, Echo. Blood+Frost self-combos deferred.
- **No T2 combos yet for Blood 🩸 or Frost 🌨️**
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

## Status Effects system (implemented 2026-06-03, gated by FeatureFlags.status_effects)

### Vocabulary
- **Effect**: the passive string field on an element dict (`"effect": "burn"`). Fires on cooldown expiry.
- **Status**: ongoing condition tracked in `player_statuses`/`opponent_statuses` on GameState. Flat dict, one pool per side (not per-element).

### State shape (in GameState)
`player_statuses` and `opponent_statuses` — both initialised via `StatusSystem.empty_statuses()`. Reset in `PhaseSystem.to_battle()`. Also `status_tick_timer: float` for 1-second tick clock.

### T1 effect mechanics
| Effect | Mechanic |
|---|---|
| burn | stacks += 1; tick: deal stacks dmg (decrements), armor absorbs at half rate (floor(stacks/2)) |
| poison | stacks += 1; tick: deal stacks dmg; **stacks never decrease, no expiry** |
| armor | value += 1; absorbs physical dmg fully before HP; depletes on hit |
| plating | value += 0.1; flat reduction to ALL incoming dmg (floor); never depletes |
| blind | pct += 0.15; cap 0.50; on fire: roll — if miss, deal 0 dmg and skip effect |
| shock | n += 1; opponent CDs × (1 + slow_pct(n)/100); formula: 50n/(n+5), asymptotes at 50% |
| heal | instant +1 HP to own side |
| cleanse | instant: remove 1 stack from each debuff on own side (burn/poison/shock/slow/weaken/blind) |
| curse | ticks = 3 (refresh on reapply); while active: burn+poison deal +1 per tick |
| plating | see above |
| leech | instant: heal own HP equal to dmg dealt |
| weaken | stacks += 1, ticks = 3 (refresh); tick: ticks−=1, expire at 0; stacks stay; reduces attacker dmg by stacks (only while ticks > 0) |

### StatusSystem API (`systems/StatusSystem.gd`)
- `empty_statuses() -> Dictionary`
- `apply_effect(statuses, effect) -> { statuses, hp_delta }` — hp_delta non-zero for heal/leech
- `tick(statuses) -> { statuses, damage }` — 1s tick, returns HP damage
- `compute_incoming_damage(raw, attacker_statuses, defender_statuses) -> { damage, defender_statuses }` — weaken→plating→armor pipeline
- `slow_pct(n) -> float` — `50n/(n+5)`, shared by shock and slow

### BattleSystem integration
Effects fire via `_apply_element_effect(s, effect, is_player_side, timers, dmg_dealt)`. Haste immediately reduces own timers by 0.3s per application. Blind uses `randf()` for miss roll. Status tick uses `while tick_acc >= 1.0` loop.

### Design decisions
- Unified model: damage type = effect identity (no separate base damage type layer)
- All statuses apply to the player side total, not per-element
- Poison is permanent (never expires); all other timed effects use ticks_remaining
- Feature flag `FeatureFlags.status_effects` gates all paths; existing behavior unchanged when false

## Deferred / TBD
Full brainstorm backlog lives in `.claude/ai-helper/ideas.md`. Key items with near-term implementation implications:

- T2 cross-recipe expansion for Blood + Frost (no T2 combos yet); Fungus T2 names need rename
- Damage types and status effects — T1 implemented; T2 effects + T3 inheritance TBD
- Open-ended forging as discovery mechanic (see ideas.md)
- Level 2 Reward implementation (design settled above)
- Ability Chain combat (real, not placeholder — major chunk)
- Innate Ability + Replay token economy
- Merge mechanic: 3× same → upgrade (distinct from the current 2-copy level-up; not yet implemented)
- Faction synergy system + grid adjacency logic
- Draft system (Items / Trinkets as separate from Elements)
- Meta-progression shape — dedicated session needed
- PlatformLayer autoload (SteamAdapter / NoOpAdapter)
