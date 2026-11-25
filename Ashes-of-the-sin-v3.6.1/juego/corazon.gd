extends Area2D
## Corazón que sueltan los enemigos: cura 1 de vida (o da puntos si ya está llena).

var _t: float = randf() * 6.0
var _forma: PackedVector2Array


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 18.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body_entered)
	for i in 28:
		var a := TAU * i / 28.0
		_forma.append(Vector2(16.0 * pow(sin(a), 3.0),
			-(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * 0.55)
	# Desaparece tras un rato para no acumularse.
	get_tree().create_timer(14.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 3.0) * 4.0 - 14.0
	draw_set_transform(Vector2(0.0, y), 0.0, Vector2.ONE * (1.0 + sin(_t * 6.0) * 0.06))
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.3, 0.2, 0.18))
	draw_colored_polygon(_forma, Color(0.9, 0.1, 0.15))
	draw_polyline(_forma + PackedVector2Array([_forma[0]]), Color(0.3, 0.0, 0.05), 2.0)
	draw_circle(Vector2(-4.0, -3.0), 2.0, Color(1.0, 0.7, 0.7))


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if Juego.vida < Juego.vida_max:
		Juego.curar(1)
	else:
		Juego.sumar_puntos(50)
	Juego.sfx("recoger")
	queue_free()
