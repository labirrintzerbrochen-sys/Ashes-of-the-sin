extends Area2D
## Reliquia del Pecador: recompensa de las zonas ocultas. +1 corazón máximo y cura total.

var _t: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 26.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body_entered)
	var luz := CPUParticles2D.new()
	luz.amount = 24
	luz.lifetime = 1.6
	luz.direction = Vector2(0, -1)
	luz.spread = 60.0
	luz.gravity = Vector2.ZERO
	luz.initial_velocity_min = 15.0
	luz.initial_velocity_max = 40.0
	luz.scale_amount_min = 1.5
	luz.scale_amount_max = 3.5
	luz.color = Color(0.6, 0.85, 1.0, 0.9)
	add_child(luz)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 2.2) * 6.0 - 24.0
	var s := 1.0 + sin(_t * 5.0) * 0.07
	var rombo := PackedVector2Array([Vector2(0, -22), Vector2(14, 0), Vector2(0, 22), Vector2(-14, 0)])
	draw_set_transform(Vector2(0.0, y), 0.0, Vector2(s, s))
	draw_circle(Vector2.ZERO, 34.0, Color(0.4, 0.7, 1.0, 0.16))
	draw_circle(Vector2.ZERO, 22.0, Color(0.5, 0.8, 1.0, 0.18))
	draw_colored_polygon(rombo, Color(0.45, 0.8, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -22), Vector2(14, 0), Vector2(0, 0)]), Color(0.8, 0.95, 1.0))
	draw_polyline(rombo + PackedVector2Array([rombo[0]]), Color(0.05, 0.15, 0.35), 2.0)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Juego.recoger_reliquia()
	queue_free()
