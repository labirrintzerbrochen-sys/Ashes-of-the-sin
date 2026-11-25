extends Area2D
## Cofre: objeto estático en el nivel. Al tocarlo suelta monedas.
## Coloca marcadores con grupo "cofre" en las escenas de mapa.

const MONEDAS_BASE := 5
const MONEDAS_EXTRA := 5

var _abierto: bool = false
var _sprite: Sprite2D
var _tex_cerrado: Texture2D
var _tex_abierto: Texture2D
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32.0, 28.0)
	cs.shape = r
	add_child(cs)
	# Cargar texturas
	_tex_cerrado = load("res://juego/sprites/cofre_cerrado.png")
	_tex_abierto  = load("res://juego/sprites/cofre_abierto.png")
	# Sprite
	_sprite = Sprite2D.new()
	_sprite.texture = _tex_cerrado
	_sprite.scale = Vector2(2.0, 2.0)
	_sprite.position = Vector2(0.0, -14.0)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _abierto:
		return
	_t += delta
	# Flotación suave
	_sprite.position.y = -14.0 + sin(_t * 2.5) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if _abierto or not body.is_in_group("player"):
		return
	_abierto = true
	_sprite.texture = _tex_abierto
	_sprite.position.y = -14.0
	Juego.sfx("reliquia")
	var n_monedas := MONEDAS_BASE + randi() % (MONEDAS_EXTRA + 1)
	for i in n_monedas:
		var m := Area2D.new()
		m.set_script(load("res://juego/moneda.gd"))
		m.global_position = global_position + Vector2(randf_range(-40.0, 40.0), -20.0)
		get_parent().add_child.call_deferred(m)
	Juego.aviso.emit("¡Cofre abierto!")
