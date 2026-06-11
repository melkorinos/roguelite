extends Control

var _player_slots: Array[BattleSlot] = []
var _opp_slots: Array[BattleSlot] = []
var _summary_visible: bool = false
var _paused: bool = false
var _speed_mult: float = 1.0
var _tooltip: TooltipCard
var _pause_overlay: PauseOverlay
var _combat_accumulator: float = 0.0
const MAX_FLOAT_LABELS: int = 40  # cap concurrent combat labels so heavy multicast can't flood the renderer
var _active_float_labels: int = 0
var _player_hp_bar: ProgressBar
var _opp_hp_bar: ProgressBar
# Status Tray: status name → its chip Control, per side. Built once, toggled per render.
var _player_chips: Dictionary = {}
var _opp_chips: Dictionary = {}
# Contribution Bars (live, player-only): one segmented bar per occupied player slot,
# normalised to a single running max (the largest element total this combat).
var _contrib_panel: PanelContainer
var _contrib_button: Button
var _contrib_rows: Array = []   # [{ slot, bg: Panel, segments: {type: ColorRect}, displayed: {type: float} }]
var _contrib_max: float = 1.0   # running max element total; monotonic within this combat
var _contrib_visible: bool = true
const CONTRIB_BAR_WIDTH: float = 150.0
const CONTRIB_BAR_HEIGHT: float = 16.0


func _ready() -> void:
	_tooltip = TooltipCard.new()
	add_child(_tooltip)

	_pause_overlay = PauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.resumed.connect(_on_pause_resumed)
	_pause_overlay.settings_requested.connect(_on_pause_settings)
	_pause_overlay.forfeit_requested.connect(_on_pause_forfeit)
	_pause_overlay.quit_to_menu_requested.connect(_on_pause_menu)
	_pause_overlay.quit_to_desktop_requested.connect(func() -> void: get_tree().quit())

	($VBox/Header as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_BATTLE)
	($VBox/BattleRow/PlayerSide/PlayerLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_PLAYER_SIDE)
	($VBox/BattleRow/OppSide/OppLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_OPP_SIDE)
	($VBox/TimerRow/TimerLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_ROUND_LABEL)

	_player_hp_bar = $VBox/HpBarRow/PlayerHpBar as ProgressBar
	_opp_hp_bar = $VBox/HpBarRow/OppHpBar as ProgressBar
	_style_hp_bar(_player_hp_bar)
	_style_hp_bar(_opp_hp_bar)

	_build_grids()
	_build_status_trays()
	_build_contrib_panel()
	_render()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		if ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _pause_overlay.is_open():
				_on_pause_resumed()
			else:
				_tooltip.hide_card()
				_paused = true
				_pause_overlay.show_overlay()


func _process(delta: float) -> void:
	if GameManager.state["phase"] == "result" or _paused or _pause_overlay.is_open():
		return
	# Fixed-timestep: advance combat in COMBAT_STEP_SECONDS chunks so the simulation
	# is frame-rate-independent and deterministic. Spread accumulated time across steps.
	_combat_accumulator += delta * _speed_mult
	while _combat_accumulator >= BattleSystem.COMBAT_STEP_SECONDS and GameManager.state["phase"] != "result":
		_combat_accumulator -= BattleSystem.COMBAT_STEP_SECONDS
		GameManager.state = BattleSystem.tick_battle(GameManager.state, BattleSystem.COMBAT_STEP_SECONDS)
		_process_fire_events(GameManager.state)
	_update_progress_bars(GameManager.state)
	_render()


# Builds a Status Tray (a row of Status Chips) for each side, between the side label and
# its grid. One chip per tray-eligible status (those with a persistent shape; slow is
# dead), built once and toggled in _update_status_trays. Emoji + valence come from
# EffectRegistry; the live readout from StatusSystem.describe.
func _build_status_trays() -> void:
	_player_chips = _build_tray($VBox/BattleRow/PlayerSide)
	_opp_chips = _build_tray($VBox/BattleRow/OppSide)


func _build_tray(side_node: Node) -> Dictionary:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	side_node.add_child(row)
	side_node.move_child(row, 1)  # between the side label (0) and the grid
	var chips: Dictionary = {}
	for effect_key: Variant in EffectRegistry.EFFECTS:
		var entry: Dictionary = EffectRegistry.EFFECTS[effect_key] as Dictionary
		if (entry["status_shape"] as Dictionary).is_empty() or (effect_key as String) == "slow":
			continue  # heal/cleanse are instant; slow is dead
		var tint: Color = ThemeData.STATUS_BUFF_TINT if (entry["valence"] as String) == "buff" else ThemeData.STATUS_DEBUFF_TINT
		var chip := StatusChip.new()
		chip.setup(entry["emoji"] as String, tint)
		chip.visible = false
		row.add_child(chip)
		chips[effect_key as String] = chip
	return chips


func _update_status_trays(s: Dictionary) -> void:
	_update_tray(_player_chips, s["player_statuses"] as Dictionary)
	_update_tray(_opp_chips, s["opponent_statuses"] as Dictionary)


func _update_tray(chips: Dictionary, statuses: Dictionary) -> void:
	for effect_key: Variant in chips:
		var chip: StatusChip = chips[effect_key] as StatusChip
		var status_name: String = effect_key as String
		var active: bool = StatusSystem.is_active(status_name, statuses)
		chip.visible = active
		if active:
			chip.set_data(StatusSystem.chip_badge(status_name, statuses), StatusSystem.describe(status_name, statuses))


# Builds the right-gutter Contribution Bars panel (one row per OCCUPIED player slot)
# plus the in-combat toggle in the controls row. Rows are built once — the board is
# fixed for the combat — and their segment widths are updated each frame in _render.
func _build_contrib_panel() -> void:
	_contrib_visible = SettingsManager.get_contribution_bars()

	# Toggle button, in the controls row (visible during combat, unlike the result-only Summary).
	_contrib_button = Button.new()
	_contrib_button.text = "📊 Bars"
	_contrib_button.pressed.connect(_on_contrib_toggle)
	$VBox/ControlsRow.add_child(_contrib_button)

	_contrib_panel = PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = ThemeData.CONTRIB_PANEL_BG
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(8)
	_contrib_panel.add_theme_stylebox_override("panel", bg)
	_contrib_panel.custom_minimum_size = Vector2(CONTRIB_BAR_WIDTH + 48.0, 0)
	_contrib_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	$VBox/BattleRow.add_child(_contrib_panel)  # rightmost child → right gutter

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_contrib_panel.add_child(vbox)
	var title := Label.new()
	title.text = "CONTRIBUTION"
	title.add_theme_color_override("font_color", ThemeData.COLOR_PLAYER_SIDE)
	vbox.add_child(title)

	_contrib_rows.clear()
	var grid: Array = GameManager.state["battle_grid"] as Array
	for i: int in grid.size():
		if grid[i] == null:
			continue
		var elem: Dictionary = grid[i] as Dictionary
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var emoji := Label.new()
		emoji.text = elem.get("emoji", "?") as String
		emoji.custom_minimum_size = Vector2(22, 0)
		row.add_child(emoji)
		var bar_bg := Panel.new()
		bar_bg.custom_minimum_size = Vector2(CONTRIB_BAR_WIDTH, CONTRIB_BAR_HEIGHT)
		bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = ThemeData.CONTRIB_BAR_BG
		bar_style.set_border_width_all(1)
		bar_style.border_color = ThemeData.CONTRIB_BAR_BORDER
		bar_style.set_corner_radius_all(3)
		bar_bg.add_theme_stylebox_override("panel", bar_style)
		var segments: Dictionary = {}
		var displayed: Dictionary = {}
		for seg_type: Variant in ThemeData.CONTRIB_SEGMENT_ORDER:
			var seg := ColorRect.new()
			seg.color = ThemeData.CONTRIB_COLORS[seg_type] as Color
			seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			seg.size = Vector2(0, CONTRIB_BAR_HEIGHT)
			bar_bg.add_child(seg)
			segments[seg_type] = seg
			displayed[seg_type] = 0.0
		row.add_child(bar_bg)
		vbox.add_child(row)
		_contrib_rows.append({ "slot": i, "bg": bar_bg, "segments": segments, "displayed": displayed })


func _on_contrib_toggle() -> void:
	AudioManager.play("click")
	_contrib_visible = not _contrib_visible
	SettingsManager.set_contribution_bars(_contrib_visible)
	_update_contrib_bars(GameManager.state, true)


# Re-lays out each bar's stacked segments from this side's contrib rows. A single
# running max (largest element total this combat) scales every bar, so the biggest
# contributor fills the bar and the rest read relative to it. Snaps on result, else
# eases toward the target for smooth growth.
func _update_contrib_bars(s: Dictionary, snap: bool) -> void:
	_contrib_panel.visible = _contrib_visible
	if not _contrib_visible:
		return
	var rows: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	# Pass 1: refresh the running max from each element's total contribution.
	for entry: Variant in _contrib_rows:
		var contrib: Dictionary = (rows[(entry as Dictionary)["slot"] as int] as Dictionary)["contrib"] as Dictionary
		var total: float = 0.0
		for seg_type: Variant in ThemeData.CONTRIB_SEGMENT_ORDER:
			total += float(contrib[seg_type] as int)
		_contrib_max = maxf(_contrib_max, total)
	var denom: float = maxf(_contrib_max, 1.0)
	# Pass 2: stack the segments left→right at their normalised widths.
	for entry: Variant in _contrib_rows:
		var row: Dictionary = entry as Dictionary
		var contrib: Dictionary = (rows[row["slot"] as int] as Dictionary)["contrib"] as Dictionary
		var displayed: Dictionary = row["displayed"] as Dictionary
		var segments: Dictionary = row["segments"] as Dictionary
		var x: float = 0.0
		for seg_type: Variant in ThemeData.CONTRIB_SEGMENT_ORDER:
			var target: float = float(contrib[seg_type] as int)
			var disp: float = target if snap else lerpf(displayed[seg_type] as float, target, 0.25)
			displayed[seg_type] = disp
			var seg: ColorRect = segments[seg_type] as ColorRect
			var w: float = (disp / denom) * CONTRIB_BAR_WIDTH
			seg.position = Vector2(x, 0)
			seg.size = Vector2(w, CONTRIB_BAR_HEIGHT)
			x += w


func _style_hp_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = ThemeData.HP_BAR_BG
	bg.set_border_width_all(2)
	bg.border_color = ThemeData.HP_BAR_BORDER
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeData.HP_BAR_FILL
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)


func _build_grids() -> void:
	var s: Dictionary = GameManager.state
	var pgrid_node: GridContainer = $VBox/BattleRow/PlayerSide/PlayerGrid
	var ogrid_node: GridContainer = $VBox/BattleRow/OppSide/OppGrid

	_player_slots.clear()
	_opp_slots.clear()

	# Each side sizes from its own grid — boards may differ (Grid Growth, ADR 0014).
	_build_side(pgrid_node, s["battle_grid"] as Array, "player", _player_slots)
	_build_side(ogrid_node, s["opponent_grid"] as Array, "opponent", _opp_slots)


func _build_side(container: GridContainer, grid: Array, side: String, slots_out: Array[BattleSlot]) -> void:
	container.columns = GridSystem.dimensions(grid.size()).x
	for i: int in grid.size():
		var slot: BattleSlot = BattleSlot.new()
		slot.slot_index = i
		slot.draggable = false
		slot.tooltip_requested.connect(_on_tooltip_requested.bind(side, i))
		slot.tooltip_hide_requested.connect(_on_tooltip_hide)
		container.add_child(slot)
		slot.set_element(grid[i])
		slots_out.append(slot)


func _update_progress_bars(s: Dictionary) -> void:
	_update_side_charge(s["battle_grid"] as Array, s["element_timers"] as Array, s["player_frozen_seconds"] as Array, _player_slots)
	_update_side_charge(s["opponent_grid"] as Array, s["opponent_timers"] as Array, s["opponent_frozen_seconds"] as Array, _opp_slots)


# Drives each Charge Bar. Combat advances in fixed 0.1 s steps, so the raw timer
# jumps in chunks; we add the un-stepped accumulator to interpolate smoothly between
# steps. Frozen elements aren't charging, so they don't get the smoothing.
func _update_side_charge(grid: Array, timers: Array, frozen: Array, slots: Array) -> void:
	for i: int in grid.size():
		if grid[i] == null:
			continue
		var elem: Dictionary = grid[i] as Dictionary
		var cooldown_seconds: float = float(elem["cooldown_deciseconds"] as int) / 10.0
		var elapsed: float = timers[i] as float
		if (frozen[i] as float) <= 0.0:
			elapsed += _combat_accumulator
		(slots[i] as BattleSlot).set_charge(elapsed / cooldown_seconds)


func _process_fire_events(s: Dictionary) -> void:
	# battle_events holds only fire/miss events (see AbilitySystem combat-event model);
	# trigger events are filtered out by BattleSystem before this list is stored.
	for event: Variant in s["battle_events"]:
		var e: Dictionary = event as Dictionary
		if not AbilitySystem.is_visual_event(e):
			continue
		var idx: int = e["slot"] as int
		var slot: BattleSlot
		if e["side"] == "player":
			slot = _player_slots[idx]
		else:
			slot = _opp_slots[idx]
		if not (e.get("is_miss", false) as bool):
			slot.play_fire_animation()
			match slot.get_tier():
				1: AudioManager.play("fire_t1")
				2: AudioManager.play("fire_t2")
				3: AudioManager.play("fire_t3")
				_: AudioManager.play("fire_t1")
		_spawn_float_labels(slot, e)


func _spawn_float_labels(slot: BattleSlot, event: Dictionary) -> void:
	var is_miss: bool = event.get("is_miss", false) as bool
	if is_miss:
		_float_label(slot, "MISS", ThemeData.FLOAT_MISS, 0.0)
		return
	var dmg: int = event.get("damage", 0) as int
	var effect: String = event.get("effect", "") as String
	if dmg > 0:
		_float_label(slot, "-%d" % dmg, ThemeData.FLOAT_DAMAGE, 0.0)
	# Heal and leech show an HP-gain amount (dynamic), not a status icon.
	if effect == "heal":
		_float_label(slot, "+1 HP", ThemeData.FLOAT_HEAL, 0.0)
	elif effect == "leech":
		_float_label(slot, "+%d HP" % dmg, ThemeData.FLOAT_HEAL, 0.0)
	else:
		# Status popups: text + emoji from EffectRegistry (one canonical emoji,
		# shared with the Status Tray), color from ThemeData.
		var fx: Dictionary = EffectRegistry.float_label(effect)
		if not fx.is_empty():
			var color: Color = ThemeData.FLOAT_LABEL_COLORS.get(effect, Color.WHITE) as Color
			_float_label(slot, fx["text"] as String, color, fx["nudge"] as float)


func _float_label(slot: BattleSlot, text: String, color: Color, y_nudge: float) -> void:
	if _active_float_labels >= MAX_FLOAT_LABELS:
		return  # renderer guard — drop excess labels under heavy multicast
	_active_float_labels += 1
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	UIScale.apply(lbl, UIScale.FLOAT_LABEL)
	lbl.z_index = 120
	add_child(lbl)
	# Position at top-centre of the slot in Battle scene local space
	var slot_gr: Rect2 = slot.get_global_rect()
	var self_gr: Rect2 = get_global_rect()
	var lx: float = slot_gr.position.x - self_gr.position.x + slot_gr.size.x * 0.5 - 24.0
	var ly: float = slot_gr.position.y - self_gr.position.y + y_nudge - 8.0
	lbl.position = Vector2(lx, ly)
	var tween := create_tween()
	tween.set_parallel(true)
	# Rise + fade durations bumped ~20% so the numbers linger a touch longer.
	tween.tween_property(lbl, "position:y", ly - 52.0, 1.02)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.02).set_delay(0.36)
	tween.chain().tween_callback(func() -> void:
		_active_float_labels -= 1
		lbl.queue_free())


func _render() -> void:
	var s: Dictionary = GameManager.state
	var is_result: bool = s["phase"] == "result"

	$VBox/Header.text = "BATTLE — Round %d  |  Life: %d  Wins: %d/10" % [s["round"], s["lives"], s["wins"]]
	$VBox/HpRow/PlayerHPLabel.text = "❤️ YOUR HP: %d" % s["player_hp"]
	$VBox/HpRow/OppHPLabel.text = "☠️ OPP HP: %d" % s["opponent_hp"]
	_player_hp_bar.max_value = maxi(1, s.get("player_starting_hp", TuningData.BASE_PLAYER_HP) as int)
	_player_hp_bar.value = s["player_hp"] as int
	_opp_hp_bar.max_value = maxi(1, s.get("opponent_starting_hp", 1) as int)
	_opp_hp_bar.value = s["opponent_hp"] as int
	_update_status_trays(s)
	var remaining: float = maxf(0.0, TuningData.BATTLE_TIME_LIMIT - (s["battle_timer"] as float))
	$VBox/TimerRow/TimerLabel.text = "⏱ %.1fs" % remaining

	($VBox/ControlsRow/PauseButton as Button).text = "▶ Resume" if _paused else "⏸ Pause"
	($VBox/ControlsRow/PauseButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed1xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed15xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed2xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed1xButton as Button).modulate = Color.WHITE if _speed_mult == 1.0 else Color(0.55, 0.55, 0.55)
	($VBox/ControlsRow/Speed15xButton as Button).modulate = Color.WHITE if _speed_mult == 1.5 else Color(0.55, 0.55, 0.55)
	($VBox/ControlsRow/Speed2xButton as Button).modulate = Color.WHITE if _speed_mult == 2.0 else Color(0.55, 0.55, 0.55)
	_contrib_button.modulate = Color.WHITE if _contrib_visible else Color(0.55, 0.55, 0.55)
	_update_contrib_bars(s, is_result)

	if is_result:
		var dr: Dictionary = PhaseSystem.describe_result(s)
		var outcome: String = dr["outcome"] as String
		var wins: int = s["wins"] as int
		var lives: int = s["lives"] as int
		var result_text: String
		var next_label: String = "▶ Next Round"
		match outcome:
			"player_wins":
				if dr["is_victory"] as bool:
					result_text = "🏆 VICTORY — 10 wins!"
					next_label = "▶ Finish"
				else:
					result_text = "✅ YOU WIN  (Wins: %d→%d)" % [wins, dr["wins_after"] as int]
			"draw":
				if dr["is_victory"] as bool:
					result_text = "🏆 VICTORY — 10 wins!"
					next_label = "▶ Finish"
				else:
					result_text = "🤝 DRAW — counts as a win  (Wins: %d→%d)" % [wins, dr["wins_after"] as int]
			"opponent_wins":
				if dr["is_eliminated"] as bool:
					result_text = "💀 ELIMINATED — %d wins in %d rounds" % [wins, s["round"] as int]
					next_label = "▶ End"
				else:
					result_text = "💀 YOU LOSE  (Life: %d→%d)" % [lives, dr["lives_after"] as int]
		$VBox/ResultLabel.text = result_text
		$VBox/ResultLabel.visible = true
		$VBox/ButtonRow.visible = true
		($VBox/ButtonRow/NextRoundButton as Button).text = next_label


func _on_summary_pressed() -> void:
	AudioManager.play("click")
	_summary_visible = not _summary_visible
	$VBox/SummarySeparator.visible = _summary_visible
	$VBox/SummaryPanel.visible = _summary_visible
	if _summary_visible:
		_build_summary()
	($VBox/ButtonRow/SummaryButton as Button).text = "📊 Summary ▲" if _summary_visible else "📊 Summary"


func _build_summary() -> void:
	var container: Node = $VBox/SummaryPanel/SummaryVBox
	for child: Node in container.get_children():
		child.queue_free()

	var s: Dictionary = GameManager.state
	var battle_time: float = maxf(s["battle_timer"] as float, 0.001)
	var bstats: Dictionary = s["battle_stats"] as Dictionary

	var player_panel := _build_side_table(
		"YOU", ThemeData.COLOR_PLAYER_SIDE,
		s["battle_grid"] as Array, bstats["player"] as Array, battle_time
	)
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(player_panel)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(10, 0)
	container.add_child(gap)

	var opp_panel := _build_side_table(
		"OPPONENT", ThemeData.COLOR_OPP_SIDE,
		s["opponent_grid"] as Array, bstats["opponent"] as Array, battle_time
	)
	opp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(opp_panel)


func _build_side_table(title: String, accent: Color, grid: Array, stats: Array, battle_time: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.06, 0.04, 0.09, 0.95)
	outer.set_border_width_all(2)
	outer.border_color = accent.lerp(Color(0.15, 0.08, 0.22, 1.0), 0.55)
	outer.set_corner_radius_all(6)
	outer.content_margin_left = 0.0
	outer.content_margin_right = 0.0
	outer.content_margin_top = 0.0
	outer.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var hdr_bg: Color = accent.lerp(Color(0.04, 0.03, 0.07, 1.0), 0.72)
	vbox.add_child(_summary_row(
		[title, "Fires", "Dmg", "Effects", "DPS"],
		[accent, Color(0.72, 0.72, 0.72), Color(0.72, 0.72, 0.72), Color(0.72, 0.72, 0.72), Color(0.72, 0.72, 0.72)],
		hdr_bg, true
	))

	var any_elem: bool = false
	for i: int in 4:
		if grid[i] == null:
			continue
		any_elem = true
		var elem: Dictionary = grid[i] as Dictionary
		var st: Dictionary = stats[i] as Dictionary
		var fires: int = st["fires"] as int
		var dmg: int = st["damage"] as int
		var _fx_map: Dictionary = st.get("effects_by_status", {}) as Dictionary
		var fx_text: String = _format_effects(elem, st)
		var dps: float = float(dmg) / battle_time

		vbox.add_child(_summary_row(
			["%s %s L%d" % [elem["emoji"], elem["name"], elem["level"] as int],
			 "%d×" % fires, "%d" % dmg, fx_text, "%.1f" % dps],
			[Color.WHITE, Color(0.78, 0.78, 0.78), Color(1.0, 0.75, 0.4), Color(0.7, 0.95, 0.7), Color(0.6, 0.85, 1.0)],
			Color(0.0, 0.0, 0.0, 0.0), false
		))

	if not any_elem:
		vbox.add_child(_summary_row(
			["(no elements)", "", "", "", ""],
			[Color(0.5, 0.5, 0.5), Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE],
			Color(0.0, 0.0, 0.0, 0.0), false
		))

	return panel


func _summary_row(texts: Array, colors: Array, bg: Color, is_header: bool) -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	if not is_header:
		style.border_width_top = 1
		style.border_color = Color(0.25, 0.18, 0.32, 0.55)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	pc.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	pc.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = texts[0] if texts.size() > 0 else ""
	name_lbl.add_theme_color_override("font_color", colors[0] if colors.size() > 0 else Color.WHITE)
	UIScale.apply(name_lbl, UIScale.SUMMARY_HEADER if is_header else UIScale.SUMMARY_ROW)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	hbox.add_child(name_lbl)

	var col_widths: Array = [40, 38, 120, 44]
	for j: int in range(1, mini(texts.size(), 5)):
		var lbl := Label.new()
		lbl.text = texts[j]
		lbl.add_theme_color_override("font_color", colors[j] if j < colors.size() else Color.WHITE)
		UIScale.apply(lbl, UIScale.SUMMARY_ROW)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if is_header else HORIZONTAL_ALIGNMENT_RIGHT
		lbl.custom_minimum_size = Vector2(col_widths[j - 1], 0)
		hbox.add_child(lbl)

	return pc


# ── Effects formatting ────────────────────────────────────────────────────────

func _format_effects(elem: Dictionary, st: Dictionary) -> String:
	var fx_map: Dictionary = st.get("effects_by_status", {}) as Dictionary
	if fx_map.is_empty():
		return "—"
	var tier: int = elem.get("tier", 1) as int
	var result: String = ""
	if tier == 1:
		for status: Variant in fx_map:
			if result != "":
				result += "  "
			var s: String = status as String
			result += "Apply %d %s" % [fx_map[status] as int, s.substr(0, 1).to_upper() + s.substr(1)]
	else:
		var ability: Dictionary = AbilityData.get_ability(elem.get("id", "") as String)
		var tlabel: String = AbilityData.trigger_label(ability)
		for status: Variant in fx_map:
			if result != "":
				result += "  "
			var s: String = status as String
			var cap: String = s.substr(0, 1).to_upper() + s.substr(1)
			result += "%d %s (%s)" % [fx_map[status] as int, cap, tlabel] if tlabel != "" else "%d %s" % [fx_map[status] as int, cap]
	return result


# ── Item Tooltip ─────────────────────────────────────────────────────────────

func _on_tooltip_requested(element: Dictionary, side: String, slot: int) -> void:
	_tooltip.show_for_battle(element, side, slot)


func _on_tooltip_hide() -> void:
	_tooltip.hide_card()


# ── Speed / Pause ─────────────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	AudioManager.play("click")
	_paused = not _paused
	_render()


func _on_speed_1x_pressed() -> void:
	AudioManager.play("click")
	_speed_mult = 1.0
	_render()


func _on_speed_15x_pressed() -> void:
	AudioManager.play("click")
	_speed_mult = 1.5
	_render()


func _on_speed_2x_pressed() -> void:
	AudioManager.play("click")
	_speed_mult = 2.0
	_render()


# ── Pause overlay handlers ────────────────────────────────────────────────────

func _on_pause_resumed() -> void:
	_pause_overlay.hide_overlay()
	_paused = false


func _on_pause_settings() -> void:
	_pause_overlay.hide_overlay()
	_paused = false
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")


func _on_pause_forfeit() -> void:
	_pause_overlay.hide_overlay()
	GameManager.state = PhaseSystem.forfeit(GameManager.state)
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _on_pause_menu() -> void:
	_pause_overlay.hide_overlay()
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _on_next_round_pressed() -> void:
	AudioManager.play("click")
	var pre: Dictionary = GameManager.state
	# One resolver decides the Round; advance_round reads the same one internally, so
	# the achievement event can never disagree with how the Run progresses.
	var event: String = PhaseSystem.resolve_round(pre)["event"] as String
	GameManager.state = PhaseSystem.advance_round(pre)
	var phase: String = GameManager.state["phase"] as String

	var ach: Dictionary = AchievementSystem.check(pre, PlayerProfile.to_dict(), event)
	PlayerProfile.from_dict(ach["profile"] as Dictionary)
	if not (ach["unlocked"] as Array).is_empty() or event in ["match_win", "match_eliminated"]:
		PlayerProfile.save_profile()

	match phase:
		"victory":
			get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
		"eliminated":
			get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/screens/Shop.tscn")
