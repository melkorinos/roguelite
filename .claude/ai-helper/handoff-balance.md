# Handoff — Steam + Async PvP Infrastructure

**Date:** 2026-06-02  
**Picking up from:** Architecture review + grill session (Steam/async PvP readiness)  
**Status:** Partially complete — see build plan below for current state

---

## What was decided this session

### Architecture review
Architecture review was conducted this session (report file since deleted).  
5 candidates identified; 3 are in scope to build now (no backend or custom engine build required).

### Grill session — all decisions settled

All design decisions recorded in [.claude/ai-helper/memory.md](memory.md) under "Steam + backend seams". Summary of key choices:

**OpponentProvider**
- Pure static class `systems/OpponentProvider.gd`
- `static func get_opponent(context: Dictionary) -> Dictionary` returns a full Ghost snapshot
- Context: `{"day": int, "round": int, "shop_tier": int}`
- LocalDaySeeded adapter: filter ElementData by `shop_tier`, seed with `hash(date_string + str(round_num))`
- `PhaseSystem.to_battle()` signature changes to `to_battle(state, opponent_snapshot: Dictionary)`; Battle.gd calls OpponentProvider first

**AchievementSystem**
- Pure static `AchievementSystem.check(state, profile, event: String) -> Dictionary` in `systems/`
- Returns updated profile dict — no side effects inside the function
- Events: `"round_win"`, `"round_loss"`, `"match_win"`, `"match_eliminated"`, `"forge_discovered"`
- Also merges current-match `discovered_recipes` into profile on every call
- Damage accumulates on both `round_win` and `round_loss`
- First 5 achievements: `ACH_FIRST_WIN`, `ACH_FIRST_FORGE`, `ACH_CLUTCH`, `ACH_SURVIVOR`, `ACH_DAMAGE_20K`

**PlayerProfile**
- Autoload `autoloads/PlayerProfile.gd`, persists to `user://profile.cfg`
- Three ConfigFile sections: `[stats]`, `[progress]`, `[discovery]`
- Fields: `total_damage_dealt`, `matches_played`, `matches_won`, `achievements_unlocked`, `discovered_recipes`
- Save: immediate on achievement unlock; batch save at match end (victory/eliminated)
- Is master for `discovered_recipes` — GameState gets a snapshot at match start

**Ghost Fixtures**
- `data/GhostFixtures.gd` — one prebuilt Ghost snapshot per shop_tier (3 fixtures)
- Used as test fixtures and as fallback if day-seeded generation returns empty

**New CONTEXT.md terms added:** Ghost, Ghost Pool, Milestone (see [CONTEXT.md](../../CONTEXT.md))

---

## Build plan for next session

Implement in this order (each step is independently testable):

| # | Status | File | Change |
|---|--------|------|--------|
| 1 | ✅ done | `autoloads/PlayerProfile.gd` | NEW — ConfigFile load/save, 3 sections, get/set helpers |
| 2 | ✅ done | `data/GhostFixtures.gd` | NEW — 3 static Ghost snapshot dicts (tier 1, 2, 3) |
| 3 | ✅ done | `data/GameState.gd` | Add `opponent_snapshot: {}` field; seed `discovered_recipes` from PlayerProfile at create() |
| 4 | ✅ done | `systems/OpponentProvider.gd` | NEW — `get_opponent(context)`, LocalDaySeeded logic, fixture fallback |
| 5 | ✅ done | `systems/AchievementSystem.gd` | NEW — `check(state, profile, event)`, all 5 achievement conditions, recipe merge |
| 6 | ✅ done | `systems/PhaseSystem.gd` | `to_battle(state, opponent_snapshot)` — store snapshot, read grid from it |
| 7 | ✅ done | `scenes/screens/Battle.gd` | Call OpponentProvider before `to_battle()`; call AchievementSystem + save profile after `advance_round()` |
| 8 | ✅ done | `test/unit/test_opponent_provider.gd` | NEW — fixture-injected tests |
| 9 | ⬜ todo | `test/unit/test_achievement_system.gd` | NEW — event-driven tests for all 5 achievements |
| 10 | ⬜ todo | `test/unit/test_player_profile.gd` | NEW — load/save/merge/section tests |

Register `PlayerProfile` as an Autoload in `project.godot` (after `GameManager`) — verify this is done.

---

## What is NOT in scope for next session

- `PlatformLayer` autoload (GodotSteam isolation) — identified but deferred; needs custom engine build decision
- Opponent Snapshot flat-field collapse in GameState — partly handled by step 3 above, but full UI wiring (showing ghost name in Battle) deferred
- Real backend HTTP adapter for OpponentProvider — needs server infrastructure
- Internal Milestone reward design — seam exists via AchievementSystem, rewards TBD in dedicated session

---

## Suggested skills for next session

- `/tdd` — implement each file test-first; GUT test suite is already wired (`godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gprefix=test_ -gexit`)
- `/grill-with-docs` — if any implementation decision feels uncertain mid-build, stop and grill before committing
- `/zoom-out` — after all 3 features land, check the overall shape hasn't drifted from the architecture intent

---

## Current test status (end of this session)

140/140 passing (from prior session). No new tests written this session — that's the first thing next session does.

## Build validation commands

```
godot --headless --import
godot --headless --quit
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gprefix=test_ -gexit
```
