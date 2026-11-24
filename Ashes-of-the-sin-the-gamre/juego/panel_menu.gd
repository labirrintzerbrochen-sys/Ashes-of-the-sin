class_name PanelMenu
extends Control
## Panel superpuesto genérico (pausa, game over): título, subtítulo y botones.
## botones = [["Texto", Callable], ...]


func configurar(titulo: String, subtitulo: String, botones: Array, color_titulo: Color = Estilo.COLOR_BRASA) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.0, 0.0, 0.72)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	centro.add_child(caja)
	caja.add_child(Estilo.etiqueta(titulo, 56, color_titulo))
	if subtitulo != "":
		caja.add_child(Estilo.etiqueta(subtitulo, 22))
	caja.add_child(Control.new())
	var primero: Button = null
	for datos in botones:
		var b := Estilo.boton(datos[0])
		b.pressed.connect(datos[1])
		b.pressed.connect(func() -> void: Juego.sfx("menu"))
		caja.add_child(b)
		if primero == null:
			primero = b
	if primero != null:
		primero.grab_focus.call_deferred()
