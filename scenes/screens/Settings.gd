extends Control

const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

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
	_render()
	_populate_bindings()


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
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")
