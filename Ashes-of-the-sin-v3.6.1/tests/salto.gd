extends SceneTree
func _initialize() -> void:
	_c.call_deferred()
func _c() -> void:
	var J = root.get_node("Juego")
	await process_frame
	J.ir_a("res://niveles/nivel_1/mapa_1.tscn")
	for i in 60: await process_frame
	var pl = J.jugador
	for x0 in [1226, 1236, 1244]:
		pl.global_position = Vector2(x0, 511); pl.velocity = Vector2.ZERO
		for i in 20: await physics_frame
		Input.action_press("derecha")
		for i in 8: await physics_frame
		Input.action_press("saltar")
		var t := 0
		while t < 120 and not (pl.is_on_floor() and t > 5):
			t += 1
			await physics_frame
			if t == 20: Input.action_release("saltar")
		Input.action_release("derecha"); Input.action_release("saltar")
		print("SALTO desde ", x0, " aterriza x=", int(pl.global_position.x), " y=", int(pl.global_position.y), " t=", t)
		pl.global_position = Vector2(300, 543); 
		for i in 30: await physics_frame
	quit(0)
