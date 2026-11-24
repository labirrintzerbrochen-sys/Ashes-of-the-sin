extends SceneTree
func _initialize() -> void:
	_c.call_deferred()
func g(n: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/1e041b44-aa78-5be0-bf2c-2eaf575db43a/scratchpad/%s.png" % n)
func f(n: int) -> void:
	for i in n: await process_frame
func _c() -> void:
	var J = root.get_node("Juego")
	await f(5)
	J.ir_a("res://niveles/nivel_1/mapa_1.tscn")
	await f(100)
	await g("h_idle")
	Input.action_press("derecha"); await f(25); await g("h_run")
	Input.action_press("saltar"); await f(8); await g("h_jump")
	Input.action_release("saltar"); Input.action_release("derecha"); await f(60)
	Input.action_press("atacar"); await f(8); await g("h_attack")
	Input.action_release("atacar"); await f(30)
	J.jugador.die(); await f(24); await g("h_death")
	quit(0)
