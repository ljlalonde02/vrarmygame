class_name TacticalTheme
extends RefCounted
## Programmatic Tactical UI Theme & Master Color Palette ("HighFleet + DEFCON + VTOL VR" aesthetic).
## Enforces the Zero-Programmer-Art visual contract across all 2D HUD panels, 3D diegetic cards, and shaders.

# Master Color Palette (Section 0.1 of IMPLEMENTATION_PLAN.md)
const COL_BUNKER_VOID := Color(0.02, 0.03, 0.055, 1.0)       # #05080E
const COL_GLASS_PANEL := Color(0.04, 0.067, 0.11, 0.92)     # #0A111CEB
const COL_GLASS_HEADER := Color(0.06, 0.10, 0.16, 0.96)
const COL_NATO_BLUE := Color(0.0, 0.85, 1.0, 1.0)           # #00D8FF
const COL_NATO_BLUE_DIM := Color(0.0, 0.85, 1.0, 0.40)      # #00D8FF66
const COL_OPFOR_RED := Color(1.0, 0.165, 0.33, 1.0)         # #FF2A54
const COL_OPFOR_RED_DIM := Color(1.0, 0.165, 0.33, 0.40)
const COL_UNMANNED_GOLD := Color(1.0, 0.72, 0.0, 1.0)       # #FFB800
const COL_DIRECTED_ENERGY := Color(0.72, 0.30, 1.0, 1.0)    # #B84DFF
const COL_CONTOUR_EMERALD := Color(0.08, 0.52, 0.47, 1.0)   # #148578
const COL_TEXT_PRIMARY := Color(0.90, 0.96, 1.0, 1.0)
const COL_TEXT_MUTED := Color(0.55, 0.70, 0.82, 1.0)
const COL_FLIR_GREEN := Color(0.18, 0.98, 0.48, 1.0)


static func create_panel_style(border_color: Color = COL_NATO_BLUE_DIM, bg_color: Color = COL_GLASS_PANEL, border_px: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_px)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	sb.shadow_size = 8
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


static func create_button_style(border_color: Color, bg_color: Color, border_px: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_px)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	sb.shadow_size = 4
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14

	# Panel & PanelContainer
	var panel_sb := create_panel_style(COL_NATO_BLUE_DIM, COL_GLASS_PANEL, 1)
	theme.set_stylebox("panel", "Panel", panel_sb)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)

	# Button states
	var btn_normal := create_button_style(COL_NATO_BLUE_DIM, Color(0.05, 0.09, 0.15, 0.94), 1)
	var btn_hover := create_button_style(COL_NATO_BLUE, Color(0.08, 0.16, 0.26, 0.98), 2)
	var btn_pressed := create_button_style(COL_UNMANNED_GOLD, Color(0.12, 0.22, 0.34, 1.0), 2)
	var btn_disabled := create_button_style(Color(0.2, 0.25, 0.3, 0.4), Color(0.03, 0.04, 0.06, 0.7), 1)

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("focus", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)

	theme.set_color("font_color", "Button", COL_TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", COL_NATO_BLUE)
	theme.set_color("font_pressed_color", "Button", COL_UNMANNED_GOLD)
	theme.set_color("font_color", "Label", COL_TEXT_PRIMARY)
	theme.set_color("default_color", "RichTextLabel", COL_TEXT_PRIMARY)

	return theme
