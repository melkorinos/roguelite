extends Control

const RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160),  # 2K, 4K — playtesting at high DPI
]

const CONTROL_ACTIONS: Array[String] = [
	"ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right",
]
const CONTROL_LABELS: Array[String] = [
	"Confirm", "Cancel / Back", "Up", "Down", "Left", "Right",
]

@onready var _master_slider: HSlider    = $VBox/Tabs/Audio/AudioVBox/MasterRow/MasterSlider
@onready var _master_val: Label         = $VBox/Tabs/Audio/AudioVBox/MasterRow/MasterVal
@onready var _music_slider: HSlider     = $VBox/Tabs/Audio/AudioVBox/MusicRow/MusicSlider
@onready var _music_val: Label          = $VBox/Tabs/Audio/AudioVBox/MusicRow/MusicVal
@onready var _sfx_slider: HSlider       = $VBox/Tabs/Audio/AudioVBox/SfxRow/SfxSlider
@onready var _sfx_val: Label            = $VBox/Tabs/Audio/AudioVBox/SfxRow/SfxVal
@onready var _fullscreen_btn: CheckButton  = $VBox/Tabs/Video/VideoVBox/FullscreenRow/FullscreenBtn
@onready var _vsync_btn: CheckButton       = $VBox/Tabs/Video/VideoVBox/VsyncRow/VsyncBtn
@onready var _resolution_opt: OptionButton = $VBox/Tabs/Video/VideoVBox/ResRow/ResolutionOpt
@onready var _binding_list: VBoxContainer  = $VBox/Tabs/Controls/ControlsVBox/BindingList

var _loading: bool = false


func _ready() -> void:
	_apply_theme()
	_render()
	_populate_bindings()


func _apply_theme() -> void:
	($VBox/TitleLabel as Label).add_theme_color_override("font_color", ThemeData.COLOR_TITLE)

	# ── Tab container ─────────────────────────────────────────────────────────
	var tabs: TabContainer = $VBox/Tabs as TabContainer

	var content_style := StyleBoxFlat.new()
	content_style.bg_color = Color(0.05, 0.04, 0.10, 0.96)
	content_style.set_border_width_all(1)
	content_style.border_color = Color(0.22, 0.14, 0.36, 0.55)
	content_style.set_corner_radius_all(6)
	tabs.add_theme_stylebox_override("panel", content_style)

	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = Color(0.14, 0.07, 0.26, 1.0)
	tab_sel.set_border_width_all(1)
	tab_sel.border_color = ThemeData.FORGE_SLOT_BORDER
	tab_sel.set_corner_radius_all(4)
	tabs.add_theme_stylebox_override("tab_selected", tab_sel)

	var tab_unsel := StyleBoxFlat.new()
	tab_unsel.bg_color = Color(0.07, 0.05, 0.12, 0.90)
	tab_unsel.set_corner_radius_all(4)
	tabs.add_theme_stylebox_override("tab_unselected", tab_unsel)

	var tab_hover := StyleBoxFlat.new()
	tab_hover.bg_color = Color(0.11, 0.06, 0.20, 0.95)
	tab_hover.set_corner_radius_all(4)
	tabs.add_theme_stylebox_override("tab_hovered", tab_hover)

	tabs.add_theme_color_override("font_selected_color", ThemeData.COLOR_HEADER_FORGE)
	tabs.add_theme_color_override("font_unselected_color", ThemeData.COLOR_SUBTITLE)

	# ── Sliders ───────────────────────────────────────────────────────────────
	_style_slider(_master_slider, Color(0.88, 0.68, 0.18))  # gold  — master
	_style_slider(_music_slider,  Color(0.30, 0.58, 0.95))  # blue  — music
	_style_slider(_sfx_slider,    Color(0.65, 0.30, 0.95))  # violet — sfx

	# ── Value labels ──────────────────────────────────────────────────────────
	for lbl: Variant in [_master_val, _music_val, _sfx_val]:
		(lbl as Label).add_theme_color_override("font_color", ThemeData.COLOR_ROUND_LABEL)

	# ── Section row labels ────────────────────────────────────────────────────
	_tint_label($VBox/Tabs/Audio/AudioVBox/MasterRow/MasterLabel, Color(0.88, 0.68, 0.18))
	_tint_label($VBox/Tabs/Audio/AudioVBox/MusicRow/MusicLabel,   Color(0.30, 0.58, 0.95))
	_tint_label($VBox/Tabs/Audio/AudioVBox/SfxRow/SfxLabel,       Color(0.65, 0.30, 0.95))
	_tint_label($VBox/Tabs/Video/VideoVBox/FullscreenRow/FullscreenLabel, ThemeData.COLOR_ROUND_LABEL)
	_tint_label($VBox/Tabs/Video/VideoVBox/VsyncRow/VsyncLabel,           ThemeData.COLOR_ROUND_LABEL)
	_tint_label($VBox/Tabs/Video/VideoVBox/ResRow/ResLabel,               ThemeData.COLOR_ROUND_LABEL)

	# ── Back button ───────────────────────────────────────────────────────────
	var back: Button = $VBox/BackButton as Button
	var back_normal := StyleBoxFlat.new()
	back_normal.bg_color = Color(0.09, 0.05, 0.17, 0.95)
	back_normal.set_border_width_all(2)
	back_normal.border_color = ThemeData.FORGE_PANEL_BORDER
	back_normal.set_corner_radius_all(6)
	back.add_theme_stylebox_override("normal", back_normal)

	var back_hover := StyleBoxFlat.new()
	back_hover.bg_color = Color(0.14, 0.07, 0.26, 1.0)
	back_hover.set_border_width_all(2)
	back_hover.border_color = ThemeData.FORGE_SLOT_BORDER
	back_hover.set_corner_radius_all(6)
	back.add_theme_stylebox_override("hover", back_hover)

	var back_pressed_style := StyleBoxFlat.new()
	back_pressed_style.bg_color = Color(0.07, 0.04, 0.13, 1.0)
	back_pressed_style.set_border_width_all(2)
	back_pressed_style.border_color = ThemeData.FORGE_PANEL_BORDER
	back_pressed_style.set_corner_radius_all(6)
	back.add_theme_stylebox_override("pressed", back_pressed_style)

	back.add_theme_color_override("font_color", ThemeData.COLOR_HEADER_FORGE)


func _style_slider(slider: HSlider, fill_color: Color) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = ThemeData.SLOT_BG_EMPTY
	track.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("slider", track)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", fill)

	var fill_hi := StyleBoxFlat.new()
	fill_hi.bg_color = fill_color.lightened(0.18)
	fill_hi.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hi)


func _tint_label(node: Node, color: Color) -> void:
	(node as Label).add_theme_color_override("font_color", color)


func _render() -> void:
	_loading = true

	_master_slider.value = SettingsManager.get_master_volume()
	_master_val.text = _pct(_master_slider.value)

	_music_slider.value = SettingsManager.get_music_volume()
	_music_val.text = _pct(_music_slider.value)

	_sfx_slider.value = SettingsManager.get_sfx_volume()
	_sfx_val.text = _pct(_sfx_slider.value)

	_fullscreen_btn.button_pressed = SettingsManager.get_fullscreen()
	_vsync_btn.button_pressed = SettingsManager.get_vsync()

	_resolution_opt.clear()
	var current_res: Vector2i = SettingsManager.get_resolution()
	var selected: int = 0
	for i: int in RESOLUTIONS.size():
		var r: Vector2i = RESOLUTIONS[i]
		_resolution_opt.add_item("%d x %d" % [r.x, r.y])
		if r == current_res:
			selected = i
	_resolution_opt.selected = selected

	_loading = false


func _populate_bindings() -> void:
	for i: int in CONTROL_ACTIONS.size():
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var action_lbl: Label = Label.new()
		action_lbl.text = CONTROL_LABELS[i]
		action_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(action_lbl)

		var key_lbl: Label = Label.new()
		key_lbl.text = _read_binding(CONTROL_ACTIONS[i])
		row.add_child(key_lbl)

		_binding_list.add_child(row)


func _read_binding(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	var parts: PackedStringArray
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			parts.append(event.as_text())
	return "  /  ".join(parts) if not parts.is_empty() else "-"


func _pct(v: float) -> String:
	return "%d%%" % roundi(v * 100.0)


# --- Audio signals ---

func _on_master_slider_changed(value: float) -> void:
	if _loading:
		return
	SettingsManager.set_master_volume(value)
	_master_val.text = _pct(value)


func _on_music_slider_changed(value: float) -> void:
	if _loading:
		return
	SettingsManager.set_music_volume(value)
	_music_val.text = _pct(value)


func _on_sfx_slider_changed(value: float) -> void:
	if _loading:
		return
	SettingsManager.set_sfx_volume(value)
	_sfx_val.text = _pct(value)
	var db: float = -80.0 if value <= 0.001 else linear_to_db(value)
	AudioManager.set_volume_db(db)


# --- Video signals ---

func _on_fullscreen_toggled(toggled: bool) -> void:
	if _loading:
		return
	SettingsManager.set_fullscreen(toggled)


func _on_vsync_toggled(toggled: bool) -> void:
	if _loading:
		return
	SettingsManager.set_vsync(toggled)


func _on_resolution_selected(index: int) -> void:
	if _loading:
		return
	SettingsManager.set_resolution(RESOLUTIONS[index])


func _on_back_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
