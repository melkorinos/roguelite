extends Control

var _player_slots: Array[BattleSlot] = []
var _opp_slots: Array[BattleSlot] = []
var _summary_visible: bool = false
var _paused: bool = false
var _speed_mult: float = 1.0
var _tooltip: TooltipCard
var _pause_overlay: PauseOverlay


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

	_build_grids()
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
	GameManager.state = BattleSystem.tick_battle(GameManager.state, delta * _speed_mult)
	_update_progress_bars(GameManager.state)
	_process_fire_events(GameManager.state)
	_render()


func _build_grids() -> void:
	var s: Dictionary = GameManager.state
	var pgrid_node: Node = $VBox/BattleRow/PlayerSide/PlayerGrid
	var ogrid_node: Node = $VBox/BattleRow/OppSide/OppGrid

	_player_slots.clear()
	_opp_slots.clear()

	for i: int in 4:
		var ps: BattleSlot = BattleSlot.new()
		ps.slot_index = i
		ps.draggable = false
		ps.tooltip_requested.connect(_on_tooltip_requested)
		ps.tooltip_hide_requested.connect(_on_tooltip_hide)
		pgrid_node.add_child(ps)
		ps.set_element(s["battle_grid"][i])
		_player_slots.append(ps)

		var os: BattleSlot = BattleSlot.new()
		os.slot_index = i
		os.draggable = false
		os.tooltip_requested.connect(_on_tooltip_requested)
		os.tooltip_hide_requested.connect(_on_tooltip_hide)
		ogrid_node.add_child(os)
		os.set_element(s["opponent_grid"][i])
		_opp_slots.append(os)


func _update_progress_bars(s: Dictionary) -> void:
	var pgrid: Array = s["battle_grid"]
	var ptimers: Array = s["element_timers"]
	for i: int in 4:
		if pgrid[i] == null:
			continue
		var elem: Dictionary = pgrid[i] as Dictionary
		var ratio: float = (ptimers[i] as float) / (elem["cooldown"] as float)
		_player_slots[i].set_cooldown_progress(ratio)

	var ogrid: Array = s["opponent_grid"]
	var otimers: Array = s["opponent_timers"]
	for i: int in 4:
		if ogrid[i] == null:
			continue
		var elem: Dictionary = ogrid[i] as Dictionary
		var ratio: float = (otimers[i] as float) / (elem["cooldown"] as float)
		_opp_slots[i].set_cooldown_progress(ratio)


func _process_fire_events(s: Dictionary) -> void:
	for event: Variant in s["battle_events"]:
		var e: Dictionary = event as Dictionary
		var idx: int = e["slot"] as int
		if e["side"] == "player":
			_player_slots[idx].play_fire_animation()
		else:
			_opp_slots[idx].play_fire_animation()


func _render() -> void:
	var s: Dictionary = GameManager.state
	var is_result: bool = s["phase"] == "result"

	$VBox/Header.text = "BATTLE — Round %d  |  Lives: %d  Wins: %d/10" % [s["round"], s["lives"], s["wins"]]
	$VBox/HpRow/PlayerHPLabel.text = "❤️ YOUR HP: %d" % s["player_hp"]
	$VBox/HpRow/OppHPLabel.text = "☠️ OPP HP: %d" % s["opponent_hp"]
	var remaining: float = maxf(0.0, BattleSystem.BATTLE_TIME_LIMIT - (s["battle_timer"] as float))
	$VBox/TimerRow/TimerLabel.text = "⏱ %.1fs" % remaining

	($VBox/ControlsRow/PauseButton as Button).text = "▶ Resume" if _paused else "⏸ Pause"
	($VBox/ControlsRow/PauseButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed1xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed15xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed2xButton as Button).disabled = is_result
	($VBox/ControlsRow/Speed1xButton as Button).modulate = Color.WHITE if _speed_mult == 1.0 else Color(0.55, 0.55, 0.55)
	($VBox/ControlsRow/Speed15xButton as Button).modulate = Color.WHITE if _speed_mult == 1.5 else Color(0.55, 0.55, 0.55)
	($VBox/ControlsRow/Speed2xButton as Button).modulate = Color.WHITE if _speed_mult == 2.0 else Color(0.55, 0.55, 0.55)

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
					result_text = "💀 YOU LOSE  (Lives: %d→%d)" % [lives, dr["lives_after"] as int]
		$VBox/ResultLabel.text = result_text
		$VBox/ResultLabel.visible = true
		$VBox/ButtonRow.visible = true
		($VBox/ButtonRow/NextRoundButton as Button).text = next_label


func _on_summary_pressed() -> void:
	_summary_visible = not _summary_visible
	$VBox/SummarySeparator.visible = _summary_visible
	$VBox/SummaryPanel.visible = _summary_visible
	if _summary_visible:
		_build_summary()
	($VBox/ButtonRow/SummaryButton as Button).text = "📊 Summary ▲" if _summary_visible else "📊 Summary"


func _build_summary() -> void:
	var vbox: Node = $VBox/SummaryPanel/SummaryVBox
	for child: Node in vbox.get_children():
		child.queue_free()

	var s: Dictionary = GameManager.state
	var battle_time: float = maxf(s["battle_timer"] as float, 0.001)
	var bstats: Dictionary = s["battle_stats"] as Dictionary

	_add_summary_header(vbox, "YOUR ELEMENTS", Color(0.4, 0.9, 0.5))
	_add_summary_rows(vbox, s["battle_grid"] as Array, bstats["player"] as Array, battle_time)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_add_summary_header(vbox, "OPPONENT", Color(0.9, 0.4, 0.4))
	_add_summary_rows(vbox, s["opponent_grid"] as Array, bstats["opponent"] as Array, battle_time)


func _add_summary_header(parent: Node, title: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.modulate = color
	UIScale.apply(lbl, UIScale.SUMMARY_HEADER)
	parent.add_child(lbl)


func _add_summary_rows(parent: Node, grid: Array, stats: Array, battle_time: float) -> void:
	var any: bool = false
	for i: int in 4:
		if grid[i] == null:
			continue
		any = true
		var elem: Dictionary = grid[i] as Dictionary
		var st: Dictionary = stats[i] as Dictionary
		var fires: int = st["fires"] as int
		var dmg: int = st["damage"] as int
		var dps: float = dmg / battle_time

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var name_lbl := Label.new()
		name_lbl.text = "%s  %s Lv%d" % [elem["emoji"], elem["name"], elem["level"] as int]
		UIScale.apply(name_lbl, UIScale.SUMMARY_ROW)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var fires_lbl := Label.new()
		fires_lbl.text = "fired %d×" % fires
		UIScale.apply(fires_lbl, UIScale.SUMMARY_ROW)
		fires_lbl.modulate = Color(0.8, 0.8, 0.8)
		row.add_child(fires_lbl)

		var dmg_lbl := Label.new()
		dmg_lbl.text = "%d dmg" % dmg
		UIScale.apply(dmg_lbl, UIScale.SUMMARY_ROW)
		dmg_lbl.modulate = Color(1.0, 0.75, 0.4)
		row.add_child(dmg_lbl)

		var dps_lbl := Label.new()
		dps_lbl.text = "%.1f dps" % dps
		UIScale.apply(dps_lbl, UIScale.SUMMARY_ROW)
		dps_lbl.modulate = Color(0.6, 0.85, 1.0)
		row.add_child(dps_lbl)

		parent.add_child(row)

	if not any:
		var empty := Label.new()
		empty.text = "  (no elements)"
		empty.modulate = Color(0.5, 0.5, 0.5)
		UIScale.apply(empty, UIScale.SUMMARY_EMPTY)
		parent.add_child(empty)


# ── Item Tooltip ─────────────────────────────────────────────────────────────

func _on_tooltip_requested(element: Dictionary) -> void:
	_tooltip.show_for(element)


func _on_tooltip_hide() -> void:
	_tooltip.hide_card()


# ── Speed / Pause ─────────────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	_paused = not _paused
	_render()


func _on_speed_1x_pressed() -> void:
	_speed_mult = 1.0
	_render()


func _on_speed_15x_pressed() -> void:
	_speed_mult = 1.5
	_render()


func _on_speed_2x_pressed() -> void:
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
	var pre: Dictionary = GameManager.state
	GameManager.state = PhaseSystem.advance_round(pre)
	var phase: String = GameManager.state["phase"] as String

	var event: String
	match phase:
		"victory":
			event = "match_win"
		"eliminated":
			event = "match_eliminated"
		_:
			event = "round_win" if (pre["opponent_hp"] as int) <= 0 else "round_loss"

	AchievementSystem.check(pre, event)

	match phase:
		"victory":
			get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
		"eliminated":
			get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/screens/Shop.tscn")
