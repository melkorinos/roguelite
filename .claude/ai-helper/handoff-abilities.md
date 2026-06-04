# Handoff — Element Ability System

Ability design + implementation for the element roster. Core build + two architecture-review passes have
shipped. **`data/AbilityData.gd` is the source of truth for per-element abilities; this doc is the map and
what's left.** Older proposal tables (now implemented) were removed — read the code for current behaviour.

---

## Status — 2026-06-04 (authoritative)

**Shipped & tested — 378/378 green, boot exit 0:**
- Integer **decisecond** time model (ADR 0003): field is `cooldown_deciseconds`; effective CD floored at 10
  (one fire/sec), shock-slow rounded. No decimals in combat design values; blind = integer %, plating = integer.
- `systems/AbilitySystem.gd` (ADR 0004): resolve_combat_start / periodic / reactive (depth-1) / multicast /
  passive-on-hit / timed commands; combat-event factories. Wired into `to_battle` + `tick_battle`.
- `data/AbilityData.gd`: T2+T3 filled (~10 skipped, below); **T4 stubbed**. Includes conditional (`when`)
  effects and chance-gated reactives.
- `StatusSystem`: curse `{ticks_remaining, is_permanent, damage_amplifier}`; modifier fields
  (`burn/poison.tick_damage_bonus`, `shock.effective_stack_bonus`, `plating.reduces_dot`, `armor.floor`,
  `weaken.duration_bonus`, `haste.reduction_bonus_deciseconds`, `leech.{bonus,double}`); signed
  `cooldown_modifier_deciseconds`; `tick()` emits tick events; integer blind %.
- `systems/GridSystem.gd` (dimensions + orthogonal neighbors) + `systems/CombatSide.gd` (one side→state-key map).
- Freeze: per-side `player_frozen_seconds` / `opponent_frozen_seconds` (+ `*_last_frozen_slot`), paused-CD,
  anti-permalock (`BattleSystem.select_freeze_target`).
- **Combat events**: `AbilitySystem.fire_event / miss_event / trigger_event`; `battle_events` = fire/miss only.
- Adjacency: `adjacency_upgrade` reactives gated by `FeatureFlags.combat_adjacency` + `GridSystem.neighbors`.
- Seeded `combat_rng_state` (per round) → reproducible combat/Replay; blind + on-hit passives draw from it.
- Innate/Replay backend seam: `pending_commands` + `queue_command` / `_drain_commands` / `resolve_command`.
- Tooltip + Compendium show abilities; tooltip live-updates battle stats + keyword glossary (shift-to-pin,
  `data/StatusGlossary.gd`). All `FeatureFlags` default true.

**Pending — prioritised:**

1. **~10 skipped abilities** (`get_ability` returns `{}`), each needs a NEW engine capability:
   - *strip-a-status-value effect* (reduce opponent plating per tick): shrapnel, rootrot, moldsteel.
   - *bonus-damage-vs-condition at the hit site*: gore (+dmg vs weakened), ancientgrove (+dmg while HP>50%).
   - *damage-output modifier* (no per-attacker model yet): ash (blind → less dmg).
   - *every-N-ticks counter*: rot (poison grows every 5 ticks).
   - *random-positive-status pick*: rainbow. *heal-amount modifier*: plant (+1). *cleanse/heal-efficiency
     debuff*: voidrift.
   - Next seams to add: a `strip_status` effect kind; a hit-site outgoing-damage modifier (mirror of the
     combat_start passive-modifier layer); an `every_n_ticks` counter on tick events.
2. **Grid growth 2×3 / 3×3** — backend is grid-agnostic (loops `grid.size()`, `GridSystem`, `CombatSide`),
   but the live grid is 4 slots. Widen the per-slot arrays in `GameState`/`PhaseSystem`, `create_opponent_grid`,
   and the Battle/Shop slot UI. Adjacency only gets interesting at 3×3.
3. **Innate Ability + Replay UI** — backend seam done; build the in-combat moment-picker and the Replay-token flow.
4. **T4 data fill** (10 elements) — pure data; engine already supports multicast 3× and every trigger.

---

## Map — where things live (read these; don't duplicate them here)

- `data/AbilityData.gd` — per-element abilities (source of truth). Effect/trigger schema in the `AbilitySystem` header.
- `systems/AbilitySystem.gd` — engine + the combat-event / effect / trigger vocabulary (read its header comment).
- `systems/BattleSystem.gd` — `tick_battle`, `_tick_side`, `_fire_element_once`, `_apply_element_effect`.
- `systems/StatusSystem.gd` — statuses + `effective_cooldown_deciseconds`. `systems/CombatSide.gd`, `systems/GridSystem.gd`.
- `CLAUDE.md` → "Round lifecycle" — the shop→battle→result flow. `CONTEXT.md` — canonical vocabulary.
- `docs/adr/0003-*` (decisecond model), `docs/adr/0004-*` (ability system + combat events). `.claude/ai-helper/memory.md`.

---

## Core design rules (load-bearing — don't relitigate)

- **Depth-1**: a reactively-triggered ability may deal damage / apply status but emits no further reactive
  events and never multicasts. Caps every synergy chain at one hop. Scan order slot 0…N, deterministic.
- **Multicast**: repeats the full cooldown fire N× (T2/T3 cap 2×, T4 cap 3×). Each repeat is an independent
  reactive trigger (1 multicast = 2 synergy triggers). Periodic / combat_start never multicast. Echo cut from v1.
- **Effects** = array of atomic `{kind, …, target}`. Buffs → own side, debuffs → opponent. Optional `when:[…]`
  condition guard; reactives may carry a `chance` (rolled vs the seeded RNG). Passive stat modifiers are set as
  status fields at combat_start and read at calc sites.
- **Curse**: amplifies DOT (+1) and adds `damage_amplifier` flat vulnerability on the cursed side;
  `is_permanent` ignores tick-down until cleansed.
- **Freeze** is per-slot combat state, not a Status; cleansable; anti-permalock.
- **One ability per element** for v1. Combat is deterministic (same board + seed → same result).

---

## T4 — proposed directions (NOT built; for the data-fill task)

T4 = the most powerful single ability per element; multicast 3× available; compound / board-wide expected.

| Element | Trigger | Proposed ability |
|---|---|---|
| **Ice Age** | combat_start | Freeze ALL opponent elements 5s; opponent CDs +2s |
| **Maelstrom** | periodic 3s + 2× | 2 [shock] + 2 [weaken] |
| **Tectonic** | combat_start | [armor] 8 + [plating] 4 own; 5 bonus damage |
| **Supernova** | periodic 4s + 2× | 3 [burn] + 2 [blind]; `burn.tick_damage_bonus` +2 |
| **Singularity** | combat_start | permanent [curse]; opponent CDs +1.5s; 3 bonus damage |
| **World Tree** | passive | own elements heal 1 on fire; [heal] effects +3 |
| **Pandemic** | passive + 2× | [poison] tick +2; each new stack deals +1 instant |
| **Ragnarok** | periodic 3s + 2× | 5 bonus damage; 1 [burn] + 1 [shock] + 1 [curse] |
| **Primordial** | combat_start | [armor]3 + [plating]3 + [heal] own; [burn]2+[shock]2+[blind]2+[curse] opp |
| **Aether** | passive | 30% chance to multicast on fire (cannot chain into another multicast) |

Deferred T4 seed concepts: **Nebula** (stellar gas / star birth — vs Supernova = death); **Void Absolute**
(total erasure of light — distinct from Singularity = matter collapse).

---

## Suggested skills
- `/grill-with-docs` — design the ~10 skipped abilities + their seams, or T4. `/tdd` — build test-first.
- `/improve-architecture` — next structural deepenings (grid growth, outgoing-damage modifier layer).
