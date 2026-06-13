# Handoff — Battle-interaction & invariant test coverage — COMPLETE

**Status: DONE (2026-06-13). 692/692, import+boot 0.** Correctness coverage for how combat
mechanics *compose* in a real fight — the layer isolated unit tests miss.

**Built:** A mitigation order · B per-modifier field A/B · C curse/primer consumption · D timing
(haste/shock/freeze) · E side-isolation · F HP-conservation invariant (24-board corpus) · leech.
Tests: `test_combat_integration.gd` (A–E + leech), `test_combat_invariants.gd` (F).

**3 real bugs caught & fixed** (all invisible to isolated unit tests):
1. Curse amp double-counted on direct hits (in `direct` *and* `curse` buckets) — F.
2. `deal_damage` atom credited no Contribution bucket (supernova etc. invisible in Summary) — F.
3. Inverted haste — `haste_timers` subtracted from count-up timers, so haste *slowed* firing — D.

**Code-as-truth corrections vs the old plan:** mitigation order is `weaken→plating→armor→curse`
(not armor-first); blind is a fire-time miss (not in the damage pipeline); curse is not cleansable.

**Coverage boundary:**
- ✅ All 12 T1 effect mechanics (the cornerstone status layer every build rests on).
- ❌ Unique T2/T3/T4 abilities — intentionally NOT covered; they're expected to be **reviewed**, so
  locking them under tests now is premature. Add coverage after that review. (A few touched
  incidentally via B: blaze, steel, mountain, blackice, plasma, supernova, boulder, gust.)

**Known follow-ups (design calls, not correctness holes):**
1. `haste` status's `reduction` field is cosmetic — decide whether to wire into `effective_cooldown`.
2. `leech_heal` bypasses `suppress_heal` — a Plague-Pact "cannot heal" side still lifesteals.

Risk report: `.claude/ai-helper/reviews/battle-test-coverage-20260613.html`.
