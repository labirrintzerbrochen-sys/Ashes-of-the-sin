extends SceneTree
## Captura imágenes del juego para revisión visual. Requiere renderizado (xvfb).
func _initialize() -> void:
	_c.call_deferred()
func guardar(nombre: String) -> void:
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/tmp/claude-0/-home-claude/1e041b44-aa78-5be0-bf2c-2eaf575db43a/scratchpad/%s.png" % nombre)
func _c() -> void:
	var J = root.get_node("Juego")
	J.al_menu()
	for i in 60: await process_frame
	await guardar("cap_menu")
	J.nueva_partida()
	for i in 150: await process_frame
	await guardar("cap_historia")
	J.transicionando = false
	J.vida_max = 6
	J.ir_a("res://niveles/nivel_1/mapa_1.tscn")
	for i in 90: await process_frame
	Input.action_press("derecha")
	for i in 40: await process_frame
	Input.action_press("atacar")
	for i in 8: await process_frame
	await guardar("cap_juego")
	Input.action_release("atacar"); Input.action_release("derecha")
	J.ir_a("res://niveles/nivel_4/mapa_3.tscn")
	for i in 120: await process_frame
	J.jugador.global_position = Vector2(3300, 500)
	for i in 60: await process_frame
	await guardar("cap_jefe")
	J.pausar()
	for i in 10: await process_frame
	await guardar("cap_pausa")
	quit(0)
