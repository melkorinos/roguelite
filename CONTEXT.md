# Auto-Battler

A game where players collect, Merge, and Forge pieces into synergistic compositions that fight asynchronously against other players and shared PvE encounters.

> **Note — vocabulary in transition.** The earlier extraction-roguelite terms (Zone, Run, Extraction, Scavenge) are retired. Some may return in altered form if roguelite elements are incorporated.

## Language

### Core mechanics

**Merge**:
Combining three identical pieces to produce one upgraded version of the same piece. The primary upgrade loop.
_Avoid_: combine, fuse, evolve, triple

**Forge**:
Combining two specific pieces (A + B → C) to produce a new piece with a different identity. Requires gold and an intentional trip to the Forge. The rare, exciting upgrade path.
_Avoid_: craft, fuse, combine (too generic — Forge is a specific action with a cost)

### Pieces and equipment

**Unit**:
A piece that occupies a board slot and participates directly in combat. Acquired via the gold shop. Can have passive abilities.
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
The resource that tracks a player's survival across Rounds. Each loss in a PvP Round deals damage proportional to the losing margin. A player is eliminated when HP reaches zero. HP is not reset between Rounds.
_Avoid_: health, lives, hearts

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

### Economy

**Gold**:
The currency spent in the shop phase to buy pieces and reroll the shop. Not used for the draft.
_Avoid_: coins, money

**Draft**:
The free selection of Items and Trinkets offered each round. Separate from the gold shop.
_Avoid_: pick phase, card draw

**Rarity**:
A tier assigned to each piece that determines how frequently it appears in the shop. Working tiers: Common, Rare, Epic.
_Avoid_: grade, quality, tier — until a canonical term is chosen

### Optional (not committed)

**PvE Boss**:
A special PvE encounter that functions as a damage or defence check. Beating a Boss unlocks a milestone (new Faction, new Synergy, or a game-changing modifier). Not confirmed for launch; noted as a strong design option.

## Example dialogue

> "I have three identical swords — what do I do?"
> "Take them to the Forge or wait — three of the same Item will Merge into an upgraded version automatically."
> "What if I have a sword and a gem?"
> "Those might have a Forge recipe. Spend gold at the Forge and you get a new Item with a different identity."
> "And that new Item goes on a Unit?"
> "Right. Attach it to a Unit in your Composition. The Item's passive activates during the combat phase."
> "What happens if I lose a PvP Round?"
> "You take damage based on how badly you lost — their surviving pieces determine how much. You're not eliminated, just pressured."
