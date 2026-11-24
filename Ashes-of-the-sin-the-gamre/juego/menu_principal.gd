extends Control
## Menú principal: fondo del infierno con parallax, brasas y botones.

var _capas: Array[TextureRect] = []
var _velocidades: Array[float] = [4.0, 8.0, 14.0]
var _controles: Control
var _t: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Juego.musica("musica_menu")
	var rutas := [
		"res://biomas/infierno/texturas/fondo_cielo.png",
		"res://biomas/infierno/texturas/fondo_montanas_lejanas.png",
		"res://biomas/infierno/texturas/fondo_montanas.png",
		"res://biomas/infierno/texturas/fondo_rocas.png",
	]
	for r in rutas:
		var tr := TextureRect.new()
		tr.texture = load(r)
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = -80.0
		tr.offset_right = 80.0
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		_capas.append(tr)
	var sombra := ColorRect.new()
	sombra.color = Color(0.03, 0.0, 0.0, 0.45)
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	add_child(Estilo.brasas(1152.0, 648.0))

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	centro.add_child(caja)
	var titulo := Estilo.etiqueta("ASHES OF THE SIN", 76, Estilo.COLOR_BRASA)
	titulo.add_theme_constant_override("outline_size", 14)
	caja.add_child(titulo)
	caja.add_child(Estilo.etiqueta("El pecado solo deja cenizas", 24, Color(0.85, 0.7, 0.6)))
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 26)
	caja.add_child(sep)

	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(botones)
	var primero: Button = null
	if Juego.hay_guardado():
		var b := Estilo.boton("Continuar")
		b.pressed.connect(func() -> void: Juego.sfx("menu"); Juego.continuar())
		botones.add_child(b)
		primero = b
	var nueva := Estilo.boton("Nueva partida")
	nueva.pressed.connect(func() -> void: Juego.sfx("menu"); Juego.nueva_partida())
	botones.add_child(nueva)
	var ctrl := Estilo.boton("Controles")
	ctrl.pressed.connect(func() -> void: Juego.sfx("menu"); _controles.visible = not _controles.visible)
	botones.add_child(ctrl)
	if OS.get_name() != "Web":
		var salir := Estilo.boton("Salir")
		salir.pressed.connect(func() -> void: get_tree().quit())
		botones.add_child(salir)
	for b in botones.get_children():
		(b as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if primero == null:
		primero = nueva
	primero.grab_focus.call_deferred()

	_controles = Estilo.etiqueta(
		"MOVER: A/D o flechas     SALTAR: Espacio / W / ↑\n" +
		"ATACAR: J / X / clic izq.     ESQUIVAR: K / Shift / clic der.\n" +
		"PAUSA: Esc / P        Mando: A salta, X ataca, B esquiva, Start pausa\n\n" +
		"Pisa a las cabezas de demonio para aplastarlas.\n" +
		"Busca muros falsos: caminan hacia secretos y reliquias.", 18)
	_controles.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_controles.offset_top = -150.0
	_controles.offset_bottom = -12.0
	_controles.visible = false
	add_child(_controles)


func _process(delta: float) -> void:
	_t += delta
	for i in _capas.size() - 1:
		_capas[i + 1].position.x = sin(_t * 0.1 + i) * _velocidades[mini(i, 2)] * 3.0
