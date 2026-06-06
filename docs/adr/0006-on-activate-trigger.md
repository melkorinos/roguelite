# On-activate ability trigger with deterministic every-Nth gating

Added an `on_activate` ability trigger: an element's ability effects run each time it
fires, expressed in the same atomic-effect vocabulary as `combat_start` / `periodic`.
Execution lives in `AbilitySystem.apply_on_activate`, hooked in
`BattleSystem._fire_element_once` right after the on-fire Action. It is the
ability-tier sibling of the single-string legacy `effect` field: where `effect` can
apply only one status per fire, `on_activate` carries a *compound* payload — e.g.
Rootrot applies `[poison]` **and** `[weaken]` every fire, which one string cannot
express. (Gore composes both mechanisms: `effect:"leech"` for true lifesteal plus an
`on_activate` `[weaken]`.)

An optional integer `every_n` gates the effects to every Nth activation, counted from
the slot's existing `fires` tally in `battle_stats` — no new state. We chose a
deterministic counter over a probabilistic per-hit `chance` (Shrapnel was originally
"30% chance to apply `[shock]`") because combat must stay fully reproducible —
determinism is the basis for Replay — and "every 3rd hit" reads more legibly to a
player than a dice roll.

Like every non-fire-event ability, `on_activate` effects emit no reactive events
(the depth-1 model is preserved); a blinded (missed) fire applies nothing; and each
multicast repeat counts as its own activation.

This loosens, but does not contradict, ADR-0004: it adds a fourth on-fire path
alongside the Action/passive/reactive set, keeping all effect execution inside
`AbilitySystem`.
