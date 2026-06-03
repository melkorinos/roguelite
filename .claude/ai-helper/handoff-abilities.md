# Handoff — Element Ability System: Design + Implementation

## Purpose

Complete handoff for a fresh model to: (1) finish deciding remaining T2/T3/T4 abilities via
grilling, then (2) implement the full system. Read top-to-bottom before doing anything.

---

## IMPLEMENTATION STATUS — updated 2026-06-04 (post architecture deepenings)

The grilling and the core build are **done**, plus architecture candidates 1–3 from
`.claude/ai-helper/reviews/architecture-review-20260604.html`. The sections below are the original
design notes; where they conflict with what shipped, the shipped behaviour (and ADR 0003/0004) wins.

**Shipped & tested (351/351 green, boot exit 0):**
- Integer **decisecond** time model (ADR 0003): `cooldown_deciseconds`, floor-10, shock-slow round.
- `StatusSystem`: integer blind %, curse `{ticks_remaining,is_permanent,damage_amplifier}`,
  burn/poison `tick_damage_bonus`, shock `effective_stack_bonus`, signed `cooldown_modifier_deciseconds`.
- `systems/GridSystem.gd` (grid-agnostic `dimensions` + orthogonal `neighbors`).
- Freeze: per-side `*_frozen_seconds` + `*_last_frozen_slot`, anti-permalock, paused-CD.
- `systems/AbilitySystem.gd` (ADR 0004): combat_start / periodic / reactive(depth-1) /
  multicast(1 cast = 2 triggers) / passive-on-hit, wired into `to_battle` + `tick_battle`.
- `data/AbilityData.gd`: ~87 T2+T3 abilities. **T4 stubbed**.
- Tooltip **and** Compendium show ability descriptions. All `FeatureFlags` default **true**.
- **C1 — conditional effects:** effects take an optional `when:[…]` guard
  (`target_has_status at_least`). surge/blight/sporeflow/cryptbloom/arcbeam/wildrot conditionals restored.
- **C2 — adjacency:** reactive resolution reads the event source slot; `adjacency_upgrade` abilities
  gated by `FeatureFlags.combat_adjacency` + `GridSystem.neighbors`.
- **C3 — seeded RNG:** `combat_rng_state` seeded per round in `to_battle`, threaded through combat;
  blind + on-hit passives draw from it → reproducible Replay/Ghost. `passive_on_hit` now actually fires.

**Pending — from my point of view, roughly prioritised:**

1. **~21 skipped abilities needing engine hooks the build still lacks.** `get_ability` returns `{}` for
   them. Each needs a NEW capability, not just data:
   - *on-tick reactive events* (emit when a Status ticks): miasma, rootrot, moldsteel, rot, underrot-style.
   - *plating-vs-DOT* modifier: steel.
   - *leech modifiers* (heal amount/×): pulse, ichor-double, gore (+dmg vs weakened).
   - *passive stat modifiers*: gust (haste strength), mountain (armor floor), tempest (shock no-decay),
     blackice (weaken duration), razorwind (weaken-as-shock), ash (blind→dmg), acid (armor no-regen),
     shrapnel (plating bypass), magnet (shock→plating), rainbow (random status), plant (heal+1),
     ancientgrove (conditional dmg), aurora (haste→blind), voidrift (cleanse efficiency).
   - This is **architecture candidate 2's second half** (typed `on_tick`/`on_armor_stripped` events) plus
     a small **passive-modifier query layer** (like `on_hit_status_chances`, but for stat modifiers read
     at the relevant calc site). Build those two seams, then most of the list becomes data.

2. **Tooltip keyword hover-glossary + shift-to-pin (§10).** NOT built. `[burn]`/`[shock]` tags render
   literally. Needs `StatusGlossary` map + bracket-detecting renderer + shift-to-pin. Main UI task.

3. **Grid growth to 2×3 / 3×3.** Backend is grid-agnostic (loops `grid.size()`, `GridSystem`), but the
   live grid is still 4 slots. Growing means widening `battle_grid`/`opponent_grid`/timers/frozen/
   ability_timers/battle_stats arrays + `create_opponent_grid` + the Battle/Shop slot UI. Adjacency only
   becomes interesting at 3×3.

4. **Innate Ability + Replay** (architecture candidate 5). `tick_battle` has no injection seam for a
   player-timed action. Add a timed-command queue in state; Replay re-times one command and re-runs with
   the now-seeded RNG (C3 already makes this reproducible).

5. **Architecture candidate 4** — collapse the duplicated side-key maps (`_make_side_ctx` / `_side_keys`)
   into one `CombatSide` accessor. Do before grid growth or innate state (both add per-slot arrays).

6. **T4 data fill** (10 elements) — pure data, no engine work.

---

## Game context

Auto-battler (Godot 4 / GDScript). 132 elements across 4 tiers. Combat is real-time deterministic:
elements fire on individual CD timers, dealing damage and applying statuses. Board is currently 2×2
(may grow to 3×3). Statuses are side-wide pools (not per-element), except `freeze` (see below).

Key files to read before starting:
- `data/ElementData.gd` — element stat dicts (id, name, tier, cooldown, damage, effect)
- `systems/BattleSystem.gd` — `tick_battle()`, `_tick_side()`, `_apply_element_effect()`
- `systems/StatusSystem.gd` — `apply_effect()`, `tick()`, `compute_incoming_damage()`
- `scenes/shared/TooltipCard.gd` — tooltip UI, hardcoded "— none yet —" ability placeholder
- `CONTEXT.md` — canonical vocabulary; read before using any terms
- `.claude/ai-helper/memory.md` — settled design decisions

T1 elements have an **Effect** (fires every CD, applies a status). That system is live and not
changing. T2/T3/T4 elements currently have no ability field at all — the Abilities Panel in the
Item Tooltip is a hardcoded placeholder.

---

## Deferred T4 seed concepts (kept for future reference)

- **Nebula** — stellar gas / star formation; birth of a star (vs Supernova = death)
- **Void Absolute** — total erasure of light; distinct from Singularity (matter collapse)

---

## Settled architecture decisions

### 1. AbilityData.gd — separate file

Abilities live in a new `data/AbilityData.gd`, keyed by element ID. `ElementData.gd` stays as
pure stats. Same pattern as `RecipeData.gd` sitting alongside `ElementData.gd`.

```gdscript
class_name AbilityData

static func get_ability(element_id: String) -> Dictionary:
    match element_id:
        "steam": return {
            "trigger": "on_burn_applied",
            "effect": "deal_damage",
            "params": { "value": 1, "target": "opponent" },
            "description": "When [burn] is applied, deal 1 bonus damage."
        }
        # ...
    return {}
```

### 2. AbilitySystem.gd — new system file

New `systems/AbilitySystem.gd`. `BattleSystem` calls into it the same way it calls `StatusSystem`.
`BattleSystem` is not extended — it gains one call site per tick.

### 3. No feature flags

Abilities are always active once the field is present. No gating.

### 4. Reactive triggers — polling, depth-1 rule

After each element fires, `BattleSystem` polls all other elements' ability triggers.
**Depth-1 rule:** a reactively-triggered ability can deal damage and apply effects but cannot
itself trigger another reactive ability. This caps all chains at one hop and prevents infinite
synergy loops regardless of grid size. Periodic and combat-start abilities are unaffected.

### 5. Freeze — per-slot state, not StatusSystem

`frozen_slots: Array[float]` added to GameState (indexed by slot, parallel to `element_timers`).
Value = seconds remaining frozen (counts down with delta). When > 0, that slot skips its fire.

`_last_frozen_slot: int` tracked during combat. When selecting a freeze target, exclude the last
frozen slot as long as another occupied slot exists. Prevents one element being permanently locked.

Freeze is cleansable: a Cleanse effect sets the target slot's `frozen_slots[i]` to 0.

### 6. Multicast — full repeat, capped by tier

Multicast repeats the full fire block (damage + effect) N times in one CD trigger.
- T2 / T3: cap 2×
- T4: cap 3×

Three flavors:
- **Self-multicast**: element fires N× on one CD (Blaze, Ichor)
- **Conditional refire**: fires again if a condition is met at fire time (Voltspore, Frostburn)
- **Echo**: when this fires, trigger another element's next fire immediately — **deferred until
  event queue architecture exists; design as global reactive in v1**

### 7. One ability per element for v1

Each element gets exactly one ability. A second slot or combinable abilities via Trinkets is a
future concern.

### 8. on_adjacent_fire — TODO for a future session

**TODO:** Some abilities (Ember, Photosynthesis) have a richer version that fires only when an
*adjacent* element triggers a specific event. Requires grid position tracking in combat state.
For v1, these are implemented as global reactives (`on_heal_applied` not `on_adjacent_heal_applied`).
Mark affected entries in AbilityData with `"adjacency_upgrade": true` so they are easy to find.
Run a dedicated handoff session after the grid system ships.

### 9. New StatusSystem fields needed

Two small additions to the status dict shape:

| Field | Lives in | Used by |
|---|---|---|
| `burn_bonus: int` | `burn` dict | Blaze — burn ticks deal `stacks + burn_bonus` damage |
| `shock_bonus_stacks: int` | `shock` dict | Plasma — `slow_pct` reads as if `n + bonus` |

`StatusSystem.empty_statuses()` gains these two fields. `StatusSystem.tick()` reads `burn_bonus`.
`StatusSystem.slow_pct()` reads `shock_bonus_stacks` from the dict or accepts it as a param.

### 10. Tooltip — keyword hover system

Ability descriptions use `[keyword]` tags (e.g. `[burn]`, `[shock]`). A `StatusGlossary`
dictionary maps keyword → one-line definition. Tooltip renderer detects bracket-wrapped terms
and renders them as hoverable inline links.

**Shift-to-pin:** holding Shift freezes the tooltip card so the player can move the cursor into
the Abilities Panel without it closing. UI-layer addition only; no ability data change needed.

Glossary must cover: `burn`, `poison`, `shock`, `weaken`, `armor`, `plating`, `blind`, `curse`,
`leech`, `heal`, `cleanse`, `haste`, `freeze`, `multicast`.

---

## Trigger type vocabulary (for AbilityData)

| Trigger string | Fires when |
|---|---|
| `combat_start` | Once at combat begin |
| `periodic` | Every N seconds (needs `"interval": float` param) |
| `passive` | Always-on modifier to existing calculations |
| `on_burn_applied` | Any element on own side applies burn |
| `on_heal_applied` | Any element on own side applies heal |
| `on_leech` | Leech triggers on own side |
| `on_status_applied` | Any status applied (needs `"status": String` param) |
| `on_damage_dealt` | Own element deals damage (probabilistic effects use this) |
| `on_armor_stripped` | Opponent armor reaches 0 or is stripped by any source |

---

## Agreed abilities — T2 Original Cross

| Element | Trigger | Description |
|---|---|---|
| **Steam** | `on_burn_applied` | When [burn] is applied by any element, deal 1 bonus damage to opponent |
| **Rain** | `combat_start` + `periodic 8s` | Apply 2 [cleanse] to own side at combat start; every 8s apply 1 [cleanse] |
| **Mud** | `combat_start` | All opponent element cooldowns permanently +0.8s |
| **Smoke** | `combat_start` | Apply 2 [blind] + 1 [curse] to opponent |
| **Lava** | `periodic 6s` | Apply 2 [burn]; if opponent has [armor] ≥ 1, strip 1 [armor] stack |
| **Dust** | `passive` | Own elements have 15% chance to apply 1 [weaken] on any damage hit |

---

## Agreed abilities — T2 Lightning family

| Element | Trigger | Description |
|---|---|---|
| **Surge** | `periodic 5s` | Apply 2 [shock]; if opponent has ≥ 3 [shock], deal 2 bonus damage |
| **Arc** | `on_burn_applied` | When [burn] is applied, also apply 1 [shock] |
| **Static** | `passive` | Own elements have 20% chance to apply 1 [shock] on any damage hit |
| **Lodestone** | `combat_start` | Apply [armor] 2 to own side; reduce own element cooldowns by 0.5s |

---

## Agreed abilities — T2 Self (mutation principle)

Self-crosses mutate the T1 mechanic — different behaviour, not just bigger numbers. T1 elements
stay relevant because the two versions are complementary, not redundant.

| Element | Trigger | Description |
|---|---|---|
| **Sea** (Water×2) | `periodic 6s` | Remove ALL stacks of one random debuff from own side |
| **Blaze** (Fire×2) | `passive` + multicast 2× | [burn] ticks deal +1 damage each (`burn_bonus`); fires twice per cooldown |
| **Gust** (Air×2) | `passive` | [haste] reduces cooldowns by 0.5s instead of 0.3s |
| **Boulder** (Earth×2) | `combat_start` | Apply [armor] 4 to own side |
| **Plasma** (Lightning×2) | `passive` | [shock] slow calculated as if +3 extra stacks exist (`shock_bonus_stacks`) |
| **Forest** (Nature×2) | `periodic 8s` | Apply [heal] 3 to own side |
| **Radiance** (Light×2) | `combat_start` | Apply 3 [blind] to opponent |
| **Void** (Dark×2) | `passive` | [curse] never expires until cleansed |
| **Steel** (Metal×2) | `passive` | [plating] also reduces [burn] and [poison] tick damage |
| **Mycelium** (Fungus×2) | `passive` | Each new [poison] stack also deals 1 instant damage when applied |
| **Freeze** (Frost×2) | `combat_start` | Freeze one opponent element for 8s + apply 2 [weaken] |
| **Ichor** (Blood×2) | `passive` + multicast 2× | [leech] heals double; fires twice per cooldown |

---

## Pending — T2 Nature family

| Element | Trigger | Proposed ability |
|---|---|---|
| **Bloom** (Nature+Water) | `combat_start` | Apply [heal] 2 + [cleanse] 1 to own side simultaneously |
| **Ember** (Nature+Fire) | `on_heal_applied` | When [heal] fires on own side, apply 1 [burn] to opponent *(adjacency upgrade TODO)* |
| **Pollen** (Nature+Air) | `passive` | 15% chance to apply 1 [poison] on any damage hit |
| **Root** (Nature+Earth) | `combat_start` | Apply [armor] 2 to own side; reduce own cooldowns by 0.3s |

---

## Pending — T2 Light family

| Element | Trigger | Proposed ability |
|---|---|---|
| **Prism** (Light+Water) | `combat_start` | Apply 2 [blind] to opponent; own damage bypasses 0.1 [plating] |
| **Solar** (Light+Fire) | `periodic 5s` | Apply 1 [burn] + 1 [blind] simultaneously |
| **Aurora** (Light+Air) | `passive` | Each [haste] application also applies 1 [blind] to opponent |
| **Crystal** (Light+Earth) | `combat_start` | Apply [plating] 0.2 + [armor] 1 to own side |

---

## Pending — T2 Dark family

| Element | Trigger | Proposed ability |
|---|---|---|
| **Abyss** (Dark+Water) | `combat_start` | Apply 1 [curse] + 1 [blind] to opponent |
| **Blight** (Dark+Fire) | `periodic 5s` | Apply 1 [burn] + 1 [curse]; if opponent has [poison], apply +1 [poison] |
| **Miasma** (Dark+Air) | `passive` | [poison] ticks have 25% chance to also apply 1 [blind] |
| **Shade** (Dark+Earth) | `combat_start` | Apply [armor] 2 to own side; own elements deal +1 damage while [curse] is active |

---

## Pending — T2 Metal family

| Element | Trigger | Proposed ability |
|---|---|---|
| **Rust** (Metal+Water) | `passive` | Whenever opponent [armor] is stripped, deal 1 bonus damage |
| **Molten** (Metal+Fire) | `periodic 6s` | Apply 2 [burn]; gain [plating] +0.1 each time [burn] strips opponent [armor] |
| **Shrapnel** (Metal+Air) | `passive` | Own elements' damage bypasses first 0.1 [plating] |
| **Flint** (Metal+Earth) | `on_damage_dealt` | 25% chance to apply 1 [shock] on any damage hit |

---

## Pending — T2 Fungus family

| Element | Trigger | Proposed ability |
|---|---|---|
| **Sporeflow** (Fungus+Water) | `periodic 5s` | Apply 2 [poison]; if opponent has [weaken], apply +1 [poison] |
| **Fireshroom** (Fungus+Fire) | `on_burn_applied` | When [burn] is applied, also apply 1 [poison] |
| **Haze** (Fungus+Air) | `combat_start` | Apply 1 [poison] + 1 [blind] to opponent |
| **Rootrot** (Fungus+Earth) | `passive` | [poison] stacks strip 0.05 [plating] per stack each tick |

---

## Pending — T2 Blood cross

Previously agreed: Pulse, Fever, Hemowind, Ironblood.

| Element | Trigger | Proposed ability |
|---|---|---|
| **Pulse** (Blood+Water) | `passive` | [leech] heals damage+1 instead of exact damage *(agreed)* |
| **Fever** (Blood+Fire) | `combat_start` | Apply 1 [poison] + 1 [weaken] to opponent *(agreed)* |
| **Hemowind** (Blood+Air) | `on_leech` | Each [leech] trigger permanently reduces own CDs by 0.2s *(agreed)* |
| **Ironblood** (Blood+Metal) | `combat_start` | Apply [plating] 0.3 to own side *(agreed)* |
| **Sparkblood** (Blood+Lightning) | `on_leech` | Each [leech] trigger also applies 1 [shock] to opponent |
| **Lifebloom** (Blood+Nature) | `on_heal_applied` | When [heal] fires, also trigger [leech] once |
| **Hemogoblin** (Blood+Dark) | `combat_start` | Apply 1 [curse] + 1 [burn]; [leech] heals double while [curse] is active |
| **Nightveil** (Blood+Dark) | `combat_start` | Apply 2 [blind] to opponent; trigger [leech] once immediately |
| **Gore** (Blood+?) | `passive` | When opponent is hit while [weaken] is active, deal +1 bonus damage |
| **Hemospore** (Blood+Fungus) | `on_leech` | Each [leech] trigger also applies 1 [poison] to opponent |
| **Frostbite** (Blood+Frost) | `combat_start` | Apply 2 [weaken] to opponent + trigger [leech] once |

---

## Pending — T2 Frost cross

Previously agreed: Frostburn, Razorwind, Permafrost.

| Element | Trigger | Proposed ability |
|---|---|---|
| **Black Ice** (Frost+Water) | `passive` | [weaken] stacks on opponent last 2 extra ticks before expiring |
| **Frostburn** (Frost+Fire) | `periodic 5s` | Apply 1 [burn] + 2 [weaken] simultaneously *(agreed)* |
| **Razorwind** (Frost+Air) | `passive` | Each [weaken] stack also counts as 0.5 [shock] (rounded up) *(agreed)* |
| **Permafrost** (Frost+Earth) | `combat_start` | Freeze one random opponent element for 5s; rotation enforced *(agreed)* |
| **Hail** (Frost+Lightning) | `periodic 4s` | Apply 1 [shock] + 1 [weaken] simultaneously |
| **Chill** (Frost+?) | `passive` | Opponent elements have +0.3s effective CD |
| **Whiteout** (Frost+Light) | `combat_start` | Apply 3 [blind] to opponent |
| **Wither** (Frost+Nature) | `periodic 5s` | Apply 2 [weaken] + 1 [cleanse] to own side |
| **Tempered** (Frost+Metal) | `combat_start` | Apply [plating] 0.2 + [armor] 2 to own side |
| **Cryptbloom** (Frost+Fungus) | `periodic 6s` | Apply 1 [poison] + 1 [weaken]; if both already active, deal 2 bonus damage |

---

## Pending — T2 Extended-to-Extended

Previously agreed: Murk, Voltspore, Photosynthesis, Ironwood.

| Element | Trigger | Proposed ability |
|---|---|---|
| **Murk** (Dark+Fungus) | `passive` | [poison] ticks also apply 1 [blind] per tick *(agreed)* |
| **Voltspore** (Lightning+Fungus) | `passive` | Each [poison] stack increases [shock] slow efficiency by 5% *(agreed)* |
| **Photosynthesis** (Nature+Light) | `on_heal_applied` | Each [heal] reduces own CDs by 0.2s *(agreed; adjacency upgrade TODO)* |
| **Ironwood** (Nature+Metal) | `combat_start` | Apply [armor] 2 + [plating] 0.1 to own side *(agreed)* |
| **Beacon** (Light+Metal) | `combat_start` | Apply 2 [blind] to opponent; own [plating] doubles while [blind] is active |
| **Lucent** (Light+Fungus) | `periodic 5s` | Apply 1 [blind] + 1 [poison] simultaneously |
| **Hexcore** (Dark+Metal) | `combat_start` | Apply [curse] + [plating] 0.2 to own side |
| **Bloomspark** (Nature+Lightning) | `on_heal_applied` | When [heal] fires, also apply 1 [shock] to opponent |
| **Arcbeam** (Lightning+Light) | `periodic 4s` | Apply 2 [shock]; if opponent has [blind], apply 1 additional [shock] |
| **Voidspark** (Dark+Lightning) | `periodic 5s` | Apply 1 [shock] + 1 [curse] simultaneously |
| **Magnet** (Lightning+Metal) | `passive` | Each [shock] stack on opponent also adds 0.05 to own [plating] |
| **Rot** (Nature+Fungus) | `passive` | [poison] stacks grow by 1 extra every 5 ticks |
| **Wildrot** (Nature+Fungus) | `periodic 6s` | Apply 1 [poison]; if opponent has [weaken], apply +1 [poison] |
| **Umbra** (Dark+Light) | `combat_start` | Apply 2 [blind] + 1 [curse]; own elements deal +1 damage for first 10s |
| **Moldsteel** (Metal+Fungus) | `passive` | [poison] ticks strip 0.05 [plating] per stack |

---

## Pending — T3 (proposed directions)

T3 design principles:
- Made from T2+T2 — abilities should feel like the synthesis of two T2 identities
- Higher impact than T2; board-wide effects are appropriate
- Multicast 2× suits high-aggression T3s
- Compound triggers encouraged ("when X AND Y are active, do Z")

| Element | Trigger | Proposed ability |
|---|---|---|
| **Cloud** | `periodic 5s` | Apply 1 [cleanse] to own side + 1 [blind] to opponent |
| **Geyser** | `periodic 8s` | Deal 4 bonus damage + apply 2 [weaken] |
| **Fog** | `combat_start` | Apply 3 [blind] + 1 [curse] to opponent |
| **Rainbow** | `passive` | Own element effects have 15% chance to apply one additional random positive status |
| **Storm** | `periodic 3s` + multicast 2× | Apply 2 [shock]; fires twice per trigger |
| **Plant** | `passive` | All own [heal] effects heal +1 more HP |
| **Swamp** | `combat_start` | All opponent CDs +1.5s + apply 2 [weaken] |
| **Brick** | `combat_start` | Apply [armor] 4 + [plating] 0.2 to own side |
| **Ash** | `passive` | Each [blind] stack on opponent reduces their damage output by 0.5 |
| **Acid** | `passive` | Opponent [armor] stripped during this combat does not regenerate |
| **Obsidian** | `combat_start` | Apply [armor] 4 + [plating] 0.2 to own side; deal 3 bonus damage to opponent |
| **Volcano** | `periodic 4s` + multicast 2× | Apply 3 [burn]; fires twice per trigger |
| **Sand** | `passive` | 25% chance to apply 1 [weaken] on any damage hit |
| **Sandstorm** | `periodic 3s` + multicast 2× | Apply 1 [blind] + 1 [weaken]; fires twice per trigger |
| **Clay** | `combat_start` | Apply [armor] 3 to own side; all opponent CDs +0.5s |
| **Glacier** | `combat_start` | Freeze two random opponent elements for 5s |
| **Blizzard** | `periodic 4s` + multicast 2× | Apply 2 [weaken] + 1 [shock]; fires twice per trigger |
| **Tundra** | `combat_start` | All opponent CDs +2s + apply 2 [weaken] |
| **Rainforest** | `passive` + `periodic 10s` | [heal] effects heal +2 more; every 10s purge all stacks of one debuff from own side |
| **Ancient Grove** | `passive` | All own element effective damage +1 while own HP > 50% |
| **Hurricane** | `periodic 3s` + multicast 2× | Apply 2 [shock] + 1 [blind]; fires twice per trigger |
| **Tempest** | `passive` | [shock] stacks never decay during combat |
| **Mountain** | `passive` | Own [armor] cannot be reduced below 2 stacks |
| **Tsunami** | `periodic 8s` | Deal 6 bonus damage ignoring [armor] and [plating]; apply 3 [weaken] |
| **Eclipse** | `combat_start` | Apply 3 [blind] + 2 [curse] to opponent; own elements deal +2 damage for first 10s |
| **Voidrift** | `passive` | While [curse] is active, opponent [cleanse] and [heal] effects are 50% less effective |
| **Plague** | `periodic 4s` + multicast 2× | Apply 3 [poison]; fires twice per trigger |
| **Underrot** | `passive` | [poison] stacks deal +1 damage per tick (stacks with `burn_bonus` pattern — new `poison_bonus` field) |
| **Inferno** | `periodic 3s` + multicast 2× | Apply 2 [burn] + 1 [curse]; fires twice per trigger |
| **Hemorrhage** | `on_leech` | Each [leech] trigger also applies 1 [poison] to opponent |
| **Carnage** | multicast 2× + `passive` | [leech] triggers twice per fire; fires twice per cooldown |
| **Meteorite** | `combat_start` | Deal 5 bonus damage to opponent; apply [armor] 2 + [plating] 0.1 to own side |

---

## Pending — T4 (proposed directions)

T4 design principles:
- The most powerful single ability in the game for each element
- Multicast 3× available
- Compound and board-wide effects are expected, not exceptional

| Element | Trigger | Proposed ability |
|---|---|---|
| **Ice Age** | `combat_start` | Freeze ALL opponent elements for 5s; all opponent CDs permanently +2s |
| **Maelstrom** | `periodic 3s` + multicast 2× | Apply 2 [shock] + 2 [weaken]; fires twice per trigger |
| **Tectonic** | `combat_start` | Apply [armor] 8 + [plating] 0.4 to own side; deal 5 bonus damage to opponent |
| **Supernova** | `periodic 4s` + multicast 2× | Apply 3 [burn] + 2 [blind]; fires twice; `burn_bonus` +2 |
| **Singularity** | `combat_start` + `passive` | Apply permanent [curse]; all opponent CDs +1.5s; deal 3 bonus damage |
| **World Tree** | `passive` | All own elements heal own side 1 HP when they fire; [heal] effects heal +3 |
| **Pandemic** | `passive` + multicast 2× | [poison] ticks deal +2 damage; each new stack deals +1 instant damage; fires twice |
| **Ragnarok** | `periodic 3s` + multicast 2× | Deal 5 bonus damage; apply 1 [burn] + 1 [shock] + 1 [curse] simultaneously; fires twice |
| **Primordial** | `combat_start` | Apply [armor] 3 + [plating] 0.3 + [heal] to own side; apply [burn] 2 + [shock] 2 + [blind] 2 + [curse] to opponent |
| **Aether** | `passive` | All own elements have 30% chance to multicast on every fire (cannot chain into another multicast) |

---

## Implementation order (recommended)

1. **`data/AbilityData.gd`** — data file only, no logic. Start with agreed T2 Original Cross +
   Lightning family. Stub all remaining elements with `{}` or a `"tbd": true` marker.
2. **`systems/AbilitySystem.gd`** — execution engine:
   - `resolve_combat_start(state, is_player) -> Dictionary`
   - `resolve_on_fire(state, elem, slot, is_player) -> Dictionary` (reactive + passive checks)
   - `resolve_periodic(state, delta, is_player) -> Dictionary` (ability-specific timers)
   - `resolve_multicast(elem) -> int` (returns extra fire count; 0 = no multicast)
3. **`BattleSystem` integration** — call `resolve_combat_start()` from `to_battle()`;
   `resolve_on_fire()` after each element fires in `_tick_side()`; `resolve_periodic()` in
   `tick_battle()`.
4. **`StatusSystem` additions** — `burn_bonus: int` and `shock_bonus_stacks: int` in
   `empty_statuses()`; consume them in `tick()` and `slow_pct()`.
5. **`GameState` additions** — `frozen_slots: Array`, `_last_frozen_slot: int`,
   `ability_timers: Dictionary` (periodic ability cooldowns per slot).
6. **`TooltipCard` wiring** — read `AbilityData.get_ability(id).description` and render it.
   Implement shift-to-pin. Add keyword hover glossary.
7. **Fill remaining AbilityData entries** — run the grilling questions below to confirm pending
   proposals, then fill them in.

---

## Grilling questions remaining (continue with /grill-with-docs, 5 at a time)

All pending proposals above are suggested starting points — confirm, redirect, or skip each.
Work through in order; skip any element where no good idea exists (leave `{}` in AbilityData).

1. T2 Nature family: Bloom, Ember, Pollen, Root
2. T2 Light family: Prism, Solar, Aurora, Crystal
3. T2 Dark family: Abyss, Blight, Miasma, Shade
4. T2 Metal family: Rust, Molten, Shrapnel, Flint
5. T2 Fungus family: Sporeflow, Fireshroom, Haze, Rootrot
6. T2 Blood cross remaining: Sparkblood, Lifebloom, Hemogoblin, Nightveil, Gore, Hemospore, Frostbite
7. T2 Frost cross remaining: Black Ice, Hail, Chill, Whiteout, Wither, Tempered, Cryptbloom
8. T2 Extended-to-Extended remaining: Beacon, Lucent, Hexcore, Bloomspark, Arcbeam, Voidspark, Magnet, Rot, Wildrot, Umbra, Moldsteel
9. T2 Self remaining: Gust, Boulder, Forest, Radiance, Freeze, Ichor
10. T3 in clusters (match cluster comments in `ElementData.gd`)
11. T4 (10 elements)

---

## Suggested skills

- `/grill-with-docs` — continue deciding remaining element abilities (5 questions at a time)
- `/handoff` — update this file again after grilling is complete, before handing to implementation
- `/tdd` — write tests for `AbilitySystem.gd` before filling in all abilities
