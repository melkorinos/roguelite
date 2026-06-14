extends Control

var _player_slots: Array[BattleSlot] = []
var _opp_slots: Array[BattleSlot] = []
# The two side VBoxes get reparented into ScenePanels in _apply_theme; the live render
# reaches them through these refs (not $ paths, which the reframe invalidates).
var _player_side: VBoxContainer
var _opp_side: VBoxContainer
var _paused: bool = false
var _speed_mult: float = 1.0
var _pause_overlay: PauseOverlay
# Battle Summary is a centered pop-up overlay (built once, toggled by the Summary button).
var _summary_overlay: CanvasLayer
var _summary_content: HBoxContainer
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
var _contrib_panel: ScenePanel
var _contrib_button: Button
var _contrib_rows: Array = []   # [{ slot, bg: Panel, segments: {type: ColorRect}, displayed: {type: float} }]
var _contrib_max: float = 1.0   # running max element total; monotonic within this combat
var _contrib_visible: bool = true
const CONTRIB_BAR_WIDTH: float = 150.0
const CONTRIB_BAR_HEIGHT: float = 16.0


func _ready() -> void:
	_pause_overlay = PauseOverlay.new()
	add_child(_pause_overlay)
	_pause_overlay.resumed.connect(_on_pause_resumed)
	_pause_overlay.settings_requested.connect(_on_pause_settings)
	_pause_overlay.forfeit_requested.connect(_on_pause_forfeit)
	_pause_overlay.quit_to_menu_requested.connect(_on_pause_menu)
	_pause_overlay.quit_to_desktop_requested.connect(func() -> void: get_tree().quit())

	_apply_theme()

	_player_hp_bar = $VBox/HpBarRow/PlayerHpBar as ProgressBar
	_opp_hp_bar = $VBox/HpBarRow/OppHpBar as ProgressBar
	_style_hp_bar(_player_hp_bar)
	_style_hp_bar(_opp_hp_bar)

	_build_grids()
	_build_status_trays()
	_build_contrib_panel()
	_build_summary_overlay()
	_render()


# Frames the two boards in ScenePanels (you = inventory-green, enemy = battle-red), themes
# every control button to the battle accent, and drops the .tscn separators (the frames +
# spacing rhythm divide the screen now). Runs before _build_grids/_build_status_trays so
# those reach the side VBoxes through _player_side/_opp_side rather than $ paths.
func _apply_theme() -> void:
	($VBox/Header as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_BATTLE)
	($VBox/TimerRow/TimerLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_ROUND_LABEL)
	($VBox/ResultLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_HEADER_BATTLE)

	for sep: Variant in [$VBox/Separator1, $VBox/Separator2, $VBox/Separator3, $VBox/Separator4]:
		(sep as Control).visible = false
	($VBox/BattleRow/CenterSep as Control).visible = false

	for b: Variant in [
		$VBox/ControlsRow/PauseButton, $VBox/ControlsRow/Speed1xButton,
		$VBox/ControlsRow/Speed15xButton, $VBox/ControlsRow/Speed2xButton,
		$VBox/ButtonRow/NextRoundButton, $VBox/ButtonRow/SummaryButton,
	]:
		UIStyle.accent_button(b as Button, ThemeData.AREA_BATTLE)

	_player_side = $VBox/BattleRow/PlayerSide as VBoxContainer
	_opp_side = $VBox/BattleRow/OppSide as VBoxContainer
	# The panel headers carry YOU / OPPONENT now, so the inner labels are redundant.
	($VBox/BattleRow/PlayerSide/PlayerLabel as Label).visible = false
	($VBox/BattleRow/OppSide/OppLabel as Label).visible = false

	var battle_row: HBoxContainer = $VBox/BattleRow
	battle_row.add_theme_constant_override("separation", LayoutData.COLUMN_GAP)

	var player_panel := ScenePanel.new()
	player_panel.setup("YOU", "🛡", ThemeData.AREA_INVENTORY)
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.add_child(player_panel)
	battle_row.move_child(player_panel, 0)
	_player_side.reparent(player_panel.body())
	_player_side.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var opp_panel := ScenePanel.new()
	opp_panel.setup("OPPONENT", "☠", ThemeData.AREA_BATTLE)
	opp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.add_child(opp_panel)
	battle_row.move_child(opp_panel, 2)  # after PlayerPanel(0) + hidden CenterSep(1)
	_opp_side.reparent(opp_panel.body())
	_opp_side.size_flags_vertical = Control.SIZE_EXPAND_FILL


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
	_player_chips = _build_tray(_player_side)
	_opp_chips = _build_tray(_opp_side)


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
	UIStyle.accent_button(_contrib_button, ThemeData.AREA_BATTLE)
	_contrib_button.pressed.connect(_on_contrib_toggle)
	$VBox/ControlsRow.add_child(_contrib_button)

	# Live DPS sidebar in the shared beveled frame (battle-red accent); its header carries
	# the CONTRIBUTION title now, so the bar rows go straight into the panel body.
	_contrib_panel = ScenePanel.new()
	_contrib_panel.setup("CONTRIBUTION", "📊", ThemeData.AREA_BATTLE)
	_contrib_panel.custom_minimum_size = Vector2(CONTRIB_BAR_WIDTH + 64.0, 0)
	_contrib_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	$VBox/BattleRow.add_child(_contrib_panel)  # rightmost child → right gutter

	var vbox: VBoxContainer = _contrib_panel.body()
	vbox.add_theme_constant_override("separation", 6)

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
	# Refresh the running max (monotonic within this combat) from BattleSystem totals.
	var totals: Array[float] = BattleSystem.contribution_totals(s, "player")
	for entry: Variant in _contrib_rows:
		var slot_idx: int = (entry as Dictionary)["slot"] as int
		if slot_idx < totals.size():
			_contrib_max = maxf(_contrib_max, totals[slot_idx])
	var denom: float = maxf(_contrib_max, 1.0)
	# Stack the segments left→right at their normalised widths.
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
	var pgrid_node: GridContainer = _player_side.get_node("PlayerGrid")
	var ogrid_node: GridContainer = _opp_side.get_node("OppGrid")

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
	var fx: Dictionary = EffectRegistry.float_label_with_amount(effect, dmg)
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


# Builds the Battle Summary pop-up once: a centered dialog over a dimmer holding the two
# side tables; clicking the dimmer or Close dismisses it. Toggled by the Summary button.
func _build_summary_overlay() -> void:
	_summary_overlay = CanvasLayer.new()
	_summary_overlay.layer = 105
	_summary_overlay.visible = false
	add_child(_summary_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = ThemeData.OVERLAY_DIMMER
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_hide_summary())
	_summary_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.dialog_panel(ThemeData.AREA_BATTLE))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "BATTLE SUMMARY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIScale.apply(title, UIScale.TOOLTIP_TITLE)
	title.add_theme_color_override("font_color", ThemeData.COLOR_HEADER_BATTLE)
	vbox.add_child(title)

	_summary_content = HBoxContainer.new()
	_summary_content.add_theme_constant_override("separation", 10)
	vbox.add_child(_summary_content)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(180, 0)
	UIStyle.accent_button(close, ThemeData.AREA_BATTLE)
	close.pressed.connect(_hide_summary)
	vbox.add_child(close)


func _on_summary_pressed() -> void:
	AudioManager.play("click")
	if _summary_overlay.visible:
		_hide_summary()
	else:
		_build_summary()
		_summary_overlay.visible = true
		($VBox/ButtonRow/SummaryButton as Button).text = "📊 Summary ▲"


func _hide_summary() -> void:
	_summary_overlay.visible = false
	($VBox/ButtonRow/SummaryButton as Button).text = "📊 Summary"


func _build_summary() -> void:
	var container: Node = _summary_content
	for child: Node in container.get_children():
		child.queue_free()

	var s: Dictionary = GameManager.state

	var player_panel := _build_side_table(
		"YOU", ThemeData.COLOR_PLAYER_SIDE, BattleSystem.summary_rows(s, "player")
	)
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(player_panel)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(10, 0)
	container.add_child(gap)

	var opp_panel := _build_side_table(
		"OPPONENT", ThemeData.COLOR_OPP_SIDE, BattleSystem.summary_rows(s, "opponent")
	)
	opp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(opp_panel)


func _build_side_table(title: String, accent: Color, rows: Array[Dictionary]) -> PanelContainer:
	var panel := PanelContainer.new()
	var outer := StyleBoxFlat.new()
	outer.bg_color = ThemeData.PANEL_INTERIOR
	outer.set_border_width_all(2)
	outer.border_color = accent
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

	for row: Dictionary in rows:
		vbox.add_child(_summary_row(
			[row["name"] as String,
			 "%d×" % (row["fires"] as int), "%d" % (row["damage"] as int),
			 row["effects"] as String, "%.1f" % (row["dps"] as float)],
			[Color.WHITE, Color(0.78, 0.78, 0.78), Color(1.0, 0.75, 0.4), Color(0.7, 0.95, 0.7), Color(0.6, 0.85, 1.0)],
			Color(0.0, 0.0, 0.0, 0.0), false
		))

	if rows.is_empty():
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
