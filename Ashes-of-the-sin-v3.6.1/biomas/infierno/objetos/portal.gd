extends Area2D
## Portal de fuego: lleva al jugador a otra escena (siguiente mapa, subnivel oculto o zona oculta).
## Fuego rojo = salida normal. Fuego azul = portal secreto.
## Un portal sin destino es la salida final: se abre al derrotar al Cráneo Gigante.

signal jugador_entro(destino: String)

@export_file("*.tscn") var escena_destino: String = ""
@export var es_secreto: bool = false

var _usado: bool = false


func _ready() -> void:
	var anim := &"secreto" if es_secreto else &"normal"
	$Llama.play(anim)
	$Brillo.play(anim)
	body_entered.connect(_intentar)


# Revisa cada frame por si el jugador esperaba dentro con el portal sellado.
func _physics_process(_delta: float) -> void:
	if _usado:
		return
	for body in get_overlapping_bodies():
		_intentar(body)


func _intentar(body: Node2D) -> void:
	if _usado or not body.is_in_group("player"):
		return
	if body.get("muerto") == true:
		return
	if escena_destino.is_empty() and Juego.jefe_vivo():
		Juego.aviso_portal_bloqueado()
		return
	_usado = true
	jugador_entro.emit(escena_destino)
	Juego.usar_portal(escena_destino, es_secreto)
