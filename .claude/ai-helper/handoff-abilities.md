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
- Tooltip + Compendium show abilities; Compendium also shows a per-ability **trigger line** (e.g. `Every 5s ×2`,
  `Combat start`, `On [burn]`, `Passive`) via `Compendium._trigger_label` + `TRIGGER_LABELS`. Tooltip live-updates
  battle stats + keyword glossary (shift-to-pin, `data/StatusGlossary.gd`). All `FeatureFlags` default true.

**Pending — prioritised:**

1. **10 skipped abilities** (`get_ability` returns `{}`): 5×T2 (shrapnel, rootrot, gore, rot, moldsteel) +
   5×T3 (rainbow, plant, ash, ancientgrove, voidrift). Two designs proposed per element (2026-06-04): an
   **A = ships-today** version (existing effect kinds + `when`-guards, zero engine work) and a **B = needs-seam**
   version (more on-theme, costs a new capability). All 10 can ship today if every A is chosen. Proposals:

   | Element | A — ships today | B — needs seam |
   |---|---|---|
   | shrapnel 💥 | combat_start: 3 dmg + 2 [weaken] | periodic 3s: strip 1 [armor]+1 [plating] |
   | rootrot 🍂 | periodic 5s: 2 [poison]; +1 [weaken] if opp has [armor] | periodic 4s: 2 [poison] + strip 1 [armor] |
   | gore ⚔️ | periodic 4s: 3 dmg; +3 more if opp [weaken]ed | passive: +1 dmg vs [weaken]ed opponents |
   | rot 🌵 | on_poison_tick 30%: +1 [poison] | every 5th [poison] tick: +2 [poison] |
   | moldsteel 🗜️ | on_armor_stripped: 2 [poison] | periodic 4s: strip 1 [plating] + 2 [poison] |
   | rainbow 🌈 | combat_start: 1 each [armor]/[heal]/[cleanse]/[haste] own | periodic 4s: random positive status own |
   | plant 🌿 | periodic 6s: [heal] 4 + 1 [cleanse] own | passive: all [heal] +1 |
   | ash ⚫ | on [blind] applied: also 1 [weaken] | passive: [blind]ed opp deals −1 dmg |
   | ancientgrove 🍀 | periodic 8s: [heal] 4 + 1 [armor] own | passive: +1 dmg while own HP > 50% |
   | voidrift 🪐 | combat_start: 1 permanent [curse] + 2 [blind]; opp CDs +0.5s | combat_start: opp [heal]/[cleanse] 50% weaker |

   **Consolidated seams** (only needed if a B option is chosen):
   - `strip_status` effect kind — remove N stacks of a status (mirror of `apply_status`). *small.* → shrapnel/rootrot/moldsteel B
   - **hit-site outgoing-damage modifier** — per-attacker +/− dmg at `compute_incoming_damage`, gated by a
     condition (target [weaken]ed / own HP>50% / attacker [blind]ed). No per-attacker model yet. *large.* → gore/ash/ancientgrove B
   - `every_n_ticks` counter on tick events. *small-medium.* → rot B
   - `random_status` pick-from-list effect (seeded RNG already exists). *small.* → rainbow B
   - heal-amount modifier field, read at heal application. *small.* → plant B
   - heal/cleanse efficiency debuff, scaled at apply-time on opponent. *medium.* → voidrift B
   - (ancientgrove B also needs an own-HP `when`-condition kind alongside the hit-site modifier.)
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
