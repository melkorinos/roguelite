# Handoff — Trinkets (the third Augment source)

**Status: NOT STARTED.** Parked deliberately to build out battle-interaction test coverage first
(user's call). Pick this up only after the test-coverage pass lands.

## What a Trinket is

The **third `source_type` of an Augment** (ADR 0016), after **Keystone** (Starting Pick) and
**Event Reward**. The whole seam already exists and trinkets reuse it wholesale — do NOT build a
new mechanism. See `docs/adr/0016-augment-scoped-atom-seam.md`, the **Augments** section of
`.claude/ai-helper/memory.md`, and `systems/AugmentSystem.gd`.

A Trinket = `{ id, name, source_type: "trinket", effects: [atoms], ...presentation }`, added to
`state["augments"]` via `AugmentSystem.add_augment`. Its scope-tagged atoms apply at their own
sites automatically (run_state / shop_gen / combat / round_result). Nothing new is needed to make
a trinket *work* — only to **acquire** it and to author its content.

## How Trinkets DIFFER from Keystones (the design delta)

- **Acquired by Draft, not the Starting Pick.** The **Draft** (see `CONTEXT.md` glossary) is the
  free per-round selection of Items/Trinkets, separate from the gold shop. Keystones = one hard
  commit at round 1; Trinkets = collected over the run.
- **Held as in-combat effect sources**, plural — you accumulate several, vs the single Keystone.
- **First consumer of the `round_result` scope.** `AugmentSystem.apply_round_result` +
  `bonus_gold_on_result` already exist and are wired in `PhaseSystem.advance_round`, but NO
  content uses them yet — a "+N gold on win/loss" trinket is the intended first user.

## Hard constraints (already decided this session — do not relitigate)

- **FLAT INTEGERS, no percentages.** ADR 0003 integer combat model. Late-game relevance comes from
  `scale_by` (per-unit `value`/`amount` × an integer board count: `family_count` / `family_levels`
  / `board_size` / `round`), resolved in `AugmentSystem.apply_combat_start`. See the Fork-2/Fork-1
  discussion crystallised in ADR 0016's Consequences.
- **Reuse the existing atom vocabulary**: `set_status_field`, `set_side_field`, `suppress`,
  `shop_weight`, `bonus_hp` / `bonus_hp_percent` / `reroll_discount`, `bonus_gold_on_result`.
  Combat atoms ARE ability atoms (`AbilitySystem.ATOM_SCHEMAS`).
- All magnitudes → `TuningData` (mirror the `KEYSTONE_*` block with a `TRINKET_*` block).
- Validate every trinket's atoms via `AugmentSystem.validate_atom`; lock the roster with a data
  test mirroring `test/unit/data/test_keystone_data.gd`.

## User's example trinkets (from this session — seed content)

- Buff all fire damage — "stack more / tick faster" → `set_status_field` on burn (flat or scaling).
- +max HP → `bonus_hp` (run_state). (Was "+20%"; reframe flat per the no-% rule.)
- Light elements appear more often → `shop_weight` family=light.
- +N gold on win OR on loss → `bonus_gold_on_result` (round_result) — the new scope's first use.

## Open design questions for the Trinket session

1. **Draft UX** — how trinkets are offered/picked each round (the Draft node), how many on offer,
   and how it coexists with the every-N Event + the shop. (Draft is currently a glossary term only,
   not built.)
2. **How many Trinkets can you hold?** A cap, or unbounded? Affects balance + UI.
3. **Combat-passive vs activatable.** Keystone combat atoms are passive (applied at combat_start).
   Do any trinkets want an *activated* combat effect (a new trigger), or stay passive?
4. **`round_result` atom kinds** — is `bonus_gold_on_result` enough, or do trinkets want more
   (e.g. on-win HP, on-loss refund)? Add kinds to `AugmentSystem.ATOM_SCHEMAS` as needed.
5. **A Trinket Compendium tab** — mirror the Keystones tab added to `scenes/screens/Compendium.gd`.

## Key files

- `systems/AugmentSystem.gd` — the seam (scopes, validate, add_augment, scale_by, apply_*).
- `data/KeystoneData.gd` + `test/unit/data/test_keystone_data.gd` — the pattern to mirror for a
  `TrinketData.gd` roster + lock test.
- `systems/PhaseSystem.gd` — `advance_round` already calls `apply_round_result`.
- `scenes/shared/StartingPickOverlay.gd` — the heterogeneous-card overlay pattern (for a Draft UI).
- `scenes/screens/Compendium.gd` — TabBar pattern (add a Trinkets tab).
- `CONTEXT.md` — **Draft**, **Trinket**, **Augment** glossary terms.

## Suggested skills for the Trinket session

- **/grill-with-docs** — to settle the Draft UX + the open questions above before building; the
  acquisition model is genuinely undecided (a real fork), unlike the seam (already settled).
- **/tdd** — once the design is locked; `test_keystone_data.gd` + `test_augment_system.gd` give a
  ready template for the data-lock + scope tests.

## Do NOT

- Re-introduce percentages, a second modifier mechanism, or a per-source apply() path.
- Start before the battle-interaction test-coverage pass is done (current focus).
