extends CanvasLayer
## HUD: corazones, vidas, puntos, barra del jefe, banner de nivel y avisos.

var _dibujo: Control
var _lbl_vidas: Label
var _lbl_puntos: Label
var _lbl_monedas: Label
var _lbl_banner: Label
var _lbl_sub: Label
var _lbl_aviso: Label
var _lbl_jefe: Label
var _forma_corazon: PackedVector2Array
var _tw_banner: Tween
var _tw_aviso: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 28:
		var a := TAU * i / 28.0
		_forma_corazon.append(Vector2(16.0 * pow(sin(a), 3.0),
			-(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * 0.8)

	_dibujo = Control.new()
	_dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dibujo.draw.connect(_dibujar)
	add_child(_dibujo)

	_lbl_vidas = Estilo.etiqueta("", 20)
	_lbl_vidas.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_lbl_vidas.position = Vector2(20, 62)
	add_child(_lbl_vidas)

	_lbl_puntos = Estilo.etiqueta("", 22)
	_lbl_puntos.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_lbl_puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_puntos.offset_right = -20.0
	_lbl_puntos.offset_top = 14.0
	add_child(_lbl_puntos)

	_lbl_monedas = Estilo.etiqueta("", 20, Color(1.0, 0.85, 0.1))
	_lbl_monedas.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_lbl_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_monedas.offset_right = -20.0
	_lbl_monedas.offset_top = 42.0
	add_child(_lbl_monedas)



	_lbl_banner = Estilo.etiqueta("", 44, Estilo.COLOR_BRASA)
	_lbl_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_lbl_banner.offset_top = 110.0
	_lbl_banner.modulate.a = 0.0
	add_child(_lbl_banner)
	_lbl_sub = Estilo.etiqueta("", 22)
	_lbl_sub.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_lbl_sub.offset_top = 170.0
	_lbl_sub.modulate.a = 0.0
	add_child(_lbl_sub)

	_lbl_aviso = Estilo.etiqueta("", 24)
	_lbl_aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_lbl_aviso.offset_top = -150.0
	_lbl_aviso.offset_bottom = -110.0
	_lbl_aviso.modulate.a = 0.0
	add_child(_lbl_aviso)

	_lbl_jefe = Estilo.etiqueta("CRÁNEO GIGANTE", 20, Color(1.0, 0.8, 0.7))
	_lbl_jefe.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_lbl_jefe.offset_top = -78.0
	_lbl_jefe.offset_bottom = -50.0
	_lbl_jefe.visible = false
	add_child(_lbl_jefe)

	Juego.aviso.connect(_mostrar_aviso)
	Juego.banner.connect(_mostrar_banner)


func _process(_delta: float) -> void:
	if not visible:
		return
	_lbl_vidas.text = "Vidas  x%d" % Juego.vidas
	_lbl_puntos.text = "PUNTOS  %06d" % Juego.puntos
	_lbl_monedas.text = "⬡ %d monedas" % Juego.monedas
	var j := _jefe_activo()
	_lbl_jefe.visible = j != null
	_dibujo.queue_redraw()


func _jefe_activo() -> Node:
	var j := get_tree().get_first_node_in_group("jefe")
	if j != null and j.get("muerto") != true and j.get("estado") != null and int(j.estado) != 0:
		return j
	return null


func _dibujar() -> void:
	# Corazones
	for i in Juego.vida_max:
		var c := Vector2(36.0 + i * 36.0, 34.0)
		var pts := PackedVector2Array()
		for p in _forma_corazon:
			pts.append(p + c)
		var lleno := i < Juego.vida
		_dibujo.draw_colored_polygon(pts, Color(0.88, 0.1, 0.14) if lleno else Color(0.12, 0.05, 0.06, 0.85))
		var borde := pts.duplicate()
		borde.append(pts[0])
		_dibujo.draw_polyline(borde, Color(0.05, 0.0, 0.0) if lleno else Color(0.45, 0.15, 0.15), 2.5)
		if lleno:
			_dibujo.draw_circle(c + Vector2(-6.0, -5.0), 3.0, Color(1.0, 0.7, 0.7, 0.8))
	# Barra del jefe
	var j := _jefe_activo()
	if j != null:
		var ancho := 520.0
		var x := (_dibujo.size.x - ancho) * 0.5
		var y := _dibujo.size.y - 44.0
		var frac := clampf(float(j.vida) / float(j.vida_maxima), 0.0, 1.0)
		_dibujo.draw_rect(Rect2(x - 3, y - 3, ancho + 6, 22), Color(0, 0, 0, 0.85))
		_dibujo.draw_rect(Rect2(x, y, ancho, 16), Color(0.2, 0.04, 0.04))
		_dibujo.draw_rect(Rect2(x, y, ancho * frac, 16), Color(0.85, 0.15, 0.1))
		_dibujo.draw_rect(Rect2(x, y, ancho * frac, 5), Color(1.0, 0.5, 0.35))


func _mostrar_banner(titulo: String, sub: String) -> void:
	_lbl_banner.text = titulo
	_lbl_sub.text = sub
	if _tw_banner != null:
		_tw_banner.kill()
	_tw_banner = create_tween()
	_tw_banner.set_parallel(true)
	_tw_banner.tween_property(_lbl_banner, "modulate:a", 1.0, 0.5)
	_tw_banner.tween_property(_lbl_sub, "modulate:a", 1.0, 0.5)
	_tw_banner.chain().tween_interval(2.2)
	_tw_banner.chain().set_parallel(true)
	_tw_banner.tween_property(_lbl_banner, "modulate:a", 0.0, 1.0)
	_tw_banner.tween_property(_lbl_sub, "modulate:a", 0.0, 1.0)


func _mostrar_aviso(texto: String) -> void:
	_lbl_aviso.text = texto
	if _tw_aviso != null:
		_tw_aviso.kill()
	_tw_aviso = create_tween()
	_tw_aviso.tween_property(_lbl_aviso, "modulate:a", 1.0, 0.2)
	_tw_aviso.tween_interval(2.6)
	_tw_aviso.tween_property(_lbl_aviso, "modulate:a", 0.0, 0.8)
