---
name: balance
description: Element balance workflow for the roguelite auto-battler. Run Monte Carlo harness → read HTML report → propose safe knob changes. Use when user says "balance", "rerun the sim", "check element strength", "is X overpowered", or asks about tuning knobs.
---

# Balance

Ground truth is the sim. Never propose a knob change without rerunning after.

## Quick-start

```powershell
# Step 1 — run harness (~14 min, PowerShell ONLY — not Bash)
godot --headless -s tools/balance_harness.gd

# Step 2 — build dated HTML
python .claude/ai-helper/diagrams/_build_element_strength.py

# Step 3 — open report
start .claude/ai-helper/diagrams/element-strength-YYYYMMDD.html
```

JSON lands at `.claude/ai-helper/diagrams/_element_strength.json`. Never read a stale JSON — always rerun first if knobs changed.

## G4 targets (from memory.md / TuningData.gd)

| Metric | Target |
|--------|--------|
| Typical fight length | 10–20s KO |
| T2 unlocks | round 3–4 |
| T3 unlocks | round 7–9 |
| T4 unlocks | round 12+ |
| Win rate vs ghost pool | ~60% |
| Tier steps (cross-tier matrix) | T2>T1 ≥65%, T3>T2 ≥65%, T4>T3 ≥70% |
| Per-element Δwin outlier threshold | ±25pp = flag; ±35pp = act |

## Reading the report

**Δwin (replacement value):** how much an element's win rate shifts when swapped in vs a random same-tier replacement on same seeds. Positive = above average.

**Cross-tier matrix:** boards of pure T1/T2/T3/T4 head-to-head. Healthy = each tier consistently beats the tier below.

**Contrib ledger:** per-element HP contribution (direct + DOT + blocked). Control statuses (weaken, blind, shock, curse) have no HP ledger — their Δwin reflects fight outcome, not a contrib number.

## Known artifacts — do not overreact

| Element | Artifact | Reason |
|---------|----------|--------|
| pandemic, hemorrhage, acid | Looks weak | Synergy-dependent; tier-pure pools lack their enablers |
| photosynthesis, ember | Looks weak | Adjacency-dependent; isolated board penalises them |
| weaken, blind, shock, curse | No contrib bar | Control statuses leave no HP trace — Δwin is the only signal |
| blood (T1) | Zero contrib | Leech heals dmg_dealt; T1 blood has no direct hit so leech yields 0 |

## Knob changes — safe procedure

1. **One knob at a time.** Never stack two changes between reruns.
2. Change in `data/TuningData.gd`. All balance dials live there.
3. Rerun harness (Step 1–3 above). Compare tier steps and Δwin distribution.
4. If tier steps regress, revert and try smaller magnitude.
5. Document the change + before/after numbers in the session log before closing.

## Key knobs and what they move

| Knob | Effect |
|------|--------|
| `TIER_POTENCY_MULTIPLIER` | Tier power step — widening makes higher tiers beat lower tiers more reliably |
| `TuningData.KEYSTONE_*` | Keystone magnitudes — combat atoms injected via AugmentSystem |
| `COMBAT_COOLDOWN_MULTIPLIER` | Global fire-rate dial — lower = faster fights |
| `BATTLE_TIME_LIMIT` | Sandstorm start (seconds) — controls fight-length ceiling |
| `BASE_PLAYER_HP` / `HP_PER_ROUND` | Player HP scaling — affects Sandstorm relevance |
| Status `tick_damage_bonus` fields | Per-status DOT tuning (set via `set_status_field` combat atoms) |

## Poison dominance (known issue as of 2026-06-13)

Permanent stacks = inevitable in long fights. Poison-lineage elements (plague, sporeflow, moldsteel, pollen, rot) are consistently +25–40pp. Options (in order of preference):

1. Add a stack cap to `StatusSystem` — tune `POISON_MAX_STACKS` in TuningData.
2. Reduce `TIER_POTENCY_MULTIPLIER[2]` (T2 potency) only — narrows T2 poison without touching T3/T4.
3. Add a cleanse/counter element; check that it's in the tier-pure pool (not synergy-gated).

Always rerun after whichever lever is pulled.
