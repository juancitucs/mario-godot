class_name PlayerMovement
extends CharacterBody2D

const GROUP_PLAYER := "player"

@export_category("Movimiento")
@export var move_speed: float = 100.0
@export var jump_velocity: float = -300.0
@export var skid_deceleration: float = 600.0
@export_category("Muerte")
@export var death_delay: float = 1.5

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD)
var is_crouching := false
var hit := false
var is_dead := false
var death_frozen := false
var is_grounded := false

func is_falling() -> bool:
	return self.velocity.y > 0
func _physics_process(delta: float) -> void:
	if is_dead:
		if not death_frozen:
			velocity.y += get_gravity().y * delta
			position += velocity * delta
		return

	var direction := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("move_up", "move_down")

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if hit:
		velocity.y = jump_velocity * 0.6
		hit = false


	is_crouching = is_on_floor() and vertical > 0.0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var skidding := false
	if direction == 0.0 or is_crouching:
		velocity.x = 0.0
	elif not is_zero_approx(velocity.x) and signf(direction) != signf(velocity.x):
		velocity.x = move_toward(velocity.x, 0.0, skid_deceleration * delta)
		skidding = true
	else:
		velocity.x = direction * move_speed

	move_and_slide()
	is_grounded = is_on_floor()
	_update_animation(direction, skidding)

func _update_animation(direction: float, skidding: bool) -> void:
	if not is_on_floor():
		_sprite.play(&"jumping")  # Mario_Jump
	elif is_crouching:
		_sprite.play(&"crouching")  # Mario_DownPole1 reutilizado como postura agachado
	elif skidding:
		_sprite.play(&"stopping")  # Mario_Skid
	elif absf(velocity.x) > 0.5:
		_sprite.play(&"running")  # Mario_Run1-3
	else:
		_sprite.play(&"idle")  # Mario_Idle
	if not is_zero_approx(direction):
		_sprite.flip_h = direction < 0.0


func bounce() -> void:
	if is_dead:
		return
	hit = true


func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	death_frozen = true 
	_collision.set_deferred("disabled", true)

	velocity = Vector2.ZERO
	is_crouching = false
	_sprite.flip_h = false
	_sprite.play(&"dying")
	await get_tree().create_timer(0.5).timeout
	velocity = Vector2(0, -350)
	death_frozen = false
	await get_tree().create_timer(death_delay).timeout
