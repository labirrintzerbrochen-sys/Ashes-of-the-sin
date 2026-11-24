extends Node
## Autoload "Juego": estado de la partida, flujo de niveles, vidas, guardado, audio y transiciones.
##
## Flujo: menú -> historia -> nivel_1/mapa_1 -> ... -> nivel_4/mapa_3 (jefe) -> final.
## Cada mapa es una escena con obtener_spawn(); aquí se instancia al jugador y se prepara la cámara.

signal vida_cambiada
signal vidas_cambiadas
signal puntos_cambiados
signal aviso(texto: String)
signal banner(titulo: String, subtitulo: String)

const ESCENA_MENU := "res://juego/menu_principal.tscn"
const ESCENA_TEXTO := "res://juego/pantalla_texto.tscn"
const PRIMER_MAPA := "res://niveles/nivel_1/mapa_1.tscn"
const MAPA_FINAL := "res://niveles/nivel_4/mapa_3.tscn"
const ESCENA_JUGADOR := preload("res://juego/jugador.tscn")
const ESCENA_CORAZON := preload("res://juego/corazon.gd")
const ESCENA_RELIQUIA := preload("res://juego/reliquia.gd")
const GUARDADO := "user://guardado.cfg"

const VIDA_INICIAL := 5
const VIDAS_INICIALES := 3
const PUNTOS_VIDA_EXTRA := 5000
const PROB_CORAZON := 0.22

const NOMBRES_NIVEL := {
	1: "Cavernas de Ceniza", 2: "Ríos de Lava", 3: "Torres Carmesí", 4: "Fortaleza del Pecado",
}

var vida_max: int = VIDA_INICIAL
var vida: int = VIDA_INICIAL
var vidas: int = VIDAS_INICIALES
var puntos: int = 0
var enemigos_derrotados: int = 0
var reliquias: Dictionary = {}  # nivel -> true
var mapa_actual: String = ""
var jugador: Jugador = null
var en_partida: bool = false
var transicionando: bool = false
var pantalla: Dictionary = {}  # datos para pantalla_texto

var _siguiente_vida_extra: int = PUNTOS_VIDA_EXTRA
var _fundido: ColorRect
var _hud: CanvasLayer
var _panel_layer: CanvasLayer
var _panel: Control = null
var _musica: AudioStreamPlayer
var _musica_actual: String = ""
var _pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _congelando: int = 0
var _ultimo_aviso_bloqueo: float = -10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_registrar_controles()
	var capa := CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	_fundido = ColorRect.new()
	_fundido.color = Color(0, 0, 0, 0)
	_fundido.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_fundido)
	_hud = preload("res://juego/hud.gd").new()
	_hud.visible = false
	add_child(_hud)
	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = 50
	add_child(_panel_layer)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -9.0
	add_child(_musica)
	get_tree().node_added.connect(_on_nodo_agregado)


# ----------------------------------------------------------------- Controles

func _registrar_controles() -> void:
	_accion("izquierda", [KEY_A, KEY_LEFT], [], [JOY_AXIS_LEFT_X, -1.0], [JOY_BUTTON_DPAD_LEFT])
	_accion("derecha", [KEY_D, KEY_RIGHT], [], [JOY_AXIS_LEFT_X, 1.0], [JOY_BUTTON_DPAD_RIGHT])
	_accion("saltar", [KEY_SPACE, KEY_W, KEY_UP], [], [], [JOY_BUTTON_A])
	_accion("atacar", [KEY_J, KEY_X], [MOUSE_BUTTON_LEFT], [], [JOY_BUTTON_X])
	_accion("esquivar", [KEY_K, KEY_SHIFT, KEY_C], [MOUSE_BUTTON_RIGHT], [], [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER])
	_accion("pausa", [KEY_ESCAPE, KEY_P], [], [], [JOY_BUTTON_START])


func _accion(nombre: StringName, teclas: Array, ratones: Array, eje: Array, botones: Array) -> void:
	if not InputMap.has_action(nombre):
		InputMap.add_action(nombre, 0.3)
	for k in teclas:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(nombre, e)
	for m in ratones:
		var e := InputEventMouseButton.new()
		e.button_index = m
		InputMap.action_add_event(nombre, e)
	if eje.size() == 2:
		var e := InputEventJoypadMotion.new()
		e.axis = eje[0]
		e.axis_value = eje[1]
		InputMap.action_add_event(nombre, e)
	for b in botones:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(nombre, e)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa") and en_partida and not transicionando:
		if _panel == null:
			pausar()
		elif get_tree().paused and _panel.has_meta("es_pausa"):
			reanudar()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- Audio

func sfx(nombre: String, volumen_db: float = 0.0, tono: float = 1.0) -> void:
	var s := _cargar_audio(nombre)
	if s == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = volumen_db
			p.pitch_scale = tono
			p.play()
			return


func _cargar_audio(nombre: String) -> AudioStream:
	if not _cache.has(nombre):
		var ruta := "res://audio/%s.wav" % nombre
		_cache[nombre] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[nombre]


func musica(nombre: String) -> void:
	if nombre == _musica_actual:
		return
	_musica_actual = nombre
	if nombre == "":
		_musica.stop()
		return
	var s := _cargar_audio(nombre)
	if s == null:
		return
	_musica.stream = s
	_musica.volume_db = -30.0
	_musica.play()
	create_tween().tween_property(_musica, "volume_db", -9.0, 1.2)


## Pausa muy breve al golpear (sensación de impacto).
func congelar(duracion: float) -> void:
	_congelando += 1
	Engine.time_scale = 0.05
	await get_tree().create_timer(duracion, true, false, true).timeout
	_congelando -= 1
	if _congelando <= 0:
		Engine.time_scale = 1.0


# ----------------------------------------------------------------- Estado del jugador

func herir(cantidad: int) -> bool:
	vida = maxi(vida - cantidad, 0)
	vida_cambiada.emit()
	return vida > 0


func curar(cantidad: int) -> void:
	vida = mini(vida + cantidad, vida_max)
	vida_cambiada.emit()


func matar() -> void:
	vida = 0
	vida_cambiada.emit()


func sumar_puntos(n: int) -> void:
	puntos += n
	puntos_cambiados.emit()
	while puntos >= _siguiente_vida_extra:
		_siguiente_vida_extra += PUNTOS_VIDA_EXTRA
		vidas += 1
		vidas_cambiadas.emit()
		aviso.emit("¡Vida extra!")
		sfx("reliquia")


func recoger_reliquia() -> void:
	var nivel := _nivel_actual()
	reliquias[nivel] = true
	vida_max += 1
	vida = vida_max
	vida_cambiada.emit()
	sumar_puntos(1000)
	sfx("reliquia")
	aviso.emit("Reliquia del Pecador: +1 corazón máximo")
	_guardar()


func jefe_vivo() -> bool:
	for j in get_tree().get_nodes_in_group("jefe_final"):
		if is_instance_valid(j) and j.get("muerto") != true:
			return true
	return false


func _nivel_actual() -> int:
	var mapa := get_tree().current_scene
	if mapa != null and mapa.get("nivel") != null:
		return mapa.nivel
	return 1


# ----------------------------------------------------------------- Enemigos y puntuación

func _on_nodo_agregado(nodo: Node) -> void:
	if nodo is EnemigoBase:
		nodo.murio.connect(_on_enemigo_murio)


func _on_enemigo_murio(enemigo: Node) -> void:
	if not en_partida:
		return
	enemigos_derrotados += 1
	var es_jefe := enemigo.is_in_group("jefe")
	sumar_puntos(int(enemigo.vida_maxima) * (100 if not es_jefe else 70))
	if es_jefe:
		sfx("jefe_muere")
		musica("musica_ambiente")
		if enemigo.is_in_group("jefe_final"):
			aviso.emit("El Cráneo Gigante cae. El portal de salida está libre.")
		else:
			aviso.emit("Guardián derrotado")
		curar(vida_max)
		return
	if randf() < PROB_CORAZON and is_instance_valid(enemigo) and enemigo.get_parent() != null:
		var c := Area2D.new()
		c.set_script(ESCENA_CORAZON)
		c.global_position = enemigo.global_position
		enemigo.get_parent().add_child.call_deferred(c)


# ----------------------------------------------------------------- Flujo de partida

func nueva_partida() -> void:
	vida_max = VIDA_INICIAL
	vida = vida_max
	vidas = VIDAS_INICIALES
	puntos = 0
	enemigos_derrotados = 0
	reliquias = {}
	_siguiente_vida_extra = PUNTOS_VIDA_EXTRA
	mapa_actual = PRIMER_MAPA
	_guardar()
	mostrar_pantalla("LA CAÍDA",
		"Un pecado sin nombre te arrastró hasta las Cavernas de Ceniza.\n\n" +
		"Dicen que en la Fortaleza del Pecado, un Cráneo Gigante custodia la única puerta que lleva de vuelta a la luz.\n\n" +
		"Empuña tu espada, Caballero. Cruza cuatro círculos del infierno… o conviértete en una ceniza más.",
		"empezar")


func hay_guardado() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(GUARDADO) == OK and cfg.has_section_key("partida", "mapa")


func continuar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GUARDADO) != OK:
		nueva_partida()
		return
	vida_max = cfg.get_value("partida", "vida_max", VIDA_INICIAL)
	vida = vida_max
	vidas = maxi(cfg.get_value("partida", "vidas", VIDAS_INICIALES), 2)
	puntos = cfg.get_value("partida", "puntos", 0)
	enemigos_derrotados = cfg.get_value("partida", "derrotados", 0)
	reliquias = cfg.get_value("partida", "reliquias", {})
	_siguiente_vida_extra = (puntos / PUNTOS_VIDA_EXTRA + 1) * PUNTOS_VIDA_EXTRA
	mapa_actual = cfg.get_value("partida", "mapa", PRIMER_MAPA)
	ir_a(mapa_actual)


func _guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partida", "mapa", mapa_actual)
	cfg.set_value("partida", "vida_max", vida_max)
	cfg.set_value("partida", "vidas", vidas)
	cfg.set_value("partida", "puntos", puntos)
	cfg.set_value("partida", "derrotados", enemigos_derrotados)
	cfg.set_value("partida", "reliquias", reliquias)
	cfg.save(GUARDADO)


func _borrar_guardado() -> void:
	if FileAccess.file_exists(GUARDADO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARDADO))


func mostrar_pantalla(titulo: String, texto: String, accion: String) -> void:
	pantalla = {"titulo": titulo, "texto": texto, "accion": accion}
	en_partida = false
	_hud.visible = false
	await _fundir(1.0)
	get_tree().change_scene_to_file(ESCENA_TEXTO)
	await get_tree().process_frame
	await _fundir(0.0)


func empezar_nivel() -> void:
	ir_a(mapa_actual if mapa_actual != "" else PRIMER_MAPA)


func al_menu() -> void:
	cerrar_panel()
	get_tree().paused = false
	en_partida = false
	_hud.visible = false
	musica("musica_menu")
	await _fundir(1.0)
	get_tree().change_scene_to_file(ESCENA_MENU)
	await get_tree().process_frame
	await _fundir(0.0)
	transicionando = false


func _fundir(alfa: float, duracion: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fundido, "color:a", alfa, duracion)
	await tw.finished


func ir_a(ruta: String) -> void:
	if transicionando:
		return
	transicionando = true
	cerrar_panel()
	get_tree().paused = false
	await _fundir(1.0)
	mapa_actual = ruta
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	_preparar_mapa()
	await _fundir(0.0)
	transicionando = false


func _preparar_mapa() -> void:
	var mapa := get_tree().current_scene
	if mapa == null or not mapa.has_method("obtener_spawn"):
		return
	en_partida = true
	vida = vida_max
	vida_cambiada.emit()
	vidas_cambiadas.emit()
	puntos_cambiados.emit()
	jugador = ESCENA_JUGADOR.instantiate() as Jugador
	mapa.add_child(jugador)
	jugador.global_position = mapa.obtener_spawn() + Vector2(0.0, -1.0)
	var previa := mapa.get_node_or_null("CamaraPrevia") as Camera2D
	if previa != null:
		jugador.configurar_limites(previa.limit_left, previa.limit_top, previa.limit_right, previa.limit_bottom)
		previa.enabled = false
		previa.set_process(false)
		previa.set_process_unhandled_input(false)
	jugador.camara.make_current()
	jugador.camara.reset_smoothing()

	# Reliquia de la zona oculta (una por nivel)
	for marcador in get_tree().get_nodes_in_group("recompensa"):
		if not reliquias.get(mapa.nivel, false):
			var r := Area2D.new()
			r.set_script(ESCENA_RELIQUIA)
			marcador.get_parent().add_child(r)
			r.global_position = marcador.global_position

	# Jefes: el Cráneo Gigante
	for e in get_tree().get_nodes_in_group("enemigos"):
		if str(e.scene_file_path).ends_with("craneo_gigante.tscn"):
			e.add_to_group("jefe")
			if mapa_actual == MAPA_FINAL:
				e.add_to_group("jefe_final")

	_hud.visible = true
	_guardar()
	musica("musica_ambiente")
	_anunciar_mapa(mapa)


func _anunciar_mapa(mapa: Node) -> void:
	var nivel: int = mapa.nivel
	var nombre := str(NOMBRES_NIVEL.get(nivel, ""))
	var es_oculto: bool = mapa.es_oculto
	if es_oculto:
		banner.emit("Zona secreta", nombre)
	else:
		var n := str(mapa.nombre_mapa)
		var num := n.substr(n.length() - 1)
		banner.emit("Nivel %d — %s" % [nivel, nombre], "Mapa %s de 3" % num)


func _process(_delta: float) -> void:
	# Música del jefe cuando despierta.
	if not en_partida:
		return
	var j := get_tree().get_first_node_in_group("jefe")
	if j != null and j.get("muerto") != true and j.get("estado") != null and int(j.estado) != 0:
		musica("musica_jefe")


func jugador_murio() -> void:
	if transicionando or not en_partida:
		return
	vidas -= 1
	vidas_cambiadas.emit()
	if vidas <= 0:
		_game_over()
	else:
		ir_a(mapa_actual)


func _game_over() -> void:
	en_partida = false
	musica("")
	var nivel := _nivel_actual()
	var primer_mapa_nivel := "res://niveles/nivel_%d/mapa_1.tscn" % nivel
	_mostrar_panel("HAS CAÍDO", "Puntos: %d" % puntos, [
		["Reintentar el nivel", func() -> void:
			vidas = VIDAS_INICIALES
			puntos = maxi(0, puntos - 500)
			en_partida = true
			ir_a(primer_mapa_nivel)],
		["Menú principal", al_menu],
	], Estilo.COLOR_SANGRE)


func usar_portal(destino: String, _secreto: bool) -> void:
	sfx("portal")
	if destino.is_empty():
		victoria()
	else:
		ir_a(destino)


func aviso_portal_bloqueado() -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - _ultimo_aviso_bloqueo < 3.0:
		return
	_ultimo_aviso_bloqueo = ahora
	aviso.emit("El portal está sellado: derrota al Cráneo Gigante")


func victoria() -> void:
	en_partida = false
	_borrar_guardado()
	musica("")
	sfx("victoria")
	mostrar_pantalla("LA LUZ",
		"El Cráneo Gigante se deshace en cenizas y el portal se abre ante ti.\n\n" +
		"El Caballero cruza el umbral. Atrás queda el infierno… pero las cenizas siempre recuerdan.\n\n" +
		"Puntos: %d     Enemigos derrotados: %d     Reliquias: %d de 4" % [puntos, enemigos_derrotados, reliquias.size()],
		"menu")


# ----------------------------------------------------------------- Pausa y paneles

func pausar() -> void:
	get_tree().paused = true
	_mostrar_panel("PAUSA", "ESC para continuar", [
		["Continuar", reanudar],
		["Reiniciar mapa", func() -> void: ir_a(mapa_actual)],
		["Menú principal", al_menu],
	])
	_panel.set_meta("es_pausa", true)


func reanudar() -> void:
	cerrar_panel()
	get_tree().paused = false


func _mostrar_panel(titulo: String, subtitulo: String, botones: Array, color: Color = Estilo.COLOR_BRASA) -> void:
	cerrar_panel()
	var p := PanelMenu.new()
	p.configurar(titulo, subtitulo, botones, color)
	_panel_layer.add_child(p)
	_panel = p


func cerrar_panel() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
