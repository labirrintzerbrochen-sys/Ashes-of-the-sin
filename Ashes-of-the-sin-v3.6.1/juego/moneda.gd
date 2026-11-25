extends Area2D
## Moneda coleccionable. Usa sprites propios en res://juego/sprites/

const VALOR_BASE := 25

var _t: float = 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	# Colisión
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	add_child(cs)
	# Sprite animado
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("girar")
	frames.set_animation_speed("girar", 12.0)
	frames.set_animation_loop("girar", true)
	for i in range(1, 7):
		var tex := load("res://juego/sprites/moneda_frame_%02d.png" % i)
		frames.add_frame("girar", tex)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.play("girar")
	_sprite.scale = Vector2(1.5, 1.5)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(18.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 4.5) * 5.0 - 8.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Juego.sumar_monedas(VALOR_BASE)
	Juego.sfx("recoger")
	queue_free()
