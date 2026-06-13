# Handoff — Rework the Starting Pick into a directional "keystone" choice

## What this session decided

Replace the placeholder round-1 **Starting Pick** (offer 3 T1 elements → grant chosen one at a level head-start)
with a **directional, game-defining keystone choice** that pushes the player toward a build for the whole run.

### Settled design (locked with the user)

- **One pick per run**, hard commit (no re-spec this version).
- **Offer 4 cards at a time**, player chooses 1.
- **Pool size: ~20–30 cards.**
- Cards are **heterogeneous** — each card is keyed to **either a Family** (a T1 element's lineage, see CONTEXT.md "Family")
  **or a Status archetype** (burn / poison / armor-tank / control, etc.). Both axes coexist in the pool.
- Every card carries a combination of these dimensions (variety is the whole point — cover the matrix):
  - **flat** vs **scaling** (scales with how hard you lean into the family/archetype)
  - **pure-upside** vs **pact** (a real trade-off / constraint)
  - **shop-shaping** (weights what the shop offers) vs **amplify-owned** (buffs pieces you already have) — a card may do either or both
- **Naming: TBD.** User wants to crowdsource the name with friends. Do NOT canonise a term — use a placeholder
  (e.g. `RunKeystone` / "Starting Pick" interim) and leave the player-facing noun blank/obvious-placeholder.

### Framework chosen: **B — Structured axis slots**

Each offer of 4 should guarantee variety across the axis/dimension tags rather than pure random — at minimum
ensure both Family- and Status-keyed cards appear, and avoid 4-of-a-kind. (Originally framed as "1 Family + 1 Status
+ 1 Wildcard" for an offer of 3; generalise the same spirit to an offer of 4. Exact draw rule is implementer's call —
a tagged pool + spread guarantee is fine.)

## Seed content — 5 example cards (template, one per dimension combo)

Tags: `[axis · flat/scaling · pure/pact · shop/amplify]`

1. **Ashen Affinity** `[Fire Family · scaling · pure · shop+amplify]` — Fire-family elements appear more often; each
   Fire-family piece on board gives all your burns +1 tick damage.
2. **Plague Pact** `[Poison Status · scaling · pact · amplify]` — Poison never expires and stacks twice as fast; but you
   cannot heal or cleanse.
3. **Bulwark Oath** `[Armor Status · flat · pact · amplify]` — Permanent Armor floor + Plating never depletes; but your
   elements deal 50% less direct-hit damage.
4. **Stormcaller's Mark** `[Lightning Family · flat · pure · shop]` — Shop guarantees ≥1 Lightning-family element each
   round; your Shock slows 25% harder.
5. **Deepfreeze Doctrine** `[Frost/control Status · scaling · pact · amplify]` — Freeze lasts longer and Weaken hits
   harder the more control you stack; but all your elements run +15% cooldown.

The next agent should design the remaining ~15–25 cards to cover the 12 Families and the status archetypes, hitting
every dimension combo multiple times. Use TuningData knobs for all magnitudes.

## Open questions for the implementer

1. **Q6 — state seam (UNDECIDED, user wants pros/cons surfaced in the plan).** Reuse the Event Run-Modifier seam
   (discrete fields `hp_bonus`/`reroll_discount` in GameState) vs. build a distinct `run_keystone` layer.
   - *Share:* reuses existing additive-field pattern; Events + Pick share vocabulary. BUT that seam only models additive
     numerics — can't express suppression ("can't heal"), shop-weighting, or board-count scaling without growing anyway.
   - *Distinct:* dedicated field + own apply-hooks; more upfront code but the pact/shop/scaling variety needs hooks the
     Event seam lacks. Cleaner: Events = nudges, Pick = identity.
   - **Recommended:** distinct layer, but route any *purely-additive* card effects through the existing Run-Modifier
     fields to avoid duplication.
2. **Player-facing name** — TBD, crowdsourcing with friends. Keep a neutral placeholder in code/UI.
3. **Pact enforcement needs new hooks** that don't exist yet:
   - status *suppression* ("can't heal / can't cleanse") — no hook today
   - shop *weighting* toward a family — interacts with the discovery-gated shop pool (ADR 0007/0015,
     `ShopSystem.eligible_for_tier` / `_pick_spread`); must not break tier-unlock gating
   - whole-board cooldown / damage multipliers per-run — check `TuningData` global dials
     (`COMBAT_COOLDOWN_MULTIPLIER`, tier potency) for the right seam
4. **Scaling cards** need a "count my family/archetype on board" helper at the right calc site (combat-start setup or
   passive query).

## Doc drift to fix as part of this work

- **CONTEXT.md "Starting Pick"** (~lines 194–196) still says the chosen element is granted with **"doubled base damage."**
  That is already false in code — `systems/StartSystem.gd` grants a **level head-start** (T1 are all pure-effect, so
  ×damage is a no-op). Rewrite this glossary entry to the new keystone concept (with placeholder name).

## Key files

- `systems/StartSystem.gd` — current placeholder logic (pure fns; `starting_options`, `apply_starting_pick`). Gate
  field `state["starting_pick_done"]`.
- `scenes/shared/StartingPickOverlay.gd` — render/input overlay (CanvasLayer 115); title still says "(2× damage)".
- `scenes/screens/Shop.gd` — invokes the overlay in `_ready` (round-1 priority over EventOverlay).
- `data/GameState.gd` — `starting_pick_done` field lives here; add new keystone state here.
- `data/TuningData.gd` — `STARTING_OPTION_COUNT`, `STARTING_PICK_LEVEL`; add new knobs here (all magnitudes).
- `scenes/shared/EventOverlay.gd` + `systems/EventSystem.gd` — the parallel every-N Event system (mirror its blocking-
  overlay + seeded-offer pattern; Replay-safe seeding via `hash("event:%d"%round)`).
- `data/ElementData.gd` — Families derive from T1 ingredient lineage; `DAMAGE_DEALERS`, `scaled_potency`.
- `test/unit/systems/test_start_system.gd` — existing tests; extend.
- `CONTEXT.md` — glossary (fix Starting Pick entry; the project uses ubiquitous-language terms).
- `docs/adr/0011-...` — Event/reward framework ADR; pattern reference. Consider a new ADR for the keystone seam
  decision (Q6) since it's hard to reverse + a real trade-off.

## Constraints / house rules (from CLAUDE.md + memory.md)

- Systems/data are **pure** static GDScript — take GameState dict, return a NEW dict (no in-place mutation, no SceneTree refs).
- **Strict typing** mandatory on `systems/` and `data/`.
- Colors via `ThemeData.gd`, font sizes via `UIScale.apply` — never hardcode.
- **Descriptive naming** — no abbreviations, spell identifiers out fully.
- Determinism matters (Replay) — seed any RNG; the Event system uses `hash("event:%d"%round)`. Do the same here so the
  offer reproduces.
- Build validation before closing: `godot --headless --import` then `godot --headless --quit`; run GUT (3 leaf `-gdir`s,
  see CLAUDE.md — do NOT pass a single parent dir).
- Reporting style: ultra-concise, terse fragments.

## Suggested skills for the next session

- **/grill-with-docs** — only if the implementer hits an undecided design fork (esp. Q6); otherwise the design is settled.
- **/prototype** or **/tdd** — to build it; `test_start_system.gd` already exists, so TDD fits well.
- Consider an **ADR** (via grill-with-docs ADR flow) for the Q6 state-seam decision.

## Next after this feature (user's stated follow-up)

After the Starting-Pick rework lands, the user wants to **brainstorm the every-N Event** (the `EVENT_EVERY_N_ROUNDS`
choice node) to make it more interesting too. Out of scope for this handoff — separate session.
