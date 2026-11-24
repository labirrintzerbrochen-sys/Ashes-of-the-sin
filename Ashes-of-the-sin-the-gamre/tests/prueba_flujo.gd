extends SceneTree
## Prueba automática: recorre los 20 mapas, mueve al jugador, lo daña y lo mata.
## Uso: godot --headless --fixed-fps 60 -s tests/prueba_flujo.gd

var errores := 0

func chk(c: bool, msg: String) -> void:
	if c:
		print("  OK   ", msg)
	else:
		print("  FAIL ", msg)
		errores += 1

func frames(n: int) -> void:
	for i in n:
		await process_frame

func _initialize() -> void:
	_correr.call_deferred()

func _correr() -> void:
	var J = root.get_node("Juego")
	await frames(5)
	var mapas: Array = []
	for n in range(1, 5):
		for m in ["mapa_1", "mapa_2", "mapa_3", "subnivel_oculto", "zona_oculta"]:
			mapas.append("res://niveles/nivel_%d/%s.tscn" % [n, m])
	J.vida_max = 5
	for ruta in mapas:
		J.ir_a(ruta)
		await frames(60)
		var pl = J.jugador
		chk(is_instance_valid(pl) and J.en_partida, "carga " + ruta.trim_prefix("res://niveles/"))
		if not is_instance_valid(pl):
			continue
		var y0: float = pl.global_position.y
		await frames(40)
		chk(pl.is_on_floor(), "  aterriza en el suelo (y=%d)" % pl.global_position.y)
	# Movimiento y ataque
	J.ir_a(mapas[0])
	await frames(60)
	var pl = J.jugador
	var x0: float = pl.global_position.x
	Input.action_press("derecha")
	await frames(60)
	Input.action_release("derecha")
	chk(pl.global_position.x > x0 + 100.0, "camina a la derecha (%d px)" % (pl.global_position.x - x0))
	Input.action_press("saltar")
	await frames(6)
	chk(pl.velocity.y < 0.0 or not pl.is_on_floor(), "salta")
	Input.action_release("saltar")
	await frames(60)
	Input.action_press("atacar")
	await frames(2)
	Input.action_release("atacar")
	await frames(30)
	Input.action_press("esquivar")
	await frames(2)
	Input.action_release("esquivar")
	await frames(30)
	# Daño
	var v0: int = J.vida
	pl.take_damage(1)
	chk(J.vida == v0 - 1, "recibe daño")
	pl.take_damage(1)
	chk(J.vida == v0 - 1, "invulnerable tras el golpe")
	# Muerte -> respawn con una vida menos
	var vidas0: int = J.vidas
	pl.die()
	await frames(150)
	chk(J.vidas == vidas0 - 1, "pierde una vida al morir")
	chk(is_instance_valid(J.jugador) and J.jugador != pl and not J.jugador.muerto, "reaparece")
	# Combate real: enemigo delante
	var enem = load("res://biomas/infierno/enemigos/murcielago.tscn").instantiate()
	current_scene.add_child(enem)
	enem.global_position = J.jugador.global_position + Vector2(50, -30)
	await frames(3)
	var pts0: int = J.puntos
	J.jugador.dir_cara = 1.0
	for i in 6:
		Input.action_press("atacar")
		await frames(2)
		Input.action_release("atacar")
		await frames(25)
	chk(not is_instance_valid(enem) or enem.muerto, "la espada derrota al murciélago")
	chk(J.puntos > pts0, "suma puntos (%d)" % (J.puntos - pts0))
	# Game over
	J.vidas = 1
	J.jugador.die()
	await frames(150)
	chk(not J.en_partida, "game over al quedarse sin vidas")
	# Portal final bloqueado/abierto
	J.vidas = 3
	J.ir_a("res://niveles/nivel_4/mapa_3.tscn")
	await frames(60)
	chk(J.jefe_vivo(), "jefe final presente")
	J.ir_a("res://niveles/nivel_1/zona_oculta.tscn")
	await frames(60)
	chk(get_nodes_in_group("recompensa").size() > 0 and current_scene.find_children("*", "Area2D", true, false).any(func(n): return n.get_script() != null and str(n.get_script().resource_path).ends_with("reliquia.gd")), "reliquia aparece en zona oculta")
	print("ERRORES: ", errores)
	quit(errores)
