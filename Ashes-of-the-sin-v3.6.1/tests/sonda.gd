extends SceneTree
func _initialize() -> void:
	_c.call_deferred()
func _c() -> void:
	var J = root.get_node("Juego")
	await process_frame
	J.ir_a("res://niveles/nivel_1/mapa_1.tscn")
	for i in 40: await process_frame
	var sp = J.jugador.get_world_2d().direct_space_state
	var prev := -1
	var out := []
	for x in range(0, 2800, 8):
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, 300), Vector2(x, 760), 1)
		var r = sp.intersect_ray(q)
		var y: int = int(r.position.y) if not r.is_empty() else -1
		if y != prev:
			out.append("x=%d top=%d" % [x, y]); prev = y
	print("SONDA ", " | ".join(out))
	quit(0)
