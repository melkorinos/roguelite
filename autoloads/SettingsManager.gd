extends Node

const CONFIG_PATH := "user://settings.cfg"

const DEFAULT_MASTER_VOL := 1.0
const DEFAULT_MUSIC_VOL  := 0.8
const DEFAULT_SFX_VOL    := 1.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC      := true
const DEFAULT_RES_W      := 1280
const DEFAULT_RES_H      := 720

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(CONFIG_PATH)
	_apply_all()


func _apply_all() -> void:
	_apply_volume("Master", get_master_volume())
	_apply_volume("Music",  get_music_volume())
	_apply_volume("SFX",    get_sfx_volume())
	_apply_window_mode(get_fullscreen())
	_apply_vsync(get_vsync())


# --- Audio ---

func get_master_volume() -> float:
	return _config.get_value("audio", "master", DEFAULT_MASTER_VOL)

func set_master_volume(value: float) -> void:
	_config.set_value("audio", "master", value)
	_apply_volume("Master", value)
	_save()

func get_music_volume() -> float:
	return _config.get_value("audio", "music", DEFAULT_MUSIC_VOL)

func set_music_volume(value: float) -> void:
	_config.set_value("audio", "music", value)
	_apply_volume("Music", value)
	_save()

func get_sfx_volume() -> float:
	return _config.get_value("audio", "sfx", DEFAULT_SFX_VOL)

func set_sfx_volume(value: float) -> void:
	_config.set_value("audio", "sfx", value)
	_apply_volume("SFX", value)
	_save()

func _apply_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


# --- Video ---

func get_fullscreen() -> bool:
	return _config.get_value("video", "fullscreen", DEFAULT_FULLSCREEN)

func set_fullscreen(value: bool) -> void:
	_config.set_value("video", "fullscreen", value)
	_apply_window_mode(value)
	_save()

func get_vsync() -> bool:
	return _config.get_value("video", "vsync", DEFAULT_VSYNC)

func set_vsync(value: bool) -> void:
	_config.set_value("video", "vsync", value)
	_apply_vsync(value)
	_save()

func get_resolution() -> Vector2i:
	var w: int = _config.get_value("video", "res_w", DEFAULT_RES_W)
	var h: int = _config.get_value("video", "res_h", DEFAULT_RES_H)
	return Vector2i(w, h)

func set_resolution(value: Vector2i) -> void:
	_config.set_value("video", "res_w", value.x)
	_config.set_value("video", "res_h", value.y)
	if not get_fullscreen():
		DisplayServer.window_set_size(value)
	_save()

func _apply_window_mode(fullscreen: bool) -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(get_resolution())

func _apply_vsync(enabled: bool) -> void:
	var mode := DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _save() -> void:
	_config.save(CONFIG_PATH)
