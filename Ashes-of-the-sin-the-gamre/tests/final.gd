extends SceneTree
func _initialize() -> void:
	_c.call_deferred()
func f(n: int) -> void:
	for i in n: await process_frame
func _c() -> void:
	var J = root.get_node("Juego")
	await f(5)
	J.ir_a("res://niveles/nivel_4/mapa_3.tscn")
	await f(80)
	var portal
	for n in current_scene.find_children("Portal*", "Area2D", true, false):
		if n.escena_destino == "": portal = n
	J.jugador.global_position = portal.global_position
	await f(30)
	print("T bloqueado: en_partida=", J.en_partida, " mapa=", J.mapa_actual.get_file())
	for e in get_nodes_in_group("jefe_final"): e.take_damage(999)
	await f(10)
	print("T jefe_vivo=", J.jefe_vivo(), " vida=", J.vida)
	J.jugador.global_position = portal.global_position
	await f(120)
	print("T victoria: en_partida=", J.en_partida, " escena=", current_scene.scene_file_path, " guardado=", J.hay_guardado())
	await f(5)
	quit(0)
