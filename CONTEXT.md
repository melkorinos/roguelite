# Roguelite

A scavenger roguelite where the player engineers synergies from salvaged items to survive and extract from dangerous zones.

## Language

**Run**:
A single play session — the player enters a Zone, scavenges, and either extracts successfully or dies.
_Avoid_: session, game, attempt, level

**Zone**:
The spatial area the player enters and explores during a Run. Contains enemies, obstacles, and Items to scavenge.
_Avoid_: level, map, stage, room (a room is a subdivision of a Zone, not the Zone itself)

**Extraction**:
The act of leaving a Zone alive to end a Run successfully, keeping whatever was accumulated.
_Avoid_: escape, exit, win

**Item**:
A collectable object found in a Zone. Can be equipped, consumed, or combined. The raw material of a Build.
_Avoid_: weapon, gear, power-up, loot (too vague)

**Build**:
The set of Items a player holds at any point during a Run. A Build is always in flux until Extraction.
_Avoid_: loadout, kit, inventory

**Synergy**:
An emergent beneficial interaction between two or more Items in a Build. The primary reward the game delivers. A Synergy is discovered, not designed by the player in advance.
_Avoid_: combo, effect, interaction (too generic)

**Scavenge**:
The act of finding and collecting Items from the Zone. The core player activity that shapes the Build.
_Avoid_: loot, pick up, collect

## Example dialogue

> "I found a broken soldering iron and a broken battery pack — what happens?"
> "Those two Items triggered a Synergy. The Build now outputs chain lightning."
> "Is that guaranteed every Run?"
> "No — Synergies are emergent. You need both Items in your Build, and the Zone has to give you both."
> "So the challenge is finding the right Items to scavenge before I try to Extract?"
> "Exactly. Stay in the Zone longer to Scavenge more, but the risk of dying before Extraction goes up."
