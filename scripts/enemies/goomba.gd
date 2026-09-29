class_name Goomba
extends CharacterBody2D

@export_category("Patrulla")
@export var speed: float = 40.0
@export var punto_a_path: NodePath
@export var punto_b_path: NodePath
@export_range(0.5, 16.0, 0.5) var arrive_threshold: float = 2.0
@export_category("Aplastamiento")
@export var squash_time: float = 0.6

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _stomp_area: Area2D = $StompArea
@onready var _hurt_area: Area2D = $HurtArea

var _target: Marker2D
var _point_a: Marker2D
var _point_b: Marker2D
var is_squashed := false


func _ready() -> void:
	add_to_group("enemies")
	_point_a = get_node_or_null(punto_a_path) as Marker2D
	_point_b = get_node_or_null(punto_b_path) as Marker2D
	if _point_a == null or _point_b == null:
		push_warning("Goomba '%s': faltan PuntoA/PuntoB, se queda quieto." % name)
	else:
		_target = _point_a  # MoveToA = true (la guía empieza yendo hacia A)
	_stomp_area.body_entered.connect(_on_stomp_body_entered)
	_hurt_area.body_entered.connect(_on_hurt_body_entered)


func _physics_process(delta: float) -> void:
	if is_squashed:
		return

	# La gravedad, igual que en el jugador, la integra el motor.
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	velocity.x = _patrol_direction() * speed
	move_and_slide()

	# El sprite de la hoja mira a la izquierda: se voltea al avanzar a la derecha.
	if not is_zero_approx(velocity.x):
		_sprite.flip_h = velocity.x > 0.0


## Dirección hacia el punto de destino; al llegar, cambia de sentido.
## Equivale a los ``MoveToA``/``MoveToB`` de la guía, pero comprobando
## distancia en lugar de igualdad exacta de vectores (``transform.position
## == PuntoA.position`` nunca se cumpliría de forma fiable).
func _patrol_direction() -> float:
	if _target == null:
		return 0.0
	var offset := _target.global_position.x - global_position.x
	if absf(offset) <= arrive_threshold:
		_target = _point_b if _target == _point_a else _point_a
		offset = _target.global_position.x - global_position.x
	return signf(offset)


func _on_stomp_body_entered(body: Node2D) -> void:
	if is_squashed or not body is PlayerMovement:
		return
	if _is_stomp(body):
		_squash(body)


func _on_hurt_body_entered(body: Node2D) -> void:
	if is_squashed or not body is PlayerMovement:
		return
	# Si no es un pisotón válido, el contacto es de costado y Mario muere.
	if not _is_stomp(body):
		body.die()


## Un pisotón válido: Mario está por encima de la cabeza y cayendo.
## Así, las dos áreas dan el mismo veredicto aunque se activen en el mismo
## paso de física (al caminar de lado los dos rectángulos se solapan).
func _is_stomp(body: PlayerMovement) -> bool:
	return body.global_position.y <= global_position.y - 6.0 and body.velocity.y > 0.0


## Aplastado: se congela, se reproduce ``goomba_3`` y Mario rebota.
func _squash(player: PlayerMovement) -> void:
	is_squashed = true
	velocity = Vector2.ZERO
	_stomp_area.set_deferred("monitoring", false)
	_hurt_area.set_deferred("monitoring", false)
	_collision.set_deferred("disabled", true)
	_sprite.play(&"down")  # goomba_3 (aplastado)
	player.bounce()        # Mario.Hit = true -> salto de rebote
	await get_tree().create_timer(squash_time).timeout
	queue_free()
