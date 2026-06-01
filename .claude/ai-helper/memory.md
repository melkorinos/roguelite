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

## Primary play object
Undefined — three open scenarios:
- **A (Menagerie)**: 6 unit slots; each unit equips 1 item; items have trinket slots.
- **B (Single character, PoE-inspired)**: 1 character equips 6 items; items have gem/trinket slots; character stats derive entirely from items.
- **C (Items as fighters)**: items are the combatants directly; no separate character or unit concept.
Resolve before Sprint 1 coding begins.

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

## Primary play object
Still open between Scenario A (Menagerie: units + items) and Scenario B (single character, items as build). Scenario C (items as fighters) is not ruled out but ranked lowest. Do not architect around any one model until resolved.

## Toolchain
Godot 4 + GDScript. TypeScript / Vite / pnpm / Phaser 3 scaffold is kept as reference only — to be deleted once the Godot port is verified.
Needs added eventually: Steam packaging (Godot export), backend (async PvP state, user accounts).

## Platform and business model
Steam desktop. Async multiplayer. Target session: 20–30 minutes.
Business model: Free to play initially → eventually paid once. Gameplay unlocks (Factions, Synergies) through meta-progression.

## Visual identity
Clean, minimal, weird, surreal. Not cute, not grimdark.

## Simulation model
Ability Chain resolution is turn-based / discrete (deterministic, fully testable). Visual presentation can be animated — those are separate concerns.
