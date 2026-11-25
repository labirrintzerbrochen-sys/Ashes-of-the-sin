extends Area2D
## Powerup: tres tipos — velocidad, fuerza, escudo.
## Se sueltan de cofres o de enemigos especiales.

## Tipo asignado antes de add_child: set_meta("tipo", "velocidad"|"fuerza"|"escudo")
var tipo: String = "velocidad"
var _t: float = randf() * TAU
var _duracion := 12.0  # segundos de efecto al recoger


func _ready() -> void:
	# Leer tipo desde meta si fue asignado por el cofre
	if has_meta("tipo"):
		tipo = str(get_meta("tipo"))
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 16.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(20.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 3.0) * 7.0 - 18.0
	draw_set_transform(Vector2(0.0, y), 0.0, Vector2.ONE)
	var col := _color_tipo()
	draw_circle(Vector2.ZERO, 18.0, Color(col.r, col.g, col.b, 0.25))
	draw_circle(Vector2.ZERO, 13.0, col)
	# Icono según tipo
	match tipo:
		"velocidad":
			# Rayo
			var rayo := PackedVector2Array([
				Vector2(3,-9), Vector2(-2,-1), Vector2(2,-1), Vector2(-3,9), Vector2(5,0), Vector2(1,0)
			])
			draw_colored_polygon(rayo, Color.WHITE)
		"fuerza":
			# Espada vertical
			draw_rect(Rect2(-2.0, -9.0, 4.0, 14.0), Color.WHITE)
			draw_rect(Rect2(-6.0, 2.0, 12.0, 3.0), Color.WHITE)
			draw_rect(Rect2(-2.0, 5.0, 4.0, 4.0), Color(0.9, 0.8, 0.6))
		"escudo":
			# Escudo
			var escudo := PackedVector2Array([
				Vector2(0,-9), Vector2(8,-5), Vector2(8,2), Vector2(0,9), Vector2(-8,2), Vector2(-8,-5)
			])
			draw_colored_polygon(escudo, Color(0.9, 0.9, 1.0, 0.9))
			draw_polyline(escudo + PackedVector2Array([escudo[0]]), Color.WHITE, 2.0)
	draw_circle(Vector2.ZERO, 13.0, col.darkened(0.1) if true else col, false, 2.5)


func _color_tipo() -> Color:
	match tipo:
		"velocidad": return Color(0.2, 0.8, 1.0)
		"fuerza":    return Color(1.0, 0.3, 0.1)
		"escudo":    return Color(0.5, 0.9, 0.5)
	return Color.WHITE


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Juego.activar_powerup(tipo, _duracion)
	Juego.sfx("reliquia")
	queue_free()
