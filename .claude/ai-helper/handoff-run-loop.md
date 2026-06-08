# Handoff — Run Loop: Economy, Progression & Balance

**The road to a playable slice.** Combat content is essentially done (abilities filled — see Status + the ✅ items below).
This handoff owns the *run loop*: how a run plays start → forge-gated shop rounds → meta events → win/loss,
plus balance tuning. Supersedes the retired `handoff-abilities.md` + `handoff-balance.md` (2026-06-05).

**North star (defines "playable"):** a full run plays **start-pick → forge-gated shop rounds → a meta event
every 3 → win/loss**, with forging as the progression engine. Order the work against that.

---

## Status

- **Tests: 469/469 green** (`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit`). Boot exit 0. Don't pass a single parent `-gdir` (no recurse). Validate also with `godot --headless --import` then `--quit`.
- **Combat content DONE** — all element abilities filled; `on_activate` trigger + `every_n` deterministic gate (ADR 0006); decisecond model (ADR 0003); ability engine (ADR 0004). Source of truth: `data/AbilityData.gd`. Magnitudes are first-pass and a fair game for the balance work below.
- **Balance knobs centralized** in `data/TuningData.gd` (2026-06-05) — economy, progression, run/match, combat, status magnitudes (incl. ×1 placeholders). Tune here. Life loss is now proportional; player HP scales with round + `hp_bonus`. (A separate "config constants" file for engine/UI/infra is still planned.)
- **Both loop concerns resolved** (from playtest) — A (Forge requires leveled-up inputs, ADR 0008) and B (forge discoverability, ADR 0009) **landed 2026-06-07**. The loop's mechanics are now complete + legible; what remains for "final" is the **every-3 event** (feature 4) and a **balance pass** (G4).

---

## The work (recommended order)

### 1. Escalating reroll — ✅ DONE 2026-06-05
`ShopSystem.reroll_cost` = `REROLL_BASE_COST(2) + reroll_count`; paid rerolls increment `reroll_count` (in `GameState`), `PhaseSystem.advance_round` resets it, Shop button shows live cost. Free rerolls don't escalate/charge.

### 2. Starting pick — ✅ DONE 2026-06-05
`systems/StartSystem.gd` (`starting_options` + `apply_starting_pick`; buff = ×2 base damage via a `damage_multiplier` field read in `ElementData.effective_damage`); `StartingPickOverlay` shown in `Shop._ready` on round 1, gated by `starting_pick_done`. **Needs an F5 eyeball** (overlay layout — the logic is tested). Future: diversify options beyond plain T1s.

### 3. Forge-gated, family-filtered shop pool — ✅ DONE 2026-06-05 (grilled; ADR 0007)
`shop_tier` **retired**. A tier appears only after forging N distinct of it this run (`ShopSystem.TIER_UNLOCK_THRESHOLDS` = 3/2/1 for T2/T3/T4); once unlocked, shows only that tier's elements from the **families** the player forged with (`eligible_for_tier` / `_families_for_tier` via `RecipeData.ingredients_of`). T1 = full pool always (exploration + forge fuel) with a guaranteed ≥1 T1 slot; higher slots spread across families (`_pick_spread`). `run_discoveries` (per-run, forge-written) in `GameState`; `discovered_recipes` unchanged. Opponent power now scales by **round** (`OpponentProvider._max_tier_for_round`).
- **Parked for balance (player idea):** shop *size* could later increase as a player unlock — would change the 5-slot assumptions in `reroll_shop` + Shop UI.

### 4. Every-3-match event — LARGE new infra, **next: grill then build (`/grill-with-docs`)**
A choice node every 3 rounds: pick 1 of 3 from a reward pool — **gold**, a **next-tier element**, **reduced reroll cost** (persistent run-modifier), **extra HP** (→ increment `hp_bonus`, the seam is already in place), a **random owned Tier-X** (to enable a Merge), etc. Needs: an event phase between rounds, a choice UI, and a reward-effect framework distinguishing **persistent run-modifiers** from **one-shot** grants. Maps to the soul's "PvE Round"/meta layer.
- **Open design questions to grill first:** which rounds fire it (3/6/9… — before or after the shop?); the exact reward pool + values (→ TuningData); persistent-modifier model (new state fields like a `reroll_discount`, vs reusing `hp_bonus`); does a "next-tier element" reward bypass the forge gate?; is the 1-of-3 offer seeded/deterministic for Replay parity?
- **Seam already built:** `hp_bonus` (extra-HP reward) is read in `PhaseSystem._scaled_player_hp`. A reduced-reroll reward would mirror it (a `reroll_discount` field subtracted in `ShopSystem.reroll_cost`).

### 5. Grid growth 2×3 / 3×3 — balance lever, interleave with tuning
Backend is grid-agnostic via single knob `CombatState.SLOT_COUNT` (Candidate 01). Real work: **size the opponent grid from Ghost snapshots to match** (`_tick_side` iterates `grid.size()` against `SLOT_COUNT`-sized arrays) + Shop/Battle slot UI. Adjacency only gets interesting at 3×3. Resizing invalidates current cooldown/HP balance + Ghost fixtures, so do it *with* a balance pass, not before.

---

## Loop concerns to grill — resolve before the loop is "final" (raised 2026-06-05 from playtest)

Vocabulary (keep straight): **Merge** = same element + same level → level+1, no recipe; **Forge** = two elements via a `RecipeData` recipe → a new higher-tier element. **Level** (Merge axis) and **Tier** (Forge axis) are independent.

### A. Forge should require leveled-up inputs — ✅ DONE 2026-06-07 (grilled; ADR 0008)
Both Forge inputs must be **Level ≥ `TuningData.FORGE_MIN_INPUT_LEVEL` (2)**; result level = `max(1, min(inputs) − FORGE_RESULT_LEVEL_PENALTY(1))` (two Lv2 → Lv1 next tier — the **−1 penalty makes the Merge tax recur per tier**, chosen over "paid once at the base" for now, knob-tunable). Under-level forges return `level_too_low` and keep items staged (bench keeps them so the player can Merge up). Self-combos no exception. Forge gold-free (`FORGE_GOLD_COST=0` reserved). Guard + result-level helpers in `ForgeSystem._inputs_below_min_level` / `_forged_level`, applied in `_forge_pair`/`_forge_bench` + both previews; Shop.gd maps the new outcomes to messages. Merge ungated.
- **Deferred to G4 balance:** each forge now represents far more investment, so `TIER_UNLOCK_THRESHOLDS` (3/2/1) and the −1 penalty likely need re-tuning together. Also: Level 3 now has little draw beyond stats (revisit a Level-3 incentive); evaluate penalty 0-vs-1.

### C. No element should "forge no further" — ✅ DONE 2026-06-07 (grilled; ADR 0010)
Was: 24 T2 + 11 T3 **forward dead-ends** (e.g. Tempered) never used as a higher-recipe ingredient. Now: **invariant — every element below T4 is an ingredient in ≥1 higher recipe** (T4 apex exempt), so anything forges up to a Phenomenon. 22 recipes added (`RecipeData` 169→191), **cluster-routed** (frost/nature/storm/earth/blood/fungus/light-dark/metal) so connections stay thematic; mostly alt-paths, two dead-ends paired per recipe where possible. No prunes/no new elements (prism routed via the natural `prism+rain→rainbow`). Locked by `test_no_non_apex_forward_dead_ends` (+ `test_no_duplicate_recipe_pairs`).
- **Deferred to G4:** the 22 recipes widen the shop family graph (ADR 0007) + shift forge economy (ADR 0008) — rebalance there. Specific pairings are first-pass; re-theme any in G4.

### B. Forge-recipe discoverability — ✅ DONE 2026-06-07 (grilled; ADR 0009)
**Reveal all** (no discovery gating; `hidden_recipes` stays the inert seam for a later layer). Surfaces: **(1) bench hint** (`Shop._update_forge_partner_hint`, shown when one bench slot is filled) — **Made from** (reverse, pair-preserving `RecipeData.recipes_for(id)`) + **Forges with** (forward, `RecipeData.recipes_with(id)`, owned inventory+grid partners first/highlighted, hidden when empty), each element a **hoverable chip** (`_make_element_chip`) that pops the shared Item Tooltip — no card duplication; warns if bench item < Lv2 (ADR 0008); no max-height (shows all). **(2) Item Tooltip** (`TooltipCard._render_made_from`) shows a "MADE FROM" line for any T2+ element (id-guarded against battle's per-frame refresh). **(3) Compendium-from-Shop** — "📖 Compendium" button; returns via `GameManager.compendium_return_scene`. `Compendium._recipes_for` now shares `RecipeData.recipes_for`.
- **F5 eyeball:** bench hint layout (made-from + forges-with chips, hover→card), the Shop→Compendium→Shop round-trip, the Item Tooltip made-from line.

---

## Balance + architecture state (from retired balance handoff)

- **BalanceSystem** (`systems/`, gated by `FeatureFlags.efficiency_scoring`; dev panel in Compendium; ADR 0002): DPS Score = `effective_damage/cooldown`; **Effect Score table is T1-only** — now that all T2/T3 abilities exist, extend the table (no BalanceSystem test coverage yet).
- **Architecture reviews to date** (all in `reviews/`): `…20260604/05` and three on 06-07 — `…20260607.html` (#1 Forge-unify ✅), `…-b.html` (Round resolution ✅ + Shop-intake `_buy_into` ✅), `…-c.html` (7 candidates). **From -c: #1 data indexing ✅ + #2 drop seam ✅ (2026-06-09)** — `ElementData`/`RecipeData` are now `const` + lazy-indexed (zero-copy `find()`, `.duplicate()` before mutating); slots validate via `ShopSystem.can_drop`/`drag_to_loc`.
- **⭐ DEFERRED — Candidate #3 (from -c): extract `ForgePanel` from the 794-line `Shop.gd`.** A cohesive ~280-line forge sub-UI (bench + hint + chips + made-from + ~12 handlers, owns `forge_slots`) → its own `scenes/slots/ForgePanel.{tscn,gd}`; Shop keeps orchestration, panel emits state-changed/forge-done signals + `tooltip_requested` (like the other slots). **Purely structural (zero behavior change) and NOT unit-testable** — do it in a session where you can **F5-verify** the forge wiring right after. Other open -c candidates: status-presentation table, `create()`→`CombatState.reset()` dedup, shared recipe-row renderer, Shop render-churn (all Worth-exploring/Speculative).
- **Infrastructure settled (don't touch):** OpponentProvider + LocalDaySeeded/GhostFixtures; AchievementSystem (pure `check()`); PlayerProfile (`user://profile.cfg`); PhaseSystem.to_battle. PlatformLayer/Steam still deferred (needs custom-engine-build decision).

---

## Combat backlog (NOT blocking playable — defer)

- **Innate Ability + Replay UI** — backend seam done (`pending_commands` + `queue_command`/`_drain_commands`/`resolve_command`). Build the in-combat moment-picker + Replay-token flow. **Blocked on designing the Innate Ability's *content*** (economy TBD).
- **T4 data fill** (10 elements) — mostly data, but ~3 need new seams: Aether (conditional "30% chance to multicast" — multicast is a static field), World Tree / Pandemic (heal-on-fire / per-stack-instant modifiers). Proposed directions table lived in the old abilities handoff; reconstruct from `ElementData` T4 entries + ADR 0004 when picked up.

---

## GameState shape — fields added by this work (orient a fresh agent)

Per-run keys in `GameState.create()` beyond the original combat shape:
- `run_discoveries: Array[String]` — element ids **forged** this run; drives the discovery-gated shop. Written by `ForgeSystem._record_discovery`. Per-run only (not reset per round).
- `reroll_count: int` — paid rerolls this shop phase; reset in `advance_round`. Drives escalating reroll cost.
- `starting_pick_done: bool` — gates the run-start `StartingPickOverlay` (round 1).
- `hp_bonus: int` — persistent run modifier added to combat HP (reward seam for feature 4).
- `player_starting_hp: int` — the combat's starting HP, set in `to_battle`; HP-bar max.
- `shop_tier` was **removed** — opponent power is round-derived, shop pool is discovery-derived.
- An element dict may carry `damage_multiplier` (Starting Pick ×2), read in `ElementData.effective_damage`.

All balance numbers behind the above live in `data/TuningData.gd` (the single tuning surface).

---

## F5 / playtest checklist (logic is unit-tested; pixels are not)
- **Starting-pick overlay** (round 1): three T1 buttons, centered; clicking grants a ×2 element.
- **Scaling HP**: player HP climbs each round; the bar max tracks it (`%d/%d` in Shop top bar); opp bar no longer overflows.
- **Forge-gated shop**: early shop is all T1; after forging 3 distinct T2, your families' T2s appear. Dev "Tier Up" button injects discoveries to jump a tier.
- **Escalating reroll**: button shows rising cost (2,3,4…) within a phase, resets next round.
- **Continuous Life loss**: a narrow loss costs little Life; a blowout costs ~`MAX_LIFE_LOSS`.
- **Forge discoverability** (ADR 0009): one bench item shows "Made from" + "Forges with" chips; hovering a chip pops the element card; "📖 Compendium" button → Compendium → Back returns to Shop (state preserved).
- **Leveled forge** (ADR 0008): forging two Lv1s shows "Inputs must be Level 2+"; Merge to Lv2 then forge → result one level below inputs.

---

## Map (read; don't duplicate)

- `data/TuningData.gd` — **all balance knobs** (single tuning surface). `data/GameState.gd` — run state shape.
- `systems/ShopSystem.gd` (transfer/reroll/discovery pool), `systems/ForgeSystem.gd`, `systems/PhaseSystem.gd` — the round/economy loop.
- `systems/StartSystem.gd` + `scenes/shared/StartingPickOverlay.gd` — starting pick. `scenes/screens/Shop.gd` / `Battle.gd` — render + wiring.
- `systems/OpponentProvider.gd` + `data/GhostFixtures.gd` — async opponent (scales by round, not `shop_tier`).
- `data/AbilityData.gd` / `systems/AbilitySystem.gd` — combat content (done). `data/RecipeData.gd` — forge graph + `ingredients_of` (the family filter).
- `CONTEXT.md` (vocabulary), `CLAUDE.md` → "Round lifecycle", `docs/adr/0001-0010`, `.claude/ai-helper/memory.md`.

---

## Suggested skills
- **`/grill-with-docs`** — the remaining open grill is **feature 4, the every-3 event** (reward framework, persistent vs one-shot modifiers, when it fires, PvE/PvP schedule). Add CONTEXT.md terms as they settle (Event node, Run Modifier). *(Loop concerns A/B/C all resolved 2026-06-07 — ADR 0008/0009/0010.)*
- **`/tdd`** — build each feature test-first (this codebase is heavily tested).
- **`/improve-architecture`** — candidate #3 ForgePanel extraction is deferred (see above, needs F5); grid growth (feature 5).

## Next sessions (priority)
1. **G4 balance pass** — magnitudes + re-tune `TIER_UNLOCK_THRESHOLDS` vs forge cost / the −1 penalty / the 22 new C-recipes; extend the Effect Score table to T2/T3.
2. **Feature 4 — every-3 event** (north-star loop piece; grill first).
3. **Candidate #3 ForgePanel extraction** — pair with an F5 pass.
4. **F5 eyeball backlog** — starting-pick overlay, forge bench hint (made-from/forges-with chips, hover→card), Shop↔Compendium round-trip.
