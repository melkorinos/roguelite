# Auto-Battler

A game where players collect, Merge, and Forge pieces into synergistic compositions that fight asynchronously against other players and shared PvE encounters.

> **Note — vocabulary in transition.** The earlier extraction-roguelite terms (Zone, Run, Extraction, Scavenge) are retired. Some may return in altered form if roguelite elements are incorporated.

## Language

### Core mechanics

**Level Up** *(current implementation)*:
Combining two identical elements at the same level to produce one element of level+1. This is the live mechanic in the codebase. Drag-drop; no recipe needed.
_Avoid_: merge (reserved for the 3-copy mechanic below), fuse, evolve

**Merge** *(future, not yet implemented)*:
Combining three identical pieces to produce one upgraded version of the same piece. Distinct from Level Up — three copies, not two. Design is settled; implementation deferred.
_Avoid_: combine, fuse, evolve, triple

**Forge**:
Combining two specific pieces (A + B → C) to produce a new piece with a different identity. Requires gold and an intentional trip to the Forge. The rare, exciting upgrade path.
_Avoid_: craft, fuse, combine (too generic — Forge is a specific action with a cost)

### Pieces and equipment

**Element** *(current prototype term)*:
The core piece in the current codebase. Bought from the gold shop, placed on the Battlegrid, and fires damage during the combat phase. Defined in `ElementData.gd`. In the longer-term design, Elements will split into Units (fighters) and Items (passives on Units), but for the prototype they are unified.
_Avoid_: card, item, unit (until the split is implemented)

**Unit** *(future)*:
A piece that occupies a board slot and participates directly in combat. Acquired via the gold shop. Can have passive abilities. Currently unified with Element in the prototype.
_Avoid_: card, character, creature, minion

**Item**:
A collectable piece with passive abilities that can attach to a Unit or exist independently. Acquired via draft. Can be taken to the Forge.
_Avoid_: gear, weapon, equipment (too narrow — Items include all non-Unit equippables)

**Trinket**:
A small modifier that slots into an Item or Unit to fine-tune its behaviour. Acquired via draft. Not a standalone fighter.
_Avoid_: relic, charm, gem (until a canonical term is chosen)

### Build and combat

**Composition** (working term):
The full set of pieces a player fields at any point in a match. Always in flux until the match ends. Arrangement within the Composition does not affect combat outcome.
_Avoid_: build, loadout, board, deck — until one canonical term is chosen

**Synergy**:
An emergent beneficial interaction between two or more pieces in a Composition. Triggered either by faction thresholds (e.g. 3 Orcs) or by passive ability interactions between specific pieces.
_Avoid_: combo, interaction, effect (too generic)

**Faction**:
A category tag on a piece (e.g. Orc, Rogue, Construct). Reaching a threshold count of the same Faction in a Composition activates a bonus for all pieces of that Faction.
_Avoid_: tribe, class, race, type

**Match**:
A complete play session consisting of multiple rounds. Players begin with full HP and are eliminated when HP reaches zero.
_Avoid_: run, game, session

**Round**:
One iteration of the shop phase followed by a combat phase. Rounds are either PvP or PvE.
_Avoid_: turn, wave

**PvE Round**:
A Round where all players fight a shared encounter (same enemy wave). Occurs on a fixed, predictable schedule with some randomisation to prevent cheesing. Primary source of Trinkets.
_Avoid_: event round, boss round (unless a specific boss encounter is designed)

**PvP Round**:
A Round where a player's Composition fights an opponent's Composition asynchronously. Losing deals damage proportional to the margin of loss.
_Avoid_: battle round, fight round

**Player HP**:
The in-battle resource representing how much damage a player's side can absorb before losing that Round. Resets to its full value at the start of every battle.
_Avoid_: health, hearts

**Lives**:
The match-level resource that tracks how close a player is to elimination. Starts at 10 per match. Lost 1–3 per defeat depending on severity (hard loss ≥70% opponent HP remaining = –3; medium 30–70% = –2; close <30% = –1). A draw counts as a player win (opponent is async). Reaching 0 Lives eliminates the player. The match goal is 10 wins before Lives run out.
_Avoid_: health, HP, hearts

### Effects and statuses

**Effect**:
The passive property on an Element that fires automatically each time its cooldown expires. Every T1 Element has exactly one Effect. Effects either deal a Status on the opponent side, modify the player's own side, or trigger instantly (Heal, Cleanse, Leech).
_Avoid_: ability (reserved for the full Ability Chain system), passive, on-hit

**Status**:
An ongoing condition tracked as a flat dictionary on one player's side, not per-element. A Status has numeric state (stacks, ticks_remaining, value) that is read and written by StatusSystem. All Elements on one side contribute to and are affected by the same shared Status pool.
_Avoid_: buff/debuff (too generic), effect (that's the element property that applies it)

**T1 Elements and their Effects (12 total, all 5g)**:
Water 💧 Cleanse — Air 🌬️ Haste — Fire 🔥 Burn — Earth 🌍 Armor — Lightning ⚡ Shock — Nature 🌿 Heal — Light ☀️ Blind — Dark 🌑 Curse — Metal ⚙️ Plating — Fungus 🍄 Poison — Blood 🩸 Leech — Frost 🌨️ Weaken.
Sound 🔊 is retired; replaced by Fungus.

### Abilities and combat

**Ability**:
An effect a piece triggers during the combat phase. Can deal damage to the enemy Player HP, buff allied pieces, apply a status, or interact with another piece's Ability.
_Avoid_: attack, skill, power (too generic until a canonical term is chosen)

**Ability Chain**:
The sequence of Ability activations that resolves a combat phase. Pieces trigger in an order determined by their properties; interactions between them produce emergent outcomes. No positional targeting — the whole Composition acts as one system.
_Avoid_: combat sequence, turn order, resolution

**Innate Ability**:
A player-owned ability, separate from their pieces, that can be triggered once per combat at a chosen moment. The primary player action during the combat phase.
_Avoid_: hero power, active skill, special move — until a canonical term is chosen

**Replay**:
A mechanic allowing the player to rewatch a lost combat and retrigger it once with their Innate Ability fired at a different moment. Consumes one Replay token. Available only after a loss.
_Avoid_: undo, time rewind

### UI zones

**Battlegrid**:
The 2×2 arrangement zone inside the Shop UI where the player positions their elements before clicking Fight. Distinct from the inventory (backpack). Elements placed here fight in the combat phase.
_Avoid_: board, bench, lineup

**Battle Summary**:
A per-element debrief shown inline at the end of a combat phase. Shows fires count, total damage dealt, and DPS for each element on both sides. Embodies the "Clinical" win/loss feel goal.
_Avoid_: combat log, result screen, debrief

### Economy

**Gold**:
The currency spent in the shop phase to buy pieces and reroll the shop. Not used for the draft.
_Avoid_: coins, money

**Draft**:
The free selection of Items and Trinkets offered each round. Separate from the gold shop.
_Avoid_: pick phase, card draw

**Rarity**:
A tier assigned to each piece that determines how frequently it appears in the shop. Working tiers: Common, Rare, Epic. *(Note: the codebase currently uses numeric Tier 1/2/3 — the named rarity vocabulary is aspirational and not yet reflected in code.)*
_Avoid_: grade, quality — "tier" is acceptable shorthand until a canonical term is chosen

### UI overlays

**Item Tooltip**:
A stats card that appears next to the cursor after hovering over an element for 0.3 seconds. Contains two sections: a stats section (tier, level, cooldown, damage, effective damage, price) and an Abilities Panel below it. Appears in the Shop and during active Battle.
_Avoid_: stat card, hover card, popup, preview

**Abilities Panel**:
The lower section of the Item Tooltip reserved for an element's active and passive ability descriptions. Currently a placeholder.
_Avoid_: info section, details panel, ability card

### Async PvP

**Ghost**:
A snapshot of a real player's Composition (grid + metadata) at a specific Round, stored and served as an async PvP opponent. The Ghost pool is the collection of Ghosts available for a given day or context. The local day-seeded adapter is a stub that generates a plausible Ghost without a backend; the real target is serving Ghosts from actual player sessions.
_Avoid_: opponent board, replay board, AI board

**Ghost Pool**:
The set of Ghosts available to be drawn as opponents for a given match context (day, round, shop tier). In production, populated from real player sessions. Before backend exists, generated locally via a day-seeded deterministic algorithm.
_Avoid_: opponent pool, enemy pool

**Milestone**:
An in-game achievement that surfaces inside the meta-progression layer (e.g. "dealt 20,000 total damage"). Milestones unlock Factions, Synergies, or run modifiers — they are internal rewards, not external recognition. Shares infrastructure with Steam Achievements but is distinct from them.
_Avoid_: challenge, quest, trophy (until a canonical term is chosen)

**Level 2 Reward**:
A bonus granted when an element reaches level 2 through a merge. Provides a flat gold payout plus a player-chosen flat stat boost (e.g. +1 base damage or −0.5 s cooldown). Healing, armour, and status effects are deferred to a later design session.
_Avoid_: merge bonus, upgrade reward

**Purchasable Inventory Slot**:
An additional inventory slot the player can buy with gold during the shop phase. Not yet in scope; reserved as a future strategic layer.
_Avoid_: slot upgrade, bag upgrade

**Pause Menu**:
A modal overlay triggered by the ESC key in the shop or battle phase. Options: Resume, Settings, Forfeit Run (marks match as eliminated → Main Menu), Quit to Main Menu, Quit to Desktop.
_Avoid_: options menu, escape menu

### Optional (not committed)

**PvE Boss**:
A special PvE encounter that functions as a damage or defence check. Beating a Boss unlocks a milestone (new Faction, new Synergy, or a game-changing modifier). Not confirmed for launch; noted as a strong design option.

### Developer tooling

**Efficiency Score**:
A two-axis developer-only score assigned to each Element: DPS Score and Effect Score. Used in the Balance Sandbox and Compendium dev column to identify balance outliers across the element roster. Never shown to players. Gated by `FeatureFlags.efficiency_scoring`.
_Avoid_: power level, rating, rank

**DPS Score**:
`effective_damage(elem, level) / cooldown`. The offensive output axis of the Efficiency Score. Computed per level; the balance tool shows Level 1 and Level 2 side by side.
_Avoid_: damage output, attack rating

**Effect Score**:
A designer-estimated utility value representing the combat impact of an Element's Effect. Drawn from a hardcoded lookup table in `BalanceSystem`. T2/T3 Elements without an assigned Effect score 0 until their effects are designed and values are added.
_Avoid_: utility score, passive value, OffDef

**Balance Sandbox**:
A dev-only panel inside the Compendium scene (visible when `FeatureFlags.efficiency_scoring` is true) where the developer drags any four Elements into a test Composition and sees their live Efficiency Scores (DPS + Effect Score per slot, and a summed board total). No battle simulation — score display only.
_Avoid_: test bench, simulator, dev board

## Example dialogue

> "I have three identical swords — what do I do?"
> "Take them to the Forge or wait — three of the same Item will Merge into an upgraded version automatically."
> "What if I have a sword and a gem?"
> "Those might have a Forge recipe. Spend gold at the Forge and you get a new Item with a different identity."
> "And that new Item goes on a Unit?"
> "Right. Attach it to a Unit in your Composition. The Item's passive activates during the combat phase."
> "What happens if I lose a PvP Round?"
> "You take damage based on how badly you lost — their surviving pieces determine how much. You're not eliminated, just pressured."
