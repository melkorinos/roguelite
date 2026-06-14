class_name UIStyle

# Shared widget styling assembled from ThemeData tokens — keeps every screen's buttons,
# dialog panels, and sliders drawing from one place instead of per-scene StyleBoxFlat
# soup. Colors/geometry come from ThemeData; this only assembles them into styleboxes.
#
# Family: ScenePanel = the beveled "hardware" frame for areas/screens; UIStyle = the
# small chrome (buttons, lighter pop-up panels, sliders) that sits inside those frames.
# Both read the same ThemeData accents, so a screen picks ONE accent and themes its
# frame + its widgets from it.


# ── Accent buttons ─────────────────────────────────────────────────────────────
# Themes a button to an accent: near-black interior, accent rim, accent-lightened text.
# Hover fills with a dim accent; pressed goes a touch darker. Used by every menu/back
# button and the pop-up actions so buttons match their screen's frame.
static func accent_button(btn: Button, accent: Color) -> void:
	var interior: Color = ThemeData.PANEL_INTERIOR
	btn.add_theme_stylebox_override("normal", _button_box(interior, accent.darkened(0.15), 2))
	btn.add_theme_stylebox_override("hover", _button_box(accent.darkened(0.68), accent, 2))
	btn.add_theme_stylebox_override("pressed", _button_box(accent.darkened(0.78), accent.darkened(0.2), 2))
	btn.add_theme_stylebox_override("disabled", _button_box(interior, accent.darkened(0.6), 1))
	btn.add_theme_color_override("font_color", accent.lightened(0.4))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", accent.darkened(0.35))


static func _button_box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 7.0
	sb.content_margin_bottom = 7.0
	return sb


# ── Lighter pop-up dialog panel (the "retint", NOT the beveled hardware frame) ──
# A flat near-black panel with an accent rim — what overlays use so they read lighter
# than the screen frames while still drawing from the same tokens.
static func dialog_panel(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeData.PANEL_INTERIOR
	sb.set_border_width_all(2)
	sb.border_color = accent
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	return sb


# A nested card inside a dialog (e.g. a Keystone / reward tile): slightly lifted off the
# dialog interior so the tiles separate, accent rim.
static func dialog_card(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent.darkened(0.82)
	sb.set_border_width_all(1)
	sb.border_color = accent.darkened(0.1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb
