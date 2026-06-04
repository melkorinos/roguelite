# Handoff — Architecture + Balance

**Last updated:** 2026-06-03

---

## Infrastructure settled (2026-06-02) — no further action needed

- **OpponentProvider** (`systems/`): `get_opponent(context)` → Ghost snapshot. LocalDaySeeded + GhostFixtures fallback.
- **AchievementSystem** (`systems/`): `check(state, profile, event) → {profile, unlocked}` — pure, no I/O. 5 achievements. Callers own PlayerProfile I/O.
- **PlayerProfile** (`autoloads/`): ConfigFile `user://profile.cfg`. Three sections: stats / progress / discovery.
- **GhostFixtures** (`data/`): 3 prebuilt Ghost snapshots (tier 1 / 2 / 3).
- **PhaseSystem.to_battle(state, opponent_snapshot)**: reads grid from snapshot, calls OpponentProvider before invoking.
- PlatformLayer (SteamAdapter) still deferred — needs custom engine build decision.

---

## Architecture work — 2026-06-03 (improve-architecture session)

Full review in [`.claude/ai-helper/reviews/architecture-review-20260603.html`](reviews/architecture-review-20260603.html).

### Implemented this session

**#1 — Deepen AchievementSystem (Strong)**
- `check()` was reading/writing `PlayerProfile` internally (untestable). Now pure: takes `profile: Dictionary`, returns `{profile, unlocked}`. Battle.gd and Shop.gd own `to_dict() / from_dict() / save_profile()`.
- Added 5 direct `check()` tests. **284/284 passing.**

**#2 — Collapse tick_battle firing loop (Strong)**
- Two 35-line near-identical player/opponent loops → single `_tick_side(s, ctx, delta, events, use_effects, bstats)`.
- `_make_side_ctx(is_player)` returns the key-map dict; `_apply_element_effect` takes explicit key strings instead of `is_player_side: bool`.
- All 21 BattleSystem tests pass unchanged.

### Remaining candidates (open)

| # | Title | Strength | Notes |
|---|-------|----------|-------|
| 3 | Unify Forge module interface | Worth exploring | 10 fns with 3 return shapes → `attempt(state, op)` + `preview(state, op)`. Scene stops doing before/after recipe count. |
| 4 | Pull drag-validation out of slot components | Worth exploring | BattleSlot/InventorySlot/ForgeSlot each call `ShopSystem.can_transfer()` directly. Move to `GameManager.can_drop()`. |
| 5 | Consolidate battle-init constants into GameState | Speculative | `player_hp = 30` and `gold += 5` appear in 3 places each. Named constants in `GameState.gd`. |

---

## BalanceSystem status (2026-06-03)

`systems/BalanceSystem.gd` — gated by `FeatureFlags.efficiency_scoring`. Dev panel lives in Compendium scene.

- **DPS Score**: `effective_damage(elem, level) / cooldown`. Computed per level.
- **Effect Score**: hardcoded lookup table, T1 only. T2/T3 score 0 — pending effect design.
- **Board score**: sum of 4 slots.
- ADR: `docs/adr/0002-two-axis-efficiency-scoring.md`.

**Known gap:** Effect Score table covers T1 only. As T2/T3 effects are designed, scores must be added to the table. No test coverage for BalanceSystem itself yet.

---

## Test suite

```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/data/ -gdir=res://test/unit/systems/ -gdir=res://test/unit/autoloads/ -gprefix=test_ -gexit
```

**284/284 passing** as of 2026-06-03.  
Do NOT use `-gdir=res://test/unit/` — this GUT version does not recurse and will silently run nothing.
