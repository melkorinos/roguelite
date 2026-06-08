# Auto-Battler

A game where players collect, Merge, and Forge elements into synergistic boards that fight asynchronously against other players and shared PvE encounters.

> **Note — vocabulary in transition.** The earlier extraction-roguelite terms (Zone, Extraction, Scavenge) are retired.

## Language

### Core mechanics

**Merge**:
Combining two identical elements at the same level to produce one element of level+1. This is the live mechanic in the codebase. Drag-drop; no recipe needed.
_Avoid_: level up, fuse, evolve, combine

**Forge**:
Combining two specific elements (A + B → C) via a recipe to produce a new element one Tier up. Both inputs must be at **Level 2 or higher** — you Merge up before you Forge, coupling the Level and Tier axes — and the result comes out **one Level below its inputs** (two Level-2s → a Level-1 of the next Tier). An intentional trip to the Forge bench; gold-free today (a cost knob is reserved for tuning). The rare, exciting upgrade path. See `docs/adr/0008`.
_Avoid_: craft, fuse, combine (too generic — Forge is a specific action)

### Pieces and equipment

**Element** *(current prototype term)*:
The core piece in the current codebase. Bought from the gold shop, placed on the Board, and fires damage during the combat phase. Defined in `ElementData.gd`. In the longer-term design, Elements will split into Units (fighters) and Items (passives on Units), but for the prototype they are unified.
_Avoid_: card, item, unit (until the split is implemented)

**Unit** *(future)*:
A piece that occupies a board slot and participates directly in combat. Acquired via the gold shop. Can have passive Abilities. Currently unified with Element in the prototype.
_Avoid_: card, character, creature, minion

**Item**:
A collectable piece with passive Abilities that can attach to a Unit or exist independently. Acquired via draft. Can be taken to the Forge.
_Avoid_: gear, weapon, equipment (too narrow — Items include all non-Unit equippables)

**Trinket**:
A small modifier that slots into an Item or Unit to fine-tune its behaviour. Acquired via draft. Not a standalone fighter.
_Avoid_: relic, charm, gem (until a canonical term is chosen)

**Level 2 Reward**:
A bonus granted when an element reaches level 2 through a Merge. Provides a flat gold payout plus a player-chosen flat stat boost (+1 base damage or −0.5 s cooldown). Healing, armour, and status effects are deferred to a later design session.
_Avoid_: merge bonus, upgrade reward

### Build and combat

**Board** (canonical term):
The full set of elements a player fields during a Run. Position matters for **adjacency_upgrade** Abilities (which react only to an orthogonally-adjacent source while `FeatureFlags.combat_adjacency` is on); broader Faction/adjacency synergies are still planned.
_Avoid_: composition, loadout, lineup, deck

**Synergy**:
An emergent beneficial interaction between two or more pieces in a Board. Triggered either by Faction thresholds or by passive Ability interactions between specific pieces.
_Avoid_: combo, interaction, effect (too generic)

**Faction** *(future, not yet in game)*:
A category tag on a piece (e.g. Orc, Rogue, Construct). Reaching a threshold count of the same Faction in a Board activates a bonus for all pieces of that Faction.
_Avoid_: tribe, class, race, type

**Run**:
A complete play session consisting of multiple rounds. Players begin with full Life and are eliminated when Life reaches zero.
_Avoid_: match, game, session

**Round**:
One iteration of the shop phase followed by a combat phase. Rounds are either PvP or PvE.
_Avoid_: turn, wave

**PvE Round**:
A Round where all players fight a shared encounter (same enemy wave). Occurs on a fixed, predictable schedule with some randomisation to prevent cheesing. Primary source of Trinkets.
_Avoid_: event round, boss round (unless a specific boss encounter is designed)

**PvP Round**:
A Round where a player's Board fights an opponent's Board asynchronously. Losing deals Life damage proportional to the margin of loss.
_Avoid_: battle round, fight round

**Player HP**:
The in-battle resource representing how much damage a player's side can absorb before losing that Round. Recomputed at the start of every battle and **scales with the round** plus any reward bonus: `BASE_PLAYER_HP + (round−1)×HP_PER_ROUND + hp_bonus` (`hp_bonus` is a persistent run modifier granted by rewards). Tuning values live in `data/TuningData.gd`.
_Avoid_: health, hearts

**Life**:
The Run-level resource that tracks how close a player is to elimination. Starts at 100. Lost per defeat **proportionally to the margin** — `round(opponent_HP_remaining_ratio × MAX_LIFE_LOSS)` — so a blowout costs the full `MAX_LIFE_LOSS` and a razor-thin loss costs almost nothing (no floor). A draw counts as a player win (opponent is async). Reaching 0 Life eliminates the player. The Run goal is `WIN_THRESHOLD` wins before Life runs out. (Tuning values live in `data/TuningData.gd`.)
_Avoid_: health, HP, hearts, lives

### Actions and statuses

**Action**:
The effect an Element triggers automatically each time its cooldown expires. Every T1 Element has exactly one Action. Actions either apply a Status on the opponent side, modify the player's own side, or trigger instantly (Heal, Cleanse, Leech). *(Code field currently named `"effect"` — rename pending.)*
_Avoid_: ability (reserved for the Ability system), passive, on-hit

**Status**:
An ongoing condition tracked as a flat dictionary on one player's side, not per-element. A Status has numeric state (stacks, ticks_remaining, value) read and written by StatusSystem. All Elements on one side share the same Status pool.
_Avoid_: buff/debuff (too generic), action, effect

### Abilities and combat

**Ability**:
A richer triggered effect on a piece — distinct from an Action in that it can interact with other Abilities, buff allied pieces, apply complex status chains, or reward economic outcomes. Will replace or extend Actions once the Ability system is built.
_Avoid_: attack, skill, power (too generic)

Early examples:
| Example | Trigger type |
|---|---|
| +1 gold per X gold-cost element on Board, post-combat | Economic reward |
| Adjacent fire elements get +burn | Board-setup aura |
| Dispel 50% of current debuffs | Reactive / on-event |
| Freeze one random opponent element every X secs | Periodic active during combat |
| Disable one random T2 opponent element at combat start | Combat-start targeted debuff |
| Bonus damage for each fire element on Board | Passive scaling modifier |
| Decrease cooldown for earth-related elements | Setup passive modifier |

**Trigger**:
The condition that activates an Ability: `combat_start` (once at battle begin), `periodic` (every N deciseconds), `passive` (always-on modifier queried at the relevant calculation site), `on_activate` (each time the element fires — the Ability-tier sibling of the single-status Action; carries a compound effects list and an optional **every Nth activation** gate), or a reactive `on_*` event (e.g. `on_burn_applied`, `on_leech`).
_Avoid_: hook, event handler, condition

**Every Nth Activation**:
A deterministic gate on an `on_activate` Ability (`every_n`) that fires its effects only on every Nth time the element activates, counted from the element's running fire tally. Chosen over a per-hit random chance so combat stays reproducible (the basis for Replay). E.g. Shrapnel applies `[shock]` every 3rd activation.
_Avoid_: proc, chance, RNG roll

**Reactive Trigger**:
A Trigger that fires in response to an in-combat event emitted by another piece. Bound by the **depth-1 rule**: a reactively-activated Ability may deal damage and apply Statuses, but its own output emits no further reactive events, and it never Multicasts. Caps every synergy chain at one hop.
_Avoid_: chain trigger, cascade

**Combat Event**:
A record emitted during a combat tick that Reactive Triggers respond to. Two shapes, built by `AbilitySystem` factories: a **fire event** (a piece fired — carries side, slot, damage, effect; also rendered by the Battle view) and a **trigger event** (a typed signal such as a Status ticking, Armour being stripped, or Haste applied — carries a trigger name and side, optionally a source slot; never rendered). Only fire events are stored in `battle_events`.
_Avoid_: signal, message, log entry

**Multicast**:
An Ability property that repeats a piece's full cooldown fire (damage + on-fire effects) N times in one cooldown — capped 2× at Tier 2/3, 3× at Tier 4. Each repeat is an independent Reactive Trigger.
_Avoid_: double-cast, repeat, echo (Echo is a distinct, deferred concept)

**Freeze**:
A per-slot combat state (not a side-wide Status) that makes one element's slot skip its fire for a duration. Tracked separately from StatusSystem, cleansable, and target selection avoids re-freezing the most-recently-frozen occupied slot.
_Avoid_: stun, stop, disable

**Decisecond**:
The integer time unit for all combat design values — one tenth of a second. A 2.5-second cooldown is stored as 25 deciseconds. No combat design value is a decimal. Effective cooldown is floored at 10 deciseconds (one fire per second).
_Avoid_: tick (reserved for the 1-second Status tick), ms, frame

**Ability Chain** *(planned, not yet implemented)*:
The future combat model where Ability activations resolve in a meaningful sequence, with interactions between pieces producing emergent outcomes. Currently deferred — the live model uses individual element cooldown timers.
_Avoid_: combat sequence, turn order, resolution

**Innate Ability**:
A player-owned ability, separate from their pieces, that can be triggered once per combat at a chosen moment. The primary player action during the combat phase.
_Avoid_: hero power, active skill, special move

**Replay**:
A mechanic allowing the player to rewatch a lost combat and retrigger it once with their Innate Ability fired at a different moment. Consumes one Replay token. Available only after a loss.
_Avoid_: undo, time rewind

### UI zones

**Battlegrid**:
The arrangement zone inside the Shop UI where the player positions their elements before clicking Fight. Elements placed here fight in the combat phase. *(Grid size — 2×2 / 2×3 / 3×3 — is undecided; the combat backend is grid-size-agnostic, deriving size from the slot array and using an orthogonal-neighbor helper for adjacency.)*
_Avoid_: board, bench, lineup

**Charge Bar**:
The thin bar on each Battle slot that fills 0→1 as an element charges toward its next fire, then resets when it fires. Driven by the element's cooldown; rendered smoothly by interpolating between the fixed combat steps. Empty while the slot is frozen.
_Avoid_: cooldown bar, progress bar, loading bar

**Battle Summary**:
A per-element debrief shown inline at the end of a combat phase. Shows fires count, total damage dealt, and DPS for each element on both sides. Embodies the "Clinical" win/loss feel goal.
_Avoid_: combat log, result screen, debrief

### Economy

**Gold**:
The currency spent in the shop phase to buy elements and reroll the shop. Not used for the draft. Reroll cost escalates within a shop phase (+1 per paid reroll) and resets each round.
_Avoid_: coins, money

**Run Discovery**:
An element the player has **Forged** during the current Run, recorded in `run_discoveries`. The set of Run Discoveries gates which tiers the Shop offers (forge 3 distinct T2 / 2 distinct T3 / 1 T4 to unlock that tier) and filters them to the player's Families. Distinct from the persistent cross-run discovery record (`discovered_recipes`). See `docs/adr/0007`.
_Avoid_: unlock, recipe (a recipe is the A+B→C rule; a discovery is the forged result)

**Family**:
All elements sharing a Tier-1 ingredient — a build archetype (e.g. the Lightning family). Once a tier unlocks, the Shop offers that tier's elements only from Families the player has Forged with. T1 stays the full pool (exploration + forge fuel).
_Avoid_: tribe, type — and **not** Faction (the separate, future threshold-synergy concept)

**Starting Pick**:
A once-per-Run choice at the start of round 1: three Tier-1 elements are offered and the chosen one is granted to the player with doubled base damage.
_Avoid_: draft (Draft is the separate free Item/Trinket selection)

**Draft**:
The free selection of Items and Trinkets offered each round. Separate from the gold shop.
_Avoid_: pick phase, card draw

**Rarity**:
A tier assigned to each piece that determines how frequently it appears in the shop. Working tiers: Common, Rare, Epic. *(Note: the codebase currently uses numeric Tier 1/2/3 — the named rarity vocabulary is aspirational and not yet reflected in code.)*
_Avoid_: grade, quality — "tier" is acceptable shorthand

### UI overlays

**Element Card**:
The permanent UI tile that represents one element in a Board slot, inventory slot, or shop row. Always visible — no hover required. Portrait layout: icon area top-center; Tier badge top-right; three stats (Cooldown, Base Dmg, Eff. Dmg) in a row below the icon; Abilities Panel spanning the full width at the bottom; Price badge bottom-right. Level is conveyed through background color saturation rather than a numeric label. Identical layout in shop, inventory, and Battlegrid contexts.
_Avoid_: item card, slot tile, info card, hover card

**Item Tooltip**:
A floating overlay that appears on hover during the active battle phase only. Repurposed from the old stats-on-hover card: now shows live combat statistics per element (total fires, damage dealt, effects applied, HP healed). Not shown in the shop.
_Avoid_: stat card, popup, preview — "Item Tooltip" refers only to the live-battle hover overlay going forward

**Abilities Panel**:
The bottom section of an Element Card showing the element's Ability description as a live RichTextLabel. Keywords such as [weaken] and [shock] are rendered as hoverable links that surface a Keyword Tooltip inline.
_Avoid_: info section, details panel, ability text

**Keyword Tooltip**:
A small secondary overlay that appears when the player hovers a highlighted keyword (e.g. [weaken], [shock]) inside an Abilities Panel. Contains a one-line glossary definition. Does not require Shift or any modifier key.
_Avoid_: glossary card, definition popup, shift card

### Async PvP

**Ghost**:
A snapshot of a real player's Board (grid + metadata) at a specific Round, stored and served as an async PvP opponent. The local day-seeded adapter is a stub that generates a plausible Ghost without a backend; the real target is serving Ghosts from actual player sessions.
_Avoid_: opponent board, replay board, AI board

**Ghost Pool**:
The set of Ghosts available to be drawn as opponents for a given Run context (day, round, shop tier). In production, populated from real player sessions. Before backend exists, generated locally via a day-seeded deterministic algorithm.
_Avoid_: opponent pool, enemy pool

**Milestone**:
An in-game achievement that surfaces inside the meta-progression layer. Milestones unlock Factions, Synergies, or Run modifiers — they are internal rewards, not external recognition. Shares infrastructure with Steam Achievements but is distinct from them.
_Avoid_: challenge, quest, trophy (until a canonical term is chosen)

**Purchasable Inventory Slot**:
An additional inventory slot the player can buy with gold during the shop phase. Not yet in scope; reserved as a future strategic layer.
_Avoid_: slot upgrade, bag upgrade

**Pause Menu**:
A modal overlay triggered by the ESC key in the shop or battle phase. Options: Resume, Settings, Forfeit Run (marks Run as eliminated → Main Menu), Quit to Main Menu, Quit to Desktop.
_Avoid_: options menu, escape menu

### Optional (not committed)

**PvE Boss**:
A special PvE encounter that functions as a damage or defence check. Beating a Boss unlocks a milestone (new Faction, new Synergy, or a game-changing modifier). Not confirmed for launch; noted as a strong design option.

### Developer tooling

**Efficiency Score**:
A two-axis developer-only score: DPS Score and Action Score. Used in the Balance Sandbox and Compendium dev column to identify balance outliers. Never shown to players. Gated by `FeatureFlags.efficiency_scoring`.
_Avoid_: power level, rating, rank

**DPS Score**:
`effective_damage(elem, level) / cooldown`. The offensive output axis of Efficiency Score. Computed per level; the tool shows Level 1 and Level 2 side by side.
_Avoid_: damage output, attack rating

**Action Score**:
A designer-estimated utility value representing the combat impact of an Element's Action. Drawn from a hardcoded lookup table in `BalanceSystem`. T2/T3 Elements score 0 until their Actions are designed and values added. *(Code currently calls this `effect_score` — rename pending.)*
_Avoid_: utility score, passive value, OffDef

**Balance Sandbox**:
A dev-only panel inside the Compendium scene (visible when `FeatureFlags.efficiency_scoring` is true) where the developer drags any four Elements into a test Board and sees their live Efficiency Scores (DPS + Action Score per slot, and a summed board total). No battle simulation.
_Avoid_: test bench, simulator, dev board

## Example dialogue

> "I have two identical Water elements — what do I do?"
> "Merge them — you get one Water at the next level."
> "What if I have Water and Fire?"
> "Those have a Forge recipe. Hit the Forge, spend the gold, and you get Steam — a brand new element."
> "Do I place them somewhere before fighting?"
> "Right. Fill your Board in the Shop, then click Fight. Your Board resolves automatically during combat."
> "What happens if I lose a PvP Round?"
> "You lose Life based on how badly you lost. You're still in the Run — just under pressure."
> "And if Life hits zero?"
> "That's the end of your Run."
