# Handoff — Elements / Abilities / Forge: review + recipe rebalance (continue iterating)

**Date:** 2026-06-12 · **Repo:** `e:\desktop\game\roguelite` (Godot 4.6, GDScript) · **Branch:** main
**Next session goal:** do more iterations on element/ability/forge balance — primarily the **ability layer** (the recipe layer was just rebalanced). Use the interactive HTML review as the working surface; regenerate it after data changes.

---

## 0. Read first (project ritual)
Per `CLAUDE.md`, at session start read the five ai-helper files: `soul.md`, `memory.md`, `goals.md`, `log.md`, `reflections.md`. The relevant settled facts for THIS work live in `memory.md` → "Element system (132 elements, 191 recipes, 4 tiers)" and "Ability System". The newest log entry (`.claude/ai-helper/log.md`, **2026-06-12**) summarizes the rebalance — read it; this doc does not duplicate it.

---

## 1. What this work covered
A player-facing **review of every element, ability, and forge combination** + a **recipe rebalance** to fix forge-convergence skew. Two phases:

1. **Review artifact** — built an interactive HTML dashboard of the full roster (elements, recipe in/out-degree, damage-dealers, ability summaries, status mechanics) plus a vis-network forge graph, so the designer can give feedback.
2. **Recipe rebalance** — acted on the #1 finding: T3 recipe convergence was wildly uneven. Landed and validated (567/567 tests).

---

## 2. Artifacts (DO NOT duplicate — open/regenerate these)
All in `.claude/ai-helper/diagrams/` (untracked dir):

| File | What |
|------|------|
| `game-elements-forge-20260611.html` | **The review.** Interactive: vis-network forge graph (toggle tier⇄family colour, tier filter, search, physics), sortable/filterable 132-element roster, recipe-imbalance tables, damage-dealer table, status & ability mechanics glossary, flagged-observations section. **Already regenerated against post-rebalance data** (shows zero single-gated T3). |
| `game-mechanics-20260611.html` | Pre-existing companion (Shop/Battle/Damage pipeline/Status/knobs map). Not mine; useful context. |
| `_build_elements_review.py` | **Regenerator** for the review HTML. Parses the live `.gd` data (no manual numbers → never drifts). Run after any data change: `python .claude/ai-helper/diagrams/_build_elements_review.py` |

**To refresh the review after editing data:** just re-run `_build_elements_review.py`. It re-reads `ElementData.gd` / `RecipeData.gd` / `AbilityData.gd` / `EffectRegistry.gd` and rewrites the HTML. Open with `start .claude/ai-helper/diagrams/game-elements-forge-20260611.html`.

---

## 3. The recipe rebalance that landed (in `data/RecipeData.gd`)
Full rationale + numbers are in the **2026-06-12 log entry**; the git diff of `RecipeData.gd` is the authoritative change list. Summary:

- **Problem:** 14 of 32 T3 reachable by exactly ONE recipe (all original-cross results: cloud/geyser/fog/storm/plant/swamp/brick/ash/acid/obsidian/volcano/sand/sandstorm/clay) while extended-family clusters + every T4 were 4–6-path sinks (Meteorite=6).
- **Fix (count held 191 → 191, redistribute not inflate):**
  - Each single-gated T3 got a **2nd path** (new original-cluster pairs; `arc+surge` **rerouted** off Tempest → Storm). The 14 new/rerouted lines are in one commented block at the end of the RECIPES array ("Tier 3 — second paths (recipe rebalance 2026-06-11)").
  - Removed **13 freely-removable** redundant paths from the worst sinks (floored each at 3).
- **Outcome:** T3/T4 in-degree spread **[1–6] → {2:17, 3:22, 4:2, 5:1}**. Remaining ≥4: Meteorite(5, sole metal-T3 → structurally forced), Glacier(4, test-locked), Ancient Grove(4).

### Invariants the rebalance preserved — the next agent MUST keep these (locked by tests in `test/unit/systems/test_forge_system.gd`)
- **Forward (the designer's hard rule):** every element tier<4 is an ingredient in ≥1 recipe → every T2 forges into a T3, every T3 into a T4. (`test_no_non_apex_forward_dead_ends`, line ~541)
- **No duplicate (order-independent) recipe pairs.** (`test_no_duplicate_recipe_pairs`, ~569)
- **Named locks:** `recipes_for("glacier")` must keep freeze+permafrost, blackice+permafrost, sea+freeze and size ≥3; `recipes_for("tempered")` must stay **exactly** frost+metal (do NOT add a recipe producing tempered). Roster stays 132, first=water, last=aether.
- **One-tier-up:** every recipe result is exactly one tier above both ingredients (T2+T2→T3, T3+T3→T4). All current recipes satisfy this; keep it.

---

## 4. Open work for the next iterations (priority order)
The **ability layer was NOT touched** — this is the meat of the next session. Findings are visible in §7 of the HTML review:

1. **7 duplicate-ability pairs** — identical trigger + identical effects, differing only in cooldown/flavour. Differentiate or merge each:
   `Lava≡Molten`, `Radiance≡Whiteout`, `Prism≡Beacon`, `Hemorrhage≡Hemospore`, `Ironwood≡Tempered`, `Carnage≡Voltspore`, `Acid≡Tempest`.
2. **Voltspore is dead** — pure-effect element (not a damage-dealer) with `"effects": []` + "fires twice" → does literally nothing. Give it a real on-fire effect.
   Also verify **Acid** and **Tempest** (`"effects": []` passives describing no-regen / no-decay) are actually wired in `systems/AbilitySystem.gd` / `StatusSystem.gd` — they may be described-but-unimplemented.
3. **All 10 T4 "Phenomena" are ability-stubbed** — base damage only, no `AbilityData.ABILITIES` entry. The payoff tier is the least designed. Design abilities for them (memory.md notes this was deferred to "a later session" — this is that session, if the designer wants).
4. **(Optional) further recipe tuning** — Meteorite is still 5-path because it's the only metal T3 (7 orphan metal T2s route through it). If the designer wants it lower, the only real fix is structural (more metal T3 sinks / re-theme), which means touching the fixed 132-roster — discuss before doing.

Files for the ability work: `data/AbilityData.gd` (pure data, keyed by element id) + `systems/AbilitySystem.gd` (execution) + `data/EffectRegistry.gd` (per-effect metadata). Ability schema + trigger vocabulary documented in `memory.md` "Ability System" and `docs/adr/0004-ability-system-architecture.md`. `AbilityData.trigger_label()` is the single source for trigger display.

---

## 5. How the analysis was done (so you can replicate / extend)
The HTML generator (`_build_elements_review.py`) does this and is the template to extend:
- The `.gd` data consts are **JSON-ish** (quoted keys, `true/false`, trailing commas, `#` comments). The script strips comments + trailing commas and `json.loads` them — no Godot needed for analysis. (When `exec`-ing the build script from another py file, open it with `encoding="utf-8"` — it contains emoji.)
- Computes: recipe **in-degree** (recipes that PRODUCE an element — the "single-gated" axis), **out-degree** (recipes it FEEDS — the "used in 7-8 combos" axis; T1 each feed 12), **family** (dominant T1 root traced through the recipe tree), damage-dealer flag (`ElementData.DAMAGE_DEALERS`, 22 ids), ability trigger/effects, status mechanics (from `systems/StatusSystem.gd`).
- For a recipe edit, validate offline BEFORE running Godot: re-parse `RecipeData.gd` and assert the §3 invariants (dup pairs, forward dead-ends, one-tier-up, named locks). This catches most breakage in seconds. (The throwaway validate/patch scripts were deleted after use; the generator is enough to recompute degrees.)

---

## 6. Gotchas / environment
- **godot is NOT on the bash PATH** but IS at `C:\Users\Dimitris\bin\godot.cmd` → call it from the **PowerShell** tool (PATHEXT resolves `godot`), not the Bash tool.
- **`steam+mud` is the canonical "no-recipe" sentinel** in 4 forge tests (`_state_with_bench("steam","mud")`). Never make steam+mud a real recipe. (Cost me a test-fail mid-session; fixed by using `smoke+sea→fog` instead of `mud+steam→fog`.) When adding recipes, grep the tests for your chosen pair.
- **Repo has unrelated in-flight changes from a parallel session** (Contribution Bars work): `CombatState.gd`, `Battle.gd`, `AbilitySystem.gd`, `BattleSystem.gd`, `ThemeData.gd`, `SettingsManager.gd`, `EffectRegistry.gd`, `StatusSystem.gd`, `test_battle_system.gd`, `test_status_system.gd`, `test_diag_oddity.gd.uid` are **NOT part of this task** — don't fold them into a recipe/ability commit. My footprint = `data/RecipeData.gd` + `.claude/ai-helper/diagrams/` + the 2026-06-12 `log.md` entry only.
- Reporting style for this repo: ultra-concise, fragments over sentences (per `CLAUDE.md`).

---

## 7. Validation commands (run before closing any task)
From PowerShell (godot resolves there):
```
godot --headless --import     # compile, expect exit 0
godot --headless --quit       # boot, expect exit 0 (ObjectDB-leak warning is benign)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit
```
Current baseline: **567/567 passing**, import+boot 0. (Note: `-gsuffix` unsupported; pass the three leaf `-gdir`s, never one parent dir.)

---

## 8. Suggested skills for the next session
- **`/grill-with-docs`** — before changing ability designs, get grilled on intent (the designer prefers being asked 5+ questions per turn during design; see memory). Good for scoping the ability dedup + T4 fills.
- **`/tdd`** — for the ability changes (AbilitySystem has dense test coverage; red→green slices fit well).
- **`/code-review`** (or `/improve-architecture` if structure shifts) — after the ability pass.
- Re-run **`_build_elements_review.py`** after any data edit and eyeball the HTML to confirm the change reads as intended.

---

## 9. One-line state
Recipe convergence fixed (no single-gated T3, spread compressed, 191 recipes, forward invariant intact, 567/567). Ability layer is the next lever: 7 dup pairs + dead Voltspore + 10 T4 stubs. Review HTML is the cockpit; regenerate it after edits.
