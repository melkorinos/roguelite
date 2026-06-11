# Handoff — Run Loop & Balance (single tracker)

The live tracker for the run loop + balance. **Merged 2026-06-11** from `handoff-run-loop.md` +
`handoff-grid-growth.md` (latter deleted). Completed-feature detail is NOT repeated here — it lives in
`log.md` (chronological) and `docs/adr/` (decisions). This file keeps only **forward-looking context**:
what's shipped (as pointers), what's ready to pick up, and the open balance/polish work.

**North star (defines "playable"):** a full run plays **start-pick → forge-gated shop rounds → a meta
event every 3 → win/loss**, with forging as the progression engine. That loop is now **structurally
complete**; what remains is balance tuning + F5 polish + the deferred backlog.

---

## Status
- **Tests: 551/551**, import+boot 0. Validate: `godot --headless --import` then `--quit`; suite:
  `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit` (3 leaf `-gdir`s — no parent, no recurse).
- **All balance knobs** live in `data/TuningData.gd` (single tuning surface). Run-state shape in
  `data/GameState.gd`.

## Shipped (pointers — see ADR + log for detail; do not re-explain here)
- **Run loop:** starting pick, escalating reroll, forge-gated family shop (0007), leveled-input forge
  (0008), recipe discoverability (0009), no forward dead-ends (0010), every-3 Event + rewards (0011).
- **Combat:** ability engine + events (0003/0004), `on_activate`/`every_n` (0006), Sandstorm sudden-death
  (0012), damage archetypes + level-scaled effects (0013), in-combat Status Tray.
- **Board:** Grid Growth (0014) — per-run +1 slot on T2-Lv2 (5th) / T3-Lv2 (6th); per-side combat array
  sizing; round-scaled opponent board (`OPPONENT_SLOTS_ROUND_BREAKS=[1,3,5,8]`).
- **Arch:** data indexing + drop seam, Round-resolution unification (`PhaseSystem.resolve_round`),
  ForgePanel extraction, `EffectRegistry` as the single effect→presentation source.

---

## Ready for pickup
1. **G4 balance pass** — the headline. Decisions locked (below); tune empirically via
   `BattleSystem.simulate_battle()`. Start with an element-stat sim sweep + the opp-HP plateau fix.
2. **F5 eyeball backlog** — logic is unit-tested, pixels are not (checklist below).
3. **Arch cleanups (small, unit-testable, no design needed):** `create()`→`CombatState.reset()` dedup;
   shared recipe-row renderer; Shop render-churn; the deferred review-#6 items (Status field readers,
   `PhaseSystem.result_text`, combat-name constants, EffectRegistry-canonical status schema; smaller:
   undo-capture leak, Ghost factory, DPS math).
4. **PlatformLayer autoload** (SteamAdapter + NoOpAdapter for web) — last Steam seam, self-contained, no
   backend needed.

## Deferred / blocked (not ready — design or seam missing)
- **Innate Ability + Replay UI** — backend seam done (`pending_commands` + `queue_command`/
  `_drain_commands`/`resolve_command`); **blocked on designing the Innate Ability's content + economy**.
- **T4 data fill** (10 elements) — mostly data, but ~3 need new seams (Aether conditional multicast;
  World Tree / Pandemic heal-on-fire / per-stack modifiers). Reconstruct directions from `ElementData` T4
  entries + ADR 0004.
- **Faction threshold synergies**, **Draft (Items/Trinkets)**, **Meta-progression shape** — not started,
  larger design grills.
- **`trinket` + board-wide `damage_bonus` Event rewards** — no system/seam yet (ADR 0011 deferred).

---

## G4 balance pass — decisions locked (grilled 2026-06-09), tuning pending
**Method:** empirical via `BattleSystem.simulate_battle()` (deterministic; no BalanceSystem — ADR 0002 was
never built/superseded; an analytical scorer could complement the sim later if ever wanted). **Targets:**
run ~12–18 rounds to 10 wins; fights KO ~10–20 s (Sandstorm guarantees resolution); forge climb
T2~r3–4 / T3~r7–9 / T4~r12+; keep `FORGE_RESULT_LEVEL_PENALTY`=1 (lower `TIER_UNLOCK_THRESHOLDS` if sims
stall); status magnitudes stay ×1; opponent ~60% win-rate for a decent board; Lv3 = a stat-payoff knob
bump (not a new mechanic). **Done-when:** defensible first-real numbers + one full-run F5, not perfection.

- **Applied 2026-06-09 (NOT final, paused for playtest):** `BASE_PLAYER_HP`/`OPPONENT_BASE_HP` 200→130,
  `HP_PER_ROUND` 3→**11**, new `COMBAT_COOLDOWN_MULTIPLIER`=**0.7** (global firing-rate dial). Sweep: early
  KOs mostly in-window; late game r7–11 dipped ~33–46%.
- **Batch 3 PROPOSED, not applied:** `HP_PER_ROUND` 11→13 (recenter r9≈50%); optional
  `COMBAT_COOLDOWN_MULTIPLIER`→0.65.
- **⚠ Opp-HP plateau:** `compute_opponent_hp` ignores element *level* (and historically board size) → late
  curve can't sit at 50% via `HP_PER_ROUND` alone. **Fix:** make it level-aware / round-scale (deferred
  review candidate B). Grid Growth's round-scaled opponent board now adds slots but HP still ignores level.
- **Pending levers:** element base `damage`/`cooldown_deciseconds`; status magnitudes (×1); forge economy
  (`TIER_UNLOCK_THRESHOLDS`/penalty + the 22 ADR-0010 recipes); **Grid Growth break rounds**
  (`GRID_GROWTH_TRIGGERS` + `OPPONENT_SLOTS_ROUND_BREAKS`); Event reward magnitudes (`EVENT_*`); run/Life/
  gold economy; Lv3 incentive.

---

## F5 / playtest checklist (consolidated)
- **Grid Growth:** the 5th slot appears the moment you reach a T2 Lv2 (merge/forge), 6th on T3 Lv2; Shop
  Battlegrid lays out at 5/6 slots; Battle shows asymmetric player/opponent boards without overflow.
- **Event overlay** (rounds 3/6/9): 3 reward cards, hover, picking each kind applies + re-renders; no
  double-fire on Shop→Compendium→Shop.
- **Starting-pick overlay** (round 1): three centered T1 buttons; pick grants the buffed element.
- **Sandstorm:** post-30 s both HP bars drain to a KO (no visual yet — confirm the mechanic resolves).
- **Forge UX:** bench "Made from / Forges with" chips (hover→card); Shop↔Compendium round-trip preserves
  state; leveled-forge messaging ("Inputs must be Level 2+").
- **Scaling HP / reroll / Life:** HP bar max tracks round; reroll cost rises then resets; Life loss scales
  with margin.

## Map (read; don't duplicate)
- `data/TuningData.gd` (knobs) · `data/GameState.gd` (run shape) · `data/CombatState.gd` (per-slot/per-side
  factory).
- `systems/` : `ShopSystem`/`ForgeSystem`/`PhaseSystem` (loop+economy, growth hook in
  `ForgeSystem.apply_grid_growth`), `GridSystem` (size/adjacency), `OpponentProvider` (round-scaled board),
  `EventSystem`/`StartSystem`, `AbilitySystem`/`StatusSystem` (combat), `BattleSystem.simulate_battle`.
- `scenes/screens/` : `Shop.gd`/`ForgePanel.gd`/`Battle.gd` (render + dynamic `columns`).
- `CONTEXT.md` (vocab) · `CLAUDE.md` "Round lifecycle" · `docs/adr/0001-0014` · `memory.md`.

## Suggested skills
- **`/tdd`** — every feature here is test-first; the suite is the safety net.
- **`/grill-with-docs`** — for the blocked design work (Innate Ability content, Faction synergies, Draft,
  Meta shape) before coding.
