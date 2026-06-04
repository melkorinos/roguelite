# Battle performance & load — notes (2026-06-04)

Review of `BattleSystem` / `AbilitySystem` / `StatusSystem` for eventual load (single battle on the
client, and many battles for async-PvP / ghost simulation), plus "infinite build" handling.

## Bottlenecks, ranked
1. **Full-state deep copies per tick** — `tick_battle` + each resolver `duplicate(true)`d the whole
   GameState every frame. Biggest cost; scales with state size × FPS × battle count.
2. **Frame-coupled simulation** — work scaled with frame rate.
3. **Per-fire / per-event grid scans** — `ability_for`, `on_hit_status_chances`, reactive scans are
   O(grid) per event.
4. **`ElementData.all_elements()` rebuilds 132 dicts per call; `find()` linear** — not combat-hot.
5. **Float-label tweens** — one Tween per fire event; heavy multicast floods the renderer (client only).

## Shipped (2026-06-04)
- **#1 In-place tick** — `resolve_reactive_inplace` / `resolve_periodic_inplace` / `apply_command`
  mutate the already-duplicated tick state; removed ~3 deep copies/frame. Public duplicating forms kept
  for tests.
- **#2 Fixed timestep** — `BattleSystem.COMBAT_STEP_SECONDS = 0.1`; `Battle.gd` accumulates and steps in
  fixed chunks (frame-rate-independent, fewer ticks at high FPS). `BattleSystem.simulate_battle(state)`
  runs a battle to completion headless (async-PvP / Replay), deterministic via `combat_rng_state`,
  step-capped.
- **#3 Infinite-build guards** — `StatusSystem.MAX_STACKS = 99` caps stacking statuses;
  `AbilitySystem.MAX_REACTIONS_PER_TICK = 1024` circuit-breaker caps reactive activations per tick (well
  above any legit board's ~hundreds). These complement the existing hard guards: **effective-cooldown
  floor of 10 deciseconds (max 1 fire/sec/element)** and the **30 s battle time limit** — together these
  already bound per-battle compute; an "infinite build" can't create infinite work.
- **#5 (partial)** — `Battle.gd` caps concurrent float labels (`MAX_FLOAT_LABELS = 40`).

## Deferred (intentionally — brainstorming phase; abilities/elements/battle still in flux)
- **#4 Per-combat caches** — precomputed on-hit list, `trigger→[slots]` map, cached `ability_for`. Would
  cut the O(grid)-per-event scans, but precomputing now would churn while abilities change. Revisit at
  3×3 grid or before server-side simulation. (Marked in `AbilitySystem` above `ability_for`.)
- **#5 ElementData lazy cache** — `all_elements()` array + `id→dict` index built once. Deferred while the
  roster is in flux. (Marked in `ElementData` above `find`.)

## Next-load checklist (when async PvP / 3×3 lands)
- Turn on the per-combat caches (#4) and ElementData cache.
- Use `simulate_battle` for ghost fights; store only seed + boards (combat is reproducible) rather than
  full replays.
- Re-tune `MAX_REACTIONS_PER_TICK` if grid grows past 3×3.
