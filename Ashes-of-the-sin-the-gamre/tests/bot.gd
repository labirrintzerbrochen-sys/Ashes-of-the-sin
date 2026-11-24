extends SceneTree
## Bot: recorre un mapa avanzando, saltando fosos/escalones y atacando. Mide si llega al portal.
## Uso: godot --headless --fixed-fps 60 -s tests/bot.gd -- res://niveles/nivel_1/mapa_1.tscn

func _initialize() -> void:
	_correr.call_deferred()

func _correr() -> void:
	var J = root.get_node("Juego")
	var args := OS.get_cmdline_user_args()
	var ruta: String = args[0] if args.size() > 0 else "res://niveles/nivel_1/mapa_1.tscn"
	await process_frame
	J.vida_max = 50
	J.ir_a(ruta)
	for i in 60:
		await process_frame
	var pl = J.jugador
	var portal_x := 1e9
	for p in get_nodes_in_group("player"): pass
	for n in current_scene.find_children("Portal*", "Area2D", true, false):
		if not n.es_secreto and (n.escena_destino != "" or true):
			portal_x = n.global_position.x
	var meta: String = current_scene.siguiente_escena
	var t := 0
	var atasco := 0
	var xprev: float = pl.global_position.x
	while t < 60 * 90 and J.mapa_actual == ruta and is_instance_valid(pl) and not pl.muerto:
		t += 1
		Input.action_press("derecha")
		# mira adelante: suelo y paredes
		var espacio = pl.get_world_2d().direct_space_state
		var p: Vector2 = pl.global_position
		var pared := _ray(espacio, p + Vector2(0, -20), p + Vector2(14, -20))
		var pared_alta := _ray(espacio, p + Vector2(0, -70), p + Vector2(14, -70))
		var suelo_adelante := _ray(espacio, p + Vector2(4, -4), p + Vector2(4, 90))
		var suelo_lejos := _ray(espacio, p + Vector2(100, -4), p + Vector2(100, 90))
		if pl.is_on_floor():
			if pared or not suelo_adelante:
				Input.action_press("saltar")
			else:
				Input.action_release("saltar")
		else:
			# mantén el salto pulsado mientras sube
			if pl.velocity.y > 0: Input.action_release("saltar")
		# atacar si hay enemigo cerca
		for e in get_nodes_in_group("enemigos"):
			if is_instance_valid(e) and e.get("muerto") != true and absf(e.global_position.x - p.x) < 90 and absf(e.global_position.y - p.y) < 90:
				Input.action_press("atacar")
				break
			else:
				Input.action_release("atacar")
		if t % 30 == 0:
			if absf(pl.global_position.x - xprev) < 5.0:
				atasco += 1
			else:
				atasco = 0
			xprev = pl.global_position.x
		await physics_frame
	Input.action_release("derecha"); Input.action_release("saltar"); Input.action_release("atacar")
	var ok: bool = J.mapa_actual != ruta
	print("RESULTADO ", ruta, " llego_portal=", ok, " muerto=", is_instance_valid(pl) and pl.muerto, " x=", int(pl.global_position.x) if is_instance_valid(pl) else -1, " t=", t / 60.0, "s", " hp=", J.vida)
	quit(0)

func _ray(espacio, a: Vector2, b: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(a, b, 1)
	return not espacio.intersect_ray(q).is_empty()
