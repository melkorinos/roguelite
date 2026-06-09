class_name BattleSystem

# Balance values (battle time limit, opponent HP) live in TuningData. COMBAT_STEP
# stays here: it's a determinism/correctness constant, not a balance knob.
# Fixed combat step (aligns with decisecond granularity). Combat advances in these
# chunks regardless of frame rate, so work and determinism don't depend on FPS.
const COMBAT_STEP_SECONDS: float = 0.1


# Runs a battle to completion at the fixed step — for headless / fast replay / async
# ghost simulation. Deterministic given combat_rng_state. Step-capped against any
# non-terminating edge case (combat also self-terminates at BATTLE_TIME_LIMIT).
static func simulate_battle(state: Dictionary) -> Dictionary:
	var s: Dictionary = state
	# Bounded by the Sandstorm hard cap (combat can now run past BATTLE_TIME_LIMIT until
	# the storm forces a KO); +50 steps of slack.
	var max_steps: int = int(TuningData.SANDSTORM_HARD_CAP_SECONDS / COMBAT_STEP_SECONDS) + 50
	var steps: int = 0
	while (s["phase"] as String) != "result" and steps < max_steps:
		s = tick_battle(s, COMBAT_STEP_SECONDS)
		steps += 1
	return s


static func compute_opponent_hp(opp_grid: Array) -> int:
	var total: int = TuningData.OPPONENT_BASE_HP
	for slot: Variant in opp_grid:
		if slot != null:
			total += (slot as Dictionary).get("damage", 1) as int * TuningData.OPPONENT_HP_PER_DAMAGE
	return maxi(total, TuningData.OPPONENT_HP_MIN)


static func tick_battle(state: Dictionary, delta: float) -> Dictionary:
	if state["phase"] == "result":
		return state
	var s: Dictionary = state.duplicate(true)
	var events: Array = []
	var use_effects: bool = FeatureFlags.status_effects
	var bstats: Dictionary = s["battle_stats"] as Dictionary

	if use_effects:
		var tick_acc: float = (s["status_tick_timer"] as float) + delta
		while tick_acc >= 1.0:
			tick_acc -= 1.0
			var opp_tick: Dictionary = StatusSystem.tick(s["opponent_statuses"] as Dictionary)
			s["opponent_statuses"] = opp_tick["statuses"] as Dictionary
			s["opponent_hp"] = maxi(0, (s["opponent_hp"] as int) - (opp_tick["damage"] as int))
			# A DOT ticking on the opponent is the player's event to react to.
			for tick_trigger: Variant in opp_tick["events"] as Array:
				events.append(AbilitySystem.trigger_event(tick_trigger as String, "player"))
			var pl_tick: Dictionary = StatusSystem.tick(s["player_statuses"] as Dictionary)
			s["player_statuses"] = pl_tick["statuses"] as Dictionary
			s["player_hp"] = maxi(0, (s["player_hp"] as int) - (pl_tick["damage"] as int))
			for tick_trigger: Variant in pl_tick["events"] as Array:
				events.append(AbilitySystem.trigger_event(tick_trigger as String, "opponent"))
		s["status_tick_timer"] = tick_acc

	# Reconstruct the seeded combat RNG, advance it through both sides + reactives, persist it.
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.state = s["combat_rng_state"] as int
	_tick_side(s, "player", delta, events, use_effects, bstats, combat_rng)
	_tick_side(s, "opponent", delta, events, use_effects, bstats, combat_rng)

	# Depth-1 reactive abilities respond to this tick's fire/tick/armor events;
	# periodic abilities advance their own timers. In-place (s is already a fresh
	# duplicate) — avoids extra full-state deep copies per tick.
	AbilitySystem.resolve_reactive_inplace(s, events, combat_rng)
	AbilitySystem.resolve_periodic_inplace(s, delta)
	s["combat_rng_state"] = combat_rng.state
	# Only fire events render; trigger events (ticks/armor/haste) stay out of the view.
	var visual_events: Array = []
	for event: Variant in events:
		if AbilitySystem.is_visual_event(event as Dictionary):
			visual_events.append(event)
	s["battle_events"] = visual_events

	var timer: float = (s["battle_timer"] as float) + delta
	s["battle_timer"] = timer

	# Timed player commands (Innate Ability; Replay re-times them) fire when the
	# clock reaches their moment.
	s = _drain_commands(s, timer)

	_tick_sandstorm(s, timer)

	# Combat ends on elimination (the canonical win rule) or the Sandstorm hard cap
	# (a determinism backstop — the storm normally forces a KO long before it).
	if (s["player_hp"] as int) <= 0 or (s["opponent_hp"] as int) <= 0 \
			or timer >= TuningData.SANDSTORM_HARD_CAP_SECONDS:
		s["phase"] = "result"

	return s


# Sandstorm (ADR 0012): after BATTLE_TIME_LIMIT (the storm START), escalating TRUE
# damage hits BOTH sides on each whole storm-second until one is eliminated. Damage of
# storm-second k (from 0) = SANDSTORM_BASE_DAMAGE + SANDSTORM_RAMP_PER_SECOND*k. Bypasses
# all mitigation by design (an impartial environmental clock — see TuningData) and emits
# no combat events (not reactive). Deterministic (time-driven, no RNG) → Replay-safe.
# `sandstorm_ticks` tracks storm-seconds already applied, so the cadence is independent
# of the combat step size. Mutates `s` (already a fresh duplicate).
static func _tick_sandstorm(s: Dictionary, timer: float) -> void:
	var elapsed: float = timer - TuningData.BATTLE_TIME_LIMIT
	if elapsed < 0.0:
		return
	var due_ticks: int = int(floor(elapsed)) + 1
	var applied: int = s.get("sandstorm_ticks", 0) as int
	while applied < due_ticks:
		var dmg: int = TuningData.SANDSTORM_BASE_DAMAGE + TuningData.SANDSTORM_RAMP_PER_SECOND * applied
		s["player_hp"] = maxi(0, (s["player_hp"] as int) - dmg)
		s["opponent_hp"] = maxi(0, (s["opponent_hp"] as int) - dmg)
		applied += 1
	s["sandstorm_ticks"] = applied


# Queues a player command to fire at at_seconds of battle time, applying the given
# ability's effects for the given side. The seam the Innate Ability and Replay ride.
static func queue_command(state: Dictionary, at_seconds: float, ability: Dictionary, side: String) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	(s["pending_commands"] as Array).append({
		"at_seconds": at_seconds, "ability": ability, "side": side, "fired": false,
	})
	return s


# Fires any unfired commands whose moment has arrived. Deterministic given the
# seeded RNG, so Replay reproduces a re-timed command exactly.
static func _drain_commands(s: Dictionary, current_time: float) -> Dictionary:
	# s is already a fresh duplicate; apply commands in place (no per-command copy).
	for command_variant: Variant in s["pending_commands"] as Array:
		var command: Dictionary = command_variant as Dictionary
		if not (command.get("fired", false) as bool) and (command["at_seconds"] as float) <= current_time:
			AbilitySystem.apply_command(s, command)
			command["fired"] = true
	return s


static func _tick_side(s: Dictionary, side: String, delta: float, events: Array, use_effects: bool, bstats: Dictionary, combat_rng: RandomNumberGenerator) -> void:
	# All side→state-key mapping goes through CombatSide — the single side accessor.
	var k: Dictionary = CombatSide.keys(side)
	var own_statuses_key: String = k["statuses"] as String
	var grid: Array = s[k["grid"] as String] as Array
	var timers: Array = s[k["timers"] as String] as Array
	var frozen_seconds: Array = s[k["frozen"] as String] as Array
	var stats: Array = bstats[k["stats"] as String] as Array

	for i: int in grid.size():
		if grid[i] == null:
			continue
		# Frozen slots are paused: they skip their fire and their cooldown does not
		# advance while the freeze drains down.
		if (frozen_seconds[i] as float) > 0.0:
			frozen_seconds[i] = maxf(0.0, (frozen_seconds[i] as float) - delta)
			continue
		var elem: Dictionary = grid[i] as Dictionary
		var t: float = (timers[i] as float) + delta
		var base_deciseconds: int = elem["cooldown_deciseconds"] as int
		var effective_cooldown_seconds: float
		if use_effects:
			effective_cooldown_seconds = float(StatusSystem.effective_cooldown_deciseconds(base_deciseconds, s[own_statuses_key] as Dictionary)) / 10.0
		else:
			effective_cooldown_seconds = float(base_deciseconds) / 10.0
		if t >= effective_cooldown_seconds:
			t -= effective_cooldown_seconds
			var fire: bool = true
			if use_effects:
				var blind_percent: int = ((s[own_statuses_key] as Dictionary)["blind"] as Dictionary)["percent"] as int
				if blind_percent > 0 and combat_rng.randf() * 100.0 < float(blind_percent):
					fire = false
			if fire:
				# Multicast repeats the full fire block; each repeat is an
				# independent event so synergies trigger once per repeat.
				var repeats: int = 1 + AbilitySystem.multicast_count(elem)
				for _repeat: int in repeats:
					_fire_element_once(s, side, elem, i, stats, events, use_effects, combat_rng)
			else:
				events.append(AbilitySystem.miss_event(side, i))
		timers[i] = t


# Resolves a single fire of one element: damage hit, event, stats, and on-fire
# effect. Called once per multicast repeat.
static func _fire_element_once(s: Dictionary, side: String, elem: Dictionary, slot_index: int, stats: Array, events: Array, use_effects: bool, combat_rng: RandomNumberGenerator) -> void:
	var k: Dictionary = CombatSide.keys(side)
	var opp_k: Dictionary = CombatSide.keys(CombatSide.opponent_of(side))
	var own_statuses_key: String = k["statuses"] as String
	var opp_statuses_key: String = opp_k["statuses"] as String
	var opp_hp_key: String = opp_k["hp"] as String
	var raw: int = ElementData.effective_damage(elem)
	var dmg: int = raw
	if use_effects:
		var armor_before: int = ((s[opp_statuses_key] as Dictionary)["armor"] as Dictionary)["value"] as int
		var hit: Dictionary = StatusSystem.compute_incoming_damage(raw, s[own_statuses_key] as Dictionary, s[opp_statuses_key] as Dictionary)
		dmg = hit["damage"] as int
		s[opp_statuses_key] = hit["defender_statuses"] as Dictionary
		var armor_after: int = ((s[opp_statuses_key] as Dictionary)["armor"] as Dictionary)["value"] as int
		if armor_before > 0 and armor_after == 0:
			events.append(AbilitySystem.trigger_event("on_armor_stripped", side, slot_index))
	s[opp_hp_key] = maxi(0, (s[opp_hp_key] as int) - dmg)
	var effect_str: String = elem.get("effect", "") as String
	events.append(AbilitySystem.fire_event(side, slot_index, dmg, effect_str))
	var slot_stats: Dictionary = stats[slot_index] as Dictionary
	slot_stats["fires"] = (slot_stats["fires"] as int) + 1
	slot_stats["damage"] = (slot_stats["damage"] as int) + dmg
	if use_effects and elem.has("effect"):
		# On-fire Action runs through the same effect vocabulary as Abilities;
		# apply_on_fire also records this element's Summary tally.
		AbilitySystem.apply_on_fire(s, effect_str, side, slot_index, dmg)
	if use_effects:
		# On-activate abilities fire alongside the Action, through the same
		# vocabulary; every_n gates them off this slot's fire tally (no-op unless
		# the element's ability is on_activate).
		AbilitySystem.apply_on_activate(s, AbilitySystem.ability_for(elem), side, slot_index, slot_stats["fires"] as int)
	# Probabilistic on-hit passives (Dust, Static, Pollen, Flint, Sand), rolled
	# from the seeded RNG in slot order so replays reproduce exactly.
	if use_effects:
		var own_grid: Array = s[k["grid"] as String] as Array
		for chance_entry: Variant in AbilitySystem.on_hit_status_chances(own_grid):
			var entry: Dictionary = chance_entry as Dictionary
			if combat_rng.randf() * 100.0 < float(entry["chance"] as int):
				var statuses_key: String = own_statuses_key if (entry.get("target", "opponent") as String) == "own" else opp_statuses_key
				var res: Dictionary = StatusSystem.apply_effect(s[statuses_key] as Dictionary, entry["status"] as String)
				s[statuses_key] = res["statuses"] as Dictionary
				_tally_effect(slot_stats, entry["status"] as String)


# Picks a slot to freeze on the given grid. Prefers any occupied slot other than
# the last one frozen (anti-permalock); only re-freezes the last slot when it is
# the sole occupant. Returns -1 when no slot is occupied.
static func select_freeze_target(grid: Array, last_frozen_slot: int) -> int:
	var occupied: Array[int] = []
	for i: int in grid.size():
		if grid[i] != null:
			occupied.append(i)
	if occupied.is_empty():
		return -1
	for slot: int in occupied:
		if slot != last_frozen_slot:
			return slot
	return occupied[0]


# Records one status application onto an element's Summary row (total + per-status).
static func _tally_effect(slot_stats: Dictionary, status: String) -> void:
	slot_stats["effects"] = (slot_stats["effects"] as int) + 1
	var by_status: Dictionary = slot_stats["effects_by_status"] as Dictionary
	by_status[status] = (by_status.get(status, 0) as int) + 1


# Canonical win rule: a Round is won when the OPPONENT is eliminated (opponent_hp
# reaches 0). A timeout with the opponent still alive is a loss scaled by their
# remaining HP (see PhaseSystem._lives_lost) — NOT an HP comparison. The old
# HP-comparison rule disagreed with how the Run actually advances, so the result
# shown could contradict the result applied. Mutual elimination in one tick is a
# draw, which counts as a win.
static func compute_result(state: Dictionary) -> String:
	var player_hp: int = state["player_hp"] as int
	var opp_hp: int = state["opponent_hp"] as int
	if opp_hp <= 0 and player_hp <= 0:
		return "draw"
	if opp_hp <= 0:
		return "player_wins"
	return "opponent_wins"
