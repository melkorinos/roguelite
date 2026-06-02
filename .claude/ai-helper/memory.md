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

## Rendering boundary
Scene scripts (`.gd` attached to `.tscn` files) handle rendering and input only. Logic in system scripts must never reference scene nodes or the Godot SceneTree. Equivalent to the former Phaser-only-in-scenes rule.

## Shop phase feel
Creative expression with soft pressure. Gold is generous enough to experiment; pressure comes from opponents improving, not from scarcity. Players should feel clever, not stressed. Reroll should be usable without feeling punishing.

## Win / loss feel
All three layers simultaneously: (1) Engineered — I can see exactly why I won/lost, the chain log confirms my plan; (2) Spectacular — the Ability Chain is a visible show, effects cascade; (3) Clinical — the result screen is a debrief with margin and opponent breakdown. None of the three is primary; all inform the result screen and combat presentation design.

## Meta-progression shape
Uncertain — deferred. Do not commit to unlock-gated content vs cosmetic-only vs XP track until a dedicated design session.

## Element system
- **4 base elements**: Water, Fire, Air, Earth (tier 1, cost 5g each)
- **Leveling**: drag same element onto same element at same level → level + 1 (needs confirmation dialog). Requires matching levels.
- **Forging**: done at the forge bench (dedicated UI area), not directly on the board. Two different elements → check recipe → produce result element (tier 2+). Recipe is revealed on first forge; goes into discovered recipe list. Unknown combos show "→ ???", known combos show result name.
- **~60 pre-computed recipes** planned; prototype ships 6 (all pairings of 4 basics: Steam, Rain, Mud, Smoke, Lava, Dust).
- **Tiers**: tier 1 = basics, tier 2+ = combinations. Shop raises available tier as the run progresses. Discovered recipes only appear in shop if their tier requirement is met.
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

## Platform and business model
Steam desktop. Async multiplayer. Target session: 20–30 minutes.
Business model: Free to play initially → eventually paid once. Gameplay unlocks (Factions, Synergies) through meta-progression.

## Visual identity
Clean, minimal, weird, surreal. Not cute, not grimdark.

## Simulation model
Real-time but deterministic. Discrete ticks simulate all element cooldowns simultaneously. RNG (if any) is seeded at combat start so the full fight is reproducible and replayable. Visual presentation is a playback of the pre-computed event log.
