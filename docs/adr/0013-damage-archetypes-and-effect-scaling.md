# Pure-effect vs damage-dealer archetypes, level-scaled effects, Curse v2

A combat-model redesign decided together (2026-06-XX):

## Archetypes
Elements split into **pure-effect** (deal **no** direct hit damage — their Status *is* their
damage) and **damage-dealer** (deal direct damage). Direct damage is a **rare privilege**:
all T1 are pure-effect; only a curated ~20% of T2+ deal damage (impact/physical theme, skewed
to T4). The set is the whitelist `ElementData.DAMAGE_DEALERS`; gating there means **zero churn
to the 132 data entries**. `effective_damage` returns 0 for anyone not in it.

## effective_damage = base × multiplier × level
The `+ tier` term was **dropped** — a tier change is a new element with its own base, so tier
shouldn't also chip the hit. `multiplier` is retained but vestigial (nothing sets it; Starting
Pick no longer does). Pure-effect → 0 (no tier chip). `BattleSystem._fire_element_once` skips
the entire damage block when raw damage is 0 (no mitigation, no armour-strip, no curse-consume).

## Level scales effect quantity
A status applied by a Level-N element applies **N** stacks/points/heal (`StatusSystem.apply_effect`
gained a `potency` param; `AbilitySystem._apply_effects` derives it from the source element's
level; on-hit passives carry their element's level). The only model a *shared per-side* status
pool supports — per-stack-by-applier can't be tracked. Linear; caps still clamp.

## Curse v2 — charges, not duration
Curse is now **stacks consumed per damaging event**: each incoming hit or DOT tick that deals
damage adds `damage_amplifier` and spends one charge (0 charges → spent). Replaces the
duration/`is_permanent` model — so curse level-scales like every other status and self-depletes
by use. `void`/`voidrift` (which used `is_permanent`) now apply a deep curse (10 charges).

## Opponent HP → round-scaled, board-independent (placeholder)
With direct damage now rare, opponent HP can't key off board `damage` (0 for most). It's now
`OPPONENT_BASE_HP(100) × (1 + GROWTH%·(round−1))` — modest, so a strong build crashes through.
A placeholder to be retuned in the balance playtest. (Supersedes the deferred review candidate
B, which would have routed opponent HP through `effective_damage` — moot now.)

## Starting Pick → +1 level
Its old ×damage buff is a no-op now that T1 are pure-effect, so it grants the chosen element at
`STARTING_PICK_LEVEL` (a Merge/Forge head start) instead.
