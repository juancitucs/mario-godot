extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -300.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		sprite.play("running")
		velocity.x = direction * SPEED
		sprite.flip_h = false if direction == 1 else true
		
	else:
		sprite.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# Add the gravity.
	if not is_on_floor():
		sprite.play("jumping")
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	move_and_slide()
