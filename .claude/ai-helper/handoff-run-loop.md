# Handoff — Run Loop: Economy, Progression & Balance

**The road to a playable slice.** Combat content is essentially done (abilities filled, see "Done" below).
This handoff owns the *run loop*: how a run plays start → forge-gated shop rounds → meta events → win/loss,
plus balance tuning. Supersedes the retired `handoff-abilities.md` + `handoff-balance.md` (2026-06-05).

**North star (defines "playable"):** a full run plays **start-pick → forge-gated shop rounds → a meta event
every 3 → win/loss**, with forging as the progression engine. Order the work against that.

---

## Status

- **Tests: 422/422 green** (`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit`). Boot exit 0. Don't pass a single parent `-gdir` (no recurse).
- **Combat content DONE** — all element abilities filled; `on_activate` trigger + `every_n` deterministic gate (ADR 0006); decisecond model (ADR 0003); ability engine (ADR 0004). Source of truth: `data/AbilityData.gd`. Magnitudes are first-pass and a fair game for the balance work below.

---

## The work (recommended order)

### 1. Escalating reroll — ✅ DONE 2026-06-05
`ShopSystem.reroll_cost` = `REROLL_BASE_COST(2) + reroll_count`; paid rerolls increment `reroll_count` (in `GameState`), `PhaseSystem.advance_round` resets it, Shop button shows live cost. Free rerolls don't escalate/charge.

### 2. Starting pick — ✅ DONE 2026-06-05
`systems/StartSystem.gd` (`starting_options` + `apply_starting_pick`; buff = ×2 base damage via a `damage_multiplier` field read in `ElementData.effective_damage`); `StartingPickOverlay` shown in `Shop._ready` on round 1, gated by `starting_pick_done`. **Needs an F5 eyeball** (overlay layout — the logic is tested). Future: diversify options beyond plain T1s.

### 3. Forge-gated shop pool — LARGE, **grill before building**
Player's chosen direction: **Option C + relatedness filter.** Forge **3 distinct** T2s before T2s appear in the shop; once unlocked, offer only the **related** subset (the element's family + the specific T2s the player forged) rather than all ~78 T2s. Repeats per tier-step.

**Why this needs `/grill-with-docs` first — it reworks an existing system, it's not greenfield:**
- The shop is **already forge-driven**: `shop_tier` (starts 1, [GameState.gd:26](../../../data/GameState.gd)) is bumped to the result tier on forge ([ForgeSystem.gd:53-54,99-100](../../../systems/ForgeSystem.gd)); it drives the tier-probability table ([ShopSystem._tier_thresholds/_pick_tier](../../../systems/ShopSystem.gd)) **and** opponent scaling ([OpponentProvider.gd:26](../../../systems/OpponentProvider.gd)). Forging one T2 today already unlocks the whole T2 tier by probability.
- So the new model **replaces/refines `shop_tier`**, and must answer: does discovery-count become the gate? what then scales the opponent? do `shop_tier` + probability survive or get deleted?
- New `run_discoveries: Array[String]` in `GameState.create()` (per-run, empty, NOT seeded from PlayerProfile); `ForgeSystem` writes to it. Keep persistent `discovered_recipes` as the cross-run record (achievements/Compendium).
- **"Related" is undefined** — must be specified against `RecipeData` (A+B→C graph; family clusters are commented in `ElementData`). Define before building.
- **Pacing risk:** since the shop won't sell T2 until unlocked, the *only* early route to T2 is forging T1+T1 three times — a forced forge-loop. Confirm early gold (start 20g, +5/round, forge cost) supports it.

### 4. Every-3-match event — LARGE new infra, do last
A choice node every 3 rounds: pick 1 of 3 from a reward pool — **gold**, a **next-tier element**, **reduced reroll cost** (persistent run-modifier), **extra HP/Life**, a **random owned Tier-X** (to enable a Merge), etc. Needs: an event phase between rounds, a choice UI, and a reward-effect framework distinguishing **persistent run-modifiers** from **one-shot** grants. Maps to the soul's "PvE Round"/meta layer. Build after the core economy loop (1-3) works.

### 5. Grid growth 2×3 / 3×3 — balance lever, interleave with tuning
Backend is grid-agnostic via single knob `CombatState.SLOT_COUNT` (Candidate 01). Real work: **size the opponent grid from Ghost snapshots to match** (`_tick_side` iterates `grid.size()` against `SLOT_COUNT`-sized arrays) + Shop/Battle slot UI. Adjacency only gets interesting at 3×3. Resizing invalidates current cooldown/HP balance + Ghost fixtures, so do it *with* a balance pass, not before.

---

## Balance + architecture state (from retired balance handoff)

- **BalanceSystem** (`systems/`, gated by `FeatureFlags.efficiency_scoring`; dev panel in Compendium; ADR 0002): DPS Score = `effective_damage/cooldown`; **Effect Score table is T1-only** — now that all T2/T3 abilities exist, extend the table (no BalanceSystem test coverage yet).
- **Open architecture candidates** (still valid): **#3 Unify Forge interface** (10 fns / 3 return shapes → `attempt`/`preview`) — *now directly relevant to the forge-discovery work, do it alongside #3 above*; **#4** pull drag-validation out of slot components into `GameManager.can_drop()`; **#5** consolidate battle-init constants (`player_hp=30`, `gold+=5`) into named `GameState` constants (partially eased by `CombatState`, verify).
- **Infrastructure settled (don't touch):** OpponentProvider + LocalDaySeeded/GhostFixtures; AchievementSystem (pure `check()`); PlayerProfile (`user://profile.cfg`); PhaseSystem.to_battle. PlatformLayer/Steam still deferred (needs custom-engine-build decision).

---

## Combat backlog (NOT blocking playable — defer)

- **Innate Ability + Replay UI** — backend seam done (`pending_commands` + `queue_command`/`_drain_commands`/`resolve_command`). Build the in-combat moment-picker + Replay-token flow. **Blocked on designing the Innate Ability's *content*** (economy TBD).
- **T4 data fill** (10 elements) — mostly data, but ~3 need new seams: Aether (conditional "30% chance to multicast" — multicast is a static field), World Tree / Pandemic (heal-on-fire / per-stack-instant modifiers). Proposed directions table lived in the old abilities handoff; reconstruct from `ElementData` T4 entries + ADR 0004 when picked up.

---

## Map (read; don't duplicate)

- `systems/ShopSystem.gd` (transfer/reroll/tier), `systems/ForgeSystem.gd`, `data/GameState.gd`, `systems/PhaseSystem.gd` — the round/economy loop.
- `systems/OpponentProvider.gd` + `data/GhostFixtures.gd` — async opponent (keyed on `shop_tier` — see feature 3).
- `data/AbilityData.gd` / `systems/AbilitySystem.gd` — combat content (done). `data/RecipeData.gd` — forge graph (needed for "related").
- `CONTEXT.md` (vocabulary), `CLAUDE.md` → "Round lifecycle", `docs/adr/0002-0006`, `.claude/ai-helper/memory.md`.

---

## Suggested skills
- **`/grill-with-docs`** — FIRST, on feature 3 (reconcile `shop_tier` vs `run_discoveries`; define "related"; confirm the forge-loop pacing). Add new CONTEXT.md terms (Run Discovery, Starting Pick, Event node, Run Modifier).
- **`/tdd`** — build each feature test-first (this codebase is heavily tested).
- **`/improve-architecture`** — Forge-unify (#3) alongside the forge-discovery rework; grid growth.
