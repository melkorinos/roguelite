# Memory — Settled Design Decisions

Decisions recorded here are stable enough to build on but may still change.

## Genre
Auto-battler with ability-chain combat. Inspirations: Super Auto Pets, Hearthstone Battlegrounds, The Bazaar, Dota Auto Chess.

## Entity model
Plain data objects + standalone system functions. No class inheritance for game entities.
Systems take `GameState`, return `GameState`. No mutation.

## Game state
Single `GameState` object (`src/data/types.ts`) passed explicitly into every system call.
No global singletons for now — revisit if passing state becomes unwieldy.

## Combat model
Ability Chain: each piece has an Ability that triggers during combat. Abilities activate in a sequence determined by piece properties; interactions between them produce emergent outcomes. No positional targeting — the whole Composition acts as one system against the opponent's.

Player has one Innate Ability per combat, triggered once at a chosen moment. This is the primary player action during the combat phase.

Both sides have a single Player HP bar. There is no unit-vs-unit HP tracking during combat — damage flows directly to the player.

## Damage and elimination
Losing a combat round deals proportional damage to Player HP (GeoGuessr-style: margin-based, with a floor of 1). Player is eliminated when HP reaches zero. No instant loss on a single round defeat.

## Replay mechanic
After a lost combat, the player can spend a Replay token to rewatch and retrigger the fight once, this time firing their Innate Ability at a different moment. The new result replaces the original. Tokens are a finite per-match resource.

## Round structure
Mixed PvE and PvP rounds. PvE on a fixed schedule with some randomization to prevent cheesing. All 8 players fight the same PvE encounter. PvE rounds are the primary source of Trinkets. PvP rounds deal Player HP damage.

## Match structure
8 players per match. Last player standing wins. Players begin with a full HP pool.

## Shop phase loop (confirmed prototype shape)
Player arrives at the Shop → buys pieces with Gold and rerolls → drafts Items/Trinkets free → optionally Merges or Forges → clicks Fight to start the combat phase.

## Upgrade mechanics
- **Merge** (primary): 3 identical pieces at the same level → 1 upgraded version. Auto-triggers on purchase.
- **Forge** (secondary): A + B → C, recipe-based, costs 2 Gold during shop phase, produces a new piece with a different identity.

## Economy
Two tracks per round:
- **Gold shop**: rotating 4 pieces; spend Gold to buy; reroll costs 1 Gold.
- **Draft**: free selection of Items/Trinkets each round.

## Rarity system
~30 pieces at launch. Tiers: Common, Rare, Epic. Rarity determines shop appearance frequency. More detail TBD.

## Faction and synergy system
Two sources of Synergy:
1. **Faction threshold**: N pieces of the same Faction (e.g. 3 Orcs) activate a bonus for all pieces of that Faction.
2. **Passive ability interactions**: specific piece abilities interact with other piece abilities, producing emergent Synergies.

## Primary play object — SETTLED: Scenario C (Elements as fighters)
Elements are the combatants directly. No separate unit or character concept. Players fill a grid board with elements; the board fights the opponent's board. Elements have individual cooldown timers and damage values. Adjacency on the grid determines buffing relationships (not targeting — combat always fires at the opponent's HP bar like Super Auto Pets).

## Meta-progression
Light progression between matches. Unlocks new Factions, Synergies, and game-changing milestones. The player's theoretical maximum slowly rises over sessions. Unlock economy TBD.

## Optional: PvE Bosses
Damage or defence check encounters. Beating a Boss unlocks a milestone (new Faction, Synergy, or global modifier). Not committed; noted as a strong option.

## Scene folder structure (settled 2026-06-02)
- `scenes/screens/` — full-screen scenes (Boot, MainMenu, Settings, Shop, Battle, Compendium)
- `scenes/slots/` — reusable tile/slot nodes (BattleSlot, ForgeSlot, InventorySlot, ShopItemTile, SellZone)
- `scenes/shared/` — cross-scene UI components (TooltipCard)

## Item Tooltip (settled 2026-06-02)
`scenes/shared/TooltipCard.gd` — CanvasLayer (layer=100), follows cursor (flip left at screen edge). Two sections: stats (Tier, Level, Cooldown, Base Dmg, Eff. Dmg, Price) + Abilities Panel placeholder. Triggered by a 0.3s hover Timer inside each slot node (`BattleSlot`, `ShopItemTile`, `InventorySlot`, `ForgeSlot`). Slots emit `tooltip_requested(element)` / `tooltip_hide_requested()`; parent scenes call `_tooltip.show_for()` / `hide_card()`. Active in Shop (all slot types) and Battle (both player + opponent grids).

## Battle speed and pause (settled 2026-06-02)
`_speed_mult: float` (1.0/1.5/2.0) multiplies delta in `tick_battle`. `_paused: bool` short-circuits `_process` entirely — freezes simulation, progress bars, timer display, fire animations. ControlsRow (Pause + 1× 1.5× 2× buttons) sits near the top of the Battle scene; all controls disabled once result phase is reached.

## Rendering boundary
Scene scripts (`.gd` attached to `.tscn` files) handle rendering and input only. Logic in system scripts must never reference scene nodes or the Godot SceneTree. Equivalent to the former Phaser-only-in-scenes rule.

All state transformations during the shop phase — including inventory↔grid swaps (`ShopSystem.swap_inv_to_grid`, `swap_grid_to_inv`, `swap_within_grid`) and forge-bench placement (`ForgeSystem.move_to_forge_slot`, `forge_quick_slot`, `remove_from_forge_slot`) — live in the system layer. Scene scripts only dispatch to those functions.

## Font size constants — UIScale (settled 2026-06-02)
All font-size deviations from the project default live in `data/UIScale.gd`. Scene scripts call `UIScale.apply(node, UIScale.SOME_CONST)`. Direct `add_theme_font_size_override()` calls and bare integers are banned in scene scripts. The `apply()` wrapper creates the seam to migrate to Godot Theme type variations later without touching call sites.

## Godot node lifecycle — set_element / child-node access
`_ready()` fires on `add_child()`, not on `.new()`. Never call a method that reads or writes child node properties (labels, progress bars, etc.) before the node has been added to the scene tree. Safe before `add_child`: plain property assignment (`slot_index`, `draggable`), signal connections. Unsafe: anything that touches nodes built inside `_ready()`. Fix: call `add_child(node)` first, then call the method.

## Shop phase feel
Creative expression with soft pressure. Gold is generous enough to experiment; pressure comes from opponents improving, not from scarcity. Players should feel clever, not stressed. Reroll should be usable without feeling punishing.

## Win / loss feel
All three layers simultaneously: (1) Engineered — I can see exactly why I won/lost, the chain log confirms my plan; (2) Spectacular — the Ability Chain is a visible show, effects cascade; (3) Clinical — the result screen is a debrief with margin and opponent breakdown. None of the three is primary; all inform the result screen and combat presentation design.

## Meta-progression shape
Uncertain — deferred. Do not commit to unlock-gated content vs cosmetic-only vs XP track until a dedicated design session.

## Shop UX model (updated 2026-06-02)
- **Sell**: drag inventory item OR Battlegrid element to SellZone — half-price refund
- **Level up**: drag inventory item onto same-element, same-level slot — hard reject if levels differ
- **Forge**: drag inventory items to ForgeSlot bench (2 slots, right panel) — auto-forges on 2nd drop; F-key quick-forge; replaces slot 2 if both full
- **Buy (click)**: click ShopItemTile → first free inventory slot
- **Buy (drag to empty slot)**: drag ShopItemTile onto empty inventory slot → buys into that slot, no dialog
- **Buy + level-up (drag)**: drag ShopItemTile onto matching Lv1 inventory item → ConfirmationDialog
- **Undo**: 1-action; GameManager.save_undo()/apply_undo(); Undo button (TopBar) + Ctrl+Z
- **Drag hints**: SellZone highlights on drag start (inventory or Battlegrid); matching inventory slots turn green
- **Shop grid**: fixed 6 slots; bought items show greyed-out "SOLD" placeholder (position-stable across purchases)

## Battle Summary (settled 2026-06-02)
Shown inline below result buttons via "📊 Summary" toggle. Displays fires count, total damage, and DPS per element for both player and opponent. Data accumulated in `battle_stats` (GameState) by `BattleSystem.tick_battle`. Embodies the "Clinical" win/loss feel.

## Stats formula (settled 2026-06-02)
- `effective_damage = base_damage × level + tier` — universal (level-up and forge results)
- Cooldown: not scaled yet (deferred)
- Forge result level: `min(level_a, level_b)` — warning shown on mismatch
- Implemented in `ElementData.effective_damage(item)`, computed dynamically (not stored)

## Element system
- **4 base elements**: Water, Fire, Air, Earth (tier 1, cost 5g each)
- **Leveling**: drag same element onto same element at same level → level + 1. Requires matching levels. Works for any element that has no self-combo recipe.
- **Forging**: done at the forge bench (dedicated UI area). Any two elements → check recipe → produce result element. Self-combos (water+water, fire+fire, air+air, earth+earth) are valid forge recipes that produce tier-2 results. Recipe is revealed on first forge; goes into discovered recipe list. Unknown combos show "→ ???", known combos show result name.
- **Two upgrade mechanisms**: (1) Level up — same element × 2 at same level → level+1, no recipe needed; (2) Forge — two elements (same or different) with a recipe → new element identity at level 1.
- **Scope (prototype)**: 3 tiers, 29 elements, 25 recipes. Tiers 4 and 5 removed for now.
  - Tier 1 (4): Water, Fire, Air, Earth
  - Tier 2 cross (6): Steam, Rain, Mud, Smoke, Lava, Dust
  - Tier 2 self (4): Ice (W+W), Blaze (F+F), Gale (A+A), Boulder (E+E)
  - Tier 3 (15): Cloud, Geyser, Fog, Rainbow, Storm, Plant, Swamp, Brick, Ash, Acid, Obsidian, Volcano, Sand, Sandstorm, Clay
- **Discovery**: all recipes currently fully visible. Future plan: shadow undiscovered recipes (show "→ ???"); use `discovered_recipes` array in GameState which already tracks this.
- **Inventory (backpack)**: 6 slots. Starts small, may expand over the run — TBD.

## Combat model (updated)
Real-time but deterministic. Each element has a cooldown timer; when it fires it deals damage to the opponent's HP bar. Ties (same-tick firings) are resolved by grid position (top-left first). Simulation runs discrete ticks; result is computed upfront and played back visually. Replay mechanic is preserved.

## Board / grid
Simple grid. Shape TBD. Adjacency bonuses apply at board setup (not during combat). Each element has its own buff direction — some broadcast to neighbours, some receive from neighbours, some both. Opposition board is revealed before battle so the player can arrange their grid strategically.

## Opponent board visibility
Full visibility before battle starts. Player can rearrange their grid after seeing the opponent.

## Trinkets
Passive bonuses that last the whole run (e.g. "+5 gold on win"). No combat-phase cooldowns at current scope. Primary source: PvE rounds.

## Starting run decision (Identity pick)
One choice per run — "I am playing Water this run." Flavour + mechanical angle. Exact bonuses TBD. May buff the chosen element family and its crafted descendants. Do not architect around a specific mechanism until a dedicated design session.

## Toolchain
Godot 4 + GDScript. TypeScript / Vite / pnpm / Phaser 3 scaffold is kept as reference only — to be deleted once the Godot port is verified.
Needs added eventually: Steam packaging (Godot export), backend (async PvP state, user accounts).

## Steam + backend architecture (settled 2026-06-02)
Five seams identified in architecture review (`docs/reviews/architecture-review-20260602.html`):

1. **OpponentProvider** — extract `BattleSystem.create_opponent_grid` behind a seam. `LocalDaySeededAdapter` (day-seeded RNG, same opponent per calendar day for all players) ships first; `BackendHTTPAdapter` slots in later without touching PhaseSystem or BattleSystem.
2. **AchievementSystem** — pure static `check(state, profile)` called by `PhaseSystem.advance_round()` after state update. Reads win/loss/forge events, updates PlayerProfile, calls PlatformLayer. Covers both Steam achievements and internal milestones.
3. **PlayerProfile autoload** — cross-match persistence to `user://profile.cfg` (follows SettingsManager pattern). Fields: `total_damage`, `matches_won`, `achievements[]`, `milestones{}`, `discovered_recipes[]`. Steam Cloud Save is a future adapter behind the same seam.
4. **PlatformLayer autoload** — isolates GodotSteam from all game code. Detects platform; delegates to SteamAdapter on desktop, NoOpAdapter on web. Required because GodotSteam needs a custom engine build incompatible with web export.
5. **Opponent Snapshot shape** — collapse flat `opponent_grid/hp/timers` fields into one `opponent_snapshot` dict with `player_id`, `player_name`, `grid`, `source ("local"|"remote")`, `acquired_day`.

All five can be built with no backend. Backend unlocks only the `BackendHTTPAdapter` and player accounts.

## Internal Milestones (feature planned, not in scope until dedicated session)
Milestones are in-game achievements that surface inside the meta-progression layer (unlock Factions, Synergies, run modifiers) — e.g. "deal 20,000 total damage." They are separate from Steam achievements but share the same AchievementSystem + PlayerProfile infrastructure. Build the seam once, wire both outputs. Do not design milestone rewards until a dedicated design session.

## Platform and business model
Steam desktop. Async multiplayer. Target session: 20–30 minutes.
Business model: Free to play initially → eventually paid once. Gameplay unlocks (Factions, Synergies) through meta-progression.

## Visual identity
Clean, minimal, weird, surreal. Not cute, not grimdark.

## Simulation model
Real-time but deterministic. Discrete ticks simulate all element cooldowns simultaneously. RNG (if any) is seeded at combat start so the full fight is reproducible and replayable. Visual presentation is a playback of the pre-computed event log.

## Match persistence — Lives system (settled 2026-06-02)
- **Player HP**: in-battle only. Resets to full (30) at start of every battle via `to_battle()`. Does NOT persist across rounds.
- **Lives**: match-level resource, starts at 10. Lost 1–3 per defeat. Reaching 0 = eliminated.
  - Hard loss (opponent HP remaining ≥ 70% of `opponent_starting_hp`) → –3 Lives
  - Medium loss (30–70%) → –2 Lives
  - Close loss (<30%) → –1 Life
  - Draw = player win (opponent is async), 0 Lives lost
- **Win condition**: 10 wins ends the match immediately (victory screen, then Main Menu). Endgame/infinite session deferred to a future session.
- **Elimination**: 0 Lives → eliminated screen, then Main Menu.
- **Gold income**: +5 gold at start of each Shop phase (added in `advance_round()`). No streak/interest mechanic yet.
- **State fields added**: `lives: int = 10`, `wins: int = 0`, `opponent_starting_hp: int` (set in `to_battle()`).
- **`advance_round()` responsibilities**: calculate Lives lost (if loss), increment wins (if win/draw), add 5 gold, reset Player HP via `to_battle()` eventually, set phase. Does NOT reset Player HP directly — that happens in `to_battle()`.
- **Display**: Lives and wins shown in both Shop and Battle HUDs.
- **Result screen**: simple inline text ("YOU WIN — 10 rounds" / "ELIMINATED — X wins, round N"), reuses Battle result flow, no new scene.
