class_name Estilo
extends RefCounted
## Utilidades de interfaz compartidas (colores, botones, etiquetas, brasas).

const COLOR_TEXTO := Color(0.96, 0.88, 0.78)
const COLOR_BRASA := Color(1.0, 0.55, 0.15)
const COLOR_SANGRE := Color(0.85, 0.12, 0.1)


static func etiqueta(texto: String, tam: int = 20, color: Color = COLOR_TEXTO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.0, 0.0, 1.0))
	l.add_theme_constant_override("outline_size", maxi(3, tam / 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _caja(fondo: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.content_margin_left = 24.0
	s.content_margin_right = 24.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


static func boton(texto: String, ancho: float = 300.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(ancho, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", COLOR_TEXTO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _caja(Color(0.12, 0.03, 0.03, 0.92), Color(0.55, 0.16, 0.08)))
	b.add_theme_stylebox_override("hover", _caja(Color(0.30, 0.07, 0.04, 0.95), COLOR_BRASA))
	b.add_theme_stylebox_override("focus", _caja(Color(0.30, 0.07, 0.04, 0.95), COLOR_BRASA))
	b.add_theme_stylebox_override("pressed", _caja(Color(0.5, 0.12, 0.05, 1.0), Color.WHITE))
	b.add_theme_stylebox_override("disabled", _caja(Color(0.08, 0.05, 0.05, 0.8), Color(0.25, 0.2, 0.2)))
	return b


## Brasas que suben (decorativo) para menús y pantallas de texto.
static func brasas(ancho: float, alto: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(ancho * 0.5, alto + 10.0)
	p.amount = 70
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(ancho * 0.6, 4.0)
	p.direction = Vector2(0.15, -1.0)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.5, 0.15, 0.85)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	g.set_color(1, Color(0.6, 0.1, 0.05, 0.0))
	p.color_ramp = g
	return p
