class_name Jugador
extends CharacterBody2D
## Personaje principal: el Caballero. Se mueve, salta, esquiva (dash) y ataca con la espada.
## Convenciones del bioma: grupo "player", capa 2 ("jugador"), máscara 1 ("mundo"),
## expone take_damage(cantidad), die() y velocity.

# --- Movimiento (pensado para que suba 2 tiles y salte fosos de 4) ---
const VEL_MAX := 235.0
const ACEL_SUELO := 2400.0
const ACEL_AIRE := 1500.0
const FRIC_SUELO := 2800.0
const FRIC_AIRE := 700.0
const GRAVEDAD := 1500.0
const GRAV_CAIDA := 1900.0
const VEL_SALTO := -560.0
const VEL_CAIDA_MAX := 720.0
const TIEMPO_COYOTE := 0.1
const TIEMPO_BUFFER := 0.12
# --- Esquiva ---
const VEL_DASH := 560.0
const DURACION_DASH := 0.17
const ENFRIAMIENTO_DASH := 0.55
# --- Ataque ---
const DANO_ATAQUE := 1.0
const DURACION_ATAQUE := 0.30
const ENFRIAMIENTO_ATAQUE := 0.34
const VENTANA_GOLPE := Vector2(0.05, 0.20)
# --- Daño ---
const TIEMPO_INVULNERABLE := 1.2
const TIEMPO_ATURDIDO := 0.25

const ESC := 1.3  # escala del sprite (el personaje mide ~45 px en el dibujo)

var dir_cara: float = 1.0
var muerto: bool = false

var _coyote: float = 0.0
var _buffer_salto: float = 0.0
var _inv: float = 0.0
var _aturdido: float = 0.0
var _dash_t: float = 0.0
var _dash_enfr: float = 0.0
var _dash_dir: float = 1.0
var _fantasma_t: float = 0.0
var _ataque_t: float = -1.0
var _ataque_enfr: float = 0.0
var _golpeados: Array = []
var _estaba_en_suelo: bool = true
var _vel_y_previa: float = 0.0

var sprite: AnimatedSprite2D
var camara: Camera2D
var _hitbox: Area2D
var _corte: Corte


## Efecto visual del tajo de la espada.
class Corte extends Node2D:
	var progreso: float = 1.0:
		set(v):
			progreso = v
			queue_redraw()

	func _draw() -> void:
		if progreso >= 1.0:
			return
		var a := 1.0 - progreso
		var ini := -1.3 + progreso * 0.8
		draw_arc(Vector2.ZERO, 50.0, ini, ini + 1.9, 24, Color(1.0, 0.6, 0.25, a * 0.8), 9.0 * a + 1.0)
		draw_arc(Vector2.ZERO, 44.0, ini + 0.1, ini + 1.8, 24, Color(1.0, 0.95, 0.85, a), 4.0 * a + 1.0)

	func disparar() -> void:
		progreso = 0.0
		create_tween().tween_property(self, "progreso", 1.0, 0.2)


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 8.0
	_crear_sprite()
	_crear_colision()
	_crear_ataque()
	_crear_camara()


func _crear_sprite() -> void:
	# Gothic Hero: cuadros de 160x90, el personaje mira a la derecha y los pies tocan el borde inferior.
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_anim(frames, "idle", "idle", 4, 6.0, true)
	_anim(frames, "correr", "run", 6, 13.0, true)
	_anim(frames, "ataque", "attack", 6, 20.0, false)
	_anim(frames, "herido", "hurt", 1, 5.0, false)
	_anim(frames, "muerte", "Death", 7, 9.0, false)
	frames.add_animation("subir")
	frames.set_animation_speed("subir", 10.0)
	frames.set_animation_loop("subir", false)
	frames.add_animation("caer")
	frames.set_animation_speed("caer", 10.0)
	frames.set_animation_loop("caer", false)
	for i in [1, 2]:
		frames.add_frame("subir", load("res://Personajes/gothic_hero/jump/frame_%02d.png" % i))
	for i in [3, 4]:
		frames.add_frame("caer", load("res://Personajes/gothic_hero/jump/frame_%02d.png" % i))
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(ESC, ESC)
	sprite.position = Vector2(0.0, -45.0 * ESC)  # los pies del dibujo quedan en el origen
	sprite.play("idle")
	add_child(sprite)


func _anim(frames: SpriteFrames, nombre: String, carpeta: String, n: int, fps: float, bucle: bool) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, fps)
	frames.set_animation_loop(nombre, bucle)
	for i in range(1, n + 1):
		frames.add_frame(nombre, load("res://Personajes/gothic_hero/%s/frame_%02d.png" % [carpeta, i]))


func _crear_colision() -> void:
	var cs := CollisionShape2D.new()
	var forma := CapsuleShape2D.new()
	forma.radius = 11.0
	forma.height = 56.0
	cs.shape = forma
	cs.position = Vector2(0.0, -28.0)
	add_child(cs)


func _crear_ataque() -> void:
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 4  # enemigos
	var cs := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(76.0, 60.0)
	cs.shape = forma
	_hitbox.add_child(cs)
	_hitbox.position = Vector2(38.0, -30.0)
	add_child(_hitbox)
	_corte = Corte.new()
	_corte.position = Vector2(0.0, -30.0)
	add_child(_corte)


func _crear_camara() -> void:
	camara = Camera2D.new()
	camara.position = Vector2(0.0, -48.0)
	camara.zoom = Vector2(1.15, 1.15)
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 7.0
	camara.limit_smoothed = true
	add_child(camara)
	camara.make_current()


func configurar_limites(izq: int, arriba: int, der: int, abajo: int) -> void:
	camara.limit_left = izq
	camara.limit_top = arriba
	camara.limit_right = der
	camara.limit_bottom = abajo


func _physics_process(delta: float) -> void:
	if muerto:
		velocity.y = minf(velocity.y + GRAVEDAD * delta, VEL_CAIDA_MAX)
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		return

	_temporizadores(delta)
	var en_suelo := is_on_floor()
	var eje := 0.0 if _aturdido > 0.0 else Input.get_axis("izquierda", "derecha")
	if eje != 0.0 and _ataque_t < 0.0 and _dash_t <= 0.0:
		dir_cara = signf(eje)

	# Esquiva
	if Input.is_action_just_pressed("esquivar") and _dash_enfr <= 0.0 and _aturdido <= 0.0:
		_iniciar_esquiva()

	if _dash_t > 0.0:
		velocity = Vector2(_dash_dir * VEL_DASH, 0.0)
		_fantasma_t -= delta
		if _fantasma_t <= 0.0:
			_fantasma_t = 0.04
			_crear_fantasma()
	else:
		if not en_suelo:
			var g := GRAV_CAIDA if velocity.y > 0.0 else GRAVEDAD
			velocity.y = minf(velocity.y + g * delta, VEL_CAIDA_MAX)
		var vmax := VEL_MAX * (0.55 if (_ataque_t >= 0.0 and en_suelo) else 1.0)
		if eje != 0.0:
			var acel := ACEL_SUELO if en_suelo else ACEL_AIRE
			velocity.x = move_toward(velocity.x, eje * vmax, acel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, (FRIC_SUELO if en_suelo else FRIC_AIRE) * delta)

		# Salto con coyote time, buffer y altura variable
		if Input.is_action_just_pressed("saltar") and _aturdido <= 0.0:
			_buffer_salto = TIEMPO_BUFFER
		if _buffer_salto > 0.0 and _coyote > 0.0:
			velocity.y = VEL_SALTO
			_buffer_salto = 0.0
			_coyote = 0.0
			Juego.sfx("salto", -4.0)
		if Input.is_action_just_released("saltar") and velocity.y < -160.0:
			velocity.y *= 0.5

	# Ataque
	if Input.is_action_just_pressed("atacar") and _ataque_enfr <= 0.0 and _dash_t <= 0.0 and _aturdido <= 0.0:
		_iniciar_ataque()
	_procesar_ataque(delta)

	_vel_y_previa = velocity.y
	move_and_slide()

	if is_on_floor() and not _estaba_en_suelo and _vel_y_previa > 250.0:
		sprite.scale = Vector2(ESC * 1.2, ESC * 0.85)  # aplastamiento al aterrizar
	_estaba_en_suelo = is_on_floor()
	_animar(delta)

	if camara != null and global_position.y > camara.limit_bottom + 260:
		die()


func _temporizadores(delta: float) -> void:
	_coyote = TIEMPO_COYOTE if is_on_floor() else _coyote - delta
	_buffer_salto -= delta
	_inv = maxf(_inv - delta, 0.0)
	_aturdido = maxf(_aturdido - delta, 0.0)
	_dash_t = maxf(_dash_t - delta, 0.0)
	_dash_enfr = maxf(_dash_enfr - delta, 0.0)
	_ataque_enfr = maxf(_ataque_enfr - delta, 0.0)


func _iniciar_esquiva() -> void:
	_dash_t = DURACION_DASH
	_dash_enfr = ENFRIAMIENTO_DASH
	_dash_dir = dir_cara
	_fantasma_t = 0.0
	velocity.y = 0.0
	Juego.sfx("esquivar", -4.0)


func _crear_fantasma() -> void:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var f := Sprite2D.new()
	f.texture = tex
	f.global_position = sprite.global_position
	f.scale = sprite.scale
	f.flip_h = sprite.flip_h
	f.offset = sprite.offset
	f.modulate = Color(0.5, 0.8, 1.0, 0.5)
	get_parent().add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.25)
	tw.tween_callback(f.queue_free)


func _iniciar_ataque() -> void:
	_ataque_t = 0.0
	_ataque_enfr = ENFRIAMIENTO_ATAQUE
	_golpeados.clear()
	_hitbox.position.x = 38.0 * dir_cara
	_corte.position.x = 14.0 * dir_cara
	_corte.scale.x = dir_cara
	sprite.play("ataque")
	Juego.sfx("corte", -6.0, randf_range(0.92, 1.1))


func _procesar_ataque(delta: float) -> void:
	if _ataque_t < 0.0:
		return
	_ataque_t += delta
	if _ataque_t >= VENTANA_GOLPE.x and _ataque_t <= VENTANA_GOLPE.y:
		for b in _hitbox.get_overlapping_bodies():
			if b in _golpeados or not b.is_in_group("enemigos"):
				continue
			if b.get("muerto") == true:
				continue
			_golpeados.append(b)
			if b.has_method("take_damage"):
				b.take_damage(DANO_ATAQUE)
			Juego.sfx("golpe", -3.0, randf_range(0.9, 1.1))
			sacudir(4.0)
			Juego.congelar(0.05)
	if _ataque_t >= DURACION_ATAQUE:
		_ataque_t = -1.0


func take_damage(cantidad: float = 1.0) -> void:
	if muerto or _inv > 0.0 or _dash_t > 0.0:
		return
	if not Juego.herir(int(ceil(cantidad))):
		die()
		return
	_inv = TIEMPO_INVULNERABLE
	_aturdido = TIEMPO_ATURDIDO
	_ataque_t = -1.0
	velocity = Vector2(-dir_cara * 220.0, -300.0)
	Juego.sfx("herido")
	sacudir(7.0)
	Juego.congelar(0.07)
	sprite.modulate = Color(2.0, 0.4, 0.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


func die() -> void:
	if muerto:
		return
	muerto = true
	Juego.matar()
	Juego.sfx("muerte")
	_ataque_t = -1.0
	velocity = Vector2(-dir_cara * 90.0, -320.0)
	sprite.visible = true
	sprite.rotation = 0.0
	sprite.play("muerte")
	create_tween().tween_property(sprite, "modulate:a", 0.0, 0.8).set_delay(0.7)
	await get_tree().create_timer(1.5).timeout
	Juego.jugador_murio()


func sacudir(fuerza: float) -> void:
	if camara == null:
		return
	var tw := create_tween()
	for i in 5:
		var f := fuerza * (1.0 - i / 5.0)
		tw.tween_property(camara, "offset", Vector2(randf_range(-f, f), randf_range(-f, f)), 0.025)
	tw.tween_property(camara, "offset", Vector2.ZERO, 0.03)


func _animar(delta: float) -> void:
	var en_suelo := is_on_floor()
	sprite.flip_h = dir_cara < 0.0
	sprite.rotation = 0.0

	var anim := "idle"
	if _ataque_t >= 0.0:
		anim = "ataque"
	elif _aturdido > 0.0:
		anim = "herido"
	elif not en_suelo:
		anim = "subir" if velocity.y < 0.0 else "caer"
	elif absf(velocity.x) > 25.0 or _dash_t > 0.0:
		anim = "correr"
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.speed_scale = 1.0 + (0.6 if _dash_t > 0.0 else 0.0)

	var objetivo := Vector2(ESC, ESC)
	if _dash_t > 0.0:
		objetivo = Vector2(ESC * 1.15, ESC * 0.9)
	sprite.scale = sprite.scale.lerp(objetivo, minf(1.0, 18.0 * delta))

	# Parpadeo mientras es invulnerable
	sprite.visible = _inv <= 0.0 or int(_inv * 22.0) % 2 == 0
