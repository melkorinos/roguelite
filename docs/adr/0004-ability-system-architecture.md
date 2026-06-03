# Ability system architecture

Abilities for T2+ elements live in a new `data/AbilityData.gd` (keyed by element id, pure data) and execute through a new `systems/AbilitySystem.gd`, mirroring the `ElementData` / `StatusSystem` split. `BattleSystem` gains call sites but is not otherwise extended. Each element has exactly one ability for v1.

## Ability data shape

```
{
  "trigger": String,                 # combat_start | periodic | passive | on_*_applied | on_leech | on_damage_dealt
  "effects": Array[Dictionary],      # atomic actions, e.g. {"kind":"apply_status","status":"burn","amount":2,"target":"opponent"}
  "interval_deciseconds": int,       # periodic only
  "adjacency_upgrade": bool,         # optional; reactive that *should* require an adjacent source
  "description": String,
}
```

Compound abilities are an array of atomic effects. Buffs (heal, cleanse, armor, plating, haste) target own side; debuffs (burn, poison, shock, weaken, blind, curse, freeze) target the opponent — a row in the spec that violates this is treated as a data error and corrected.

## Trigger model and the depth-1 rule

Reactive triggers (`on_burn_applied`, `on_heal_applied`, `on_leech`, …) are resolved by scanning friendly slots in fixed order (slot 0…N, top-left first) after each fire emits in-tick events. **Depth-1:** a reactively-triggered ability may deal damage and apply statuses but its own output is not reactive-eligible, and a reactive activation never multicasts. This bounds every chain to one hop regardless of grid size. `combat_start` resolves once at t=0 in `to_battle()`; `periodic` first fires at +interval.

## Multicast

A multicast repeats the full cooldown fire block (damage + on-fire effects) N times — cap 2× at T2/T3, 3× at T4. **Each repeat is an independent reactive trigger** (a 2× multicast makes a friendly `on_burn_applied` ability respond twice), resolved interleaved (each repeat fully resolves, including its reactive wave, before the next). Periodic and combat-start abilities never multicast. Echo (forcing another element's fire) is cut from v1; conditional refire is supported.

## Why

Keeps `ElementData` pure stats, isolates execution in one testable system, and the depth-1 + no-reactive-multicast clauses are the load-bearing rules that keep synergy chains finite and replays deterministic (all RNG draws from the combat-start seed in slot order).
