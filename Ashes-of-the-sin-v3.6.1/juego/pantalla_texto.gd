extends Control
## Pantalla de texto con efecto de máquina de escribir (historia inicial y final).
## Lee Juego.pantalla = {titulo, texto, accion}. accion: "empezar" o "menu".

var _cuerpo: Label
var _pista: Label
var _tw: Tween
var _listo: bool = false
var _t: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var d: Dictionary = Juego.pantalla
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.01, 0.01)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	add_child(Estilo.brasas(1152.0, 648.0))
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 26)
	caja.custom_minimum_size = Vector2(760, 0)
	centro.add_child(caja)
	caja.add_child(Estilo.etiqueta(str(d.get("titulo", "")), 56, Estilo.COLOR_BRASA))
	_cuerpo = Estilo.etiqueta(str(d.get("texto", "")), 24)
	_cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cuerpo.custom_minimum_size = Vector2(760, 0)
	_cuerpo.visible_ratio = 0.0
	caja.add_child(_cuerpo)
	_pista = Estilo.etiqueta("Pulsa Enter, Espacio o clic para continuar", 18, Color(0.7, 0.6, 0.55))
	_pista.modulate.a = 0.0
	caja.add_child(_pista)
	var n := _cuerpo.text.length()
	_tw = create_tween()
	_tw.tween_property(_cuerpo, "visible_ratio", 1.0, n * 0.03)
	_tw.tween_callback(_terminar)


func _terminar() -> void:
	_listo = true
	_cuerpo.visible_ratio = 1.0


func _process(delta: float) -> void:
	if _listo:
		_t += delta
		_pista.modulate.a = 0.5 + 0.5 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	var pulsado: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("saltar") \
		or (event is InputEventMouseButton and event.pressed)
	if not pulsado:
		return
	get_viewport().set_input_as_handled()
	if not _listo:
		_tw.kill()
		_terminar()
		return
	set_process_unhandled_input(false)
	Juego.sfx("menu")
	if Juego.pantalla.get("accion", "menu") == "empezar":
		Juego.empezar_nivel()
	else:
		Juego.al_menu()
