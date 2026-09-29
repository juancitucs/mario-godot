class_name PlayerMovement
extends CharacterBody2D
## Adaptación en Godot del script ``PlayerMovement.cs`` de la guía (Unity).
##
## Mecánicas de la guía cubiertas aquí:
## * Movimiento horizontal con ``moveSpeed`` (AWSD / flechas).
## * Salto con ``jumpForce`` sólo cuando Mario toca el suelo.
## * Agacharse manteniendo pulsado hacia abajo estando en el suelo.
## * Voltear el sprite según la dirección (``spriteRenderer.flipX``).
## * Rebote al pisar a un enemigo (el campo ``Hit`` de la guía).
## * Animaciones: Idle, Run, Skid (frenar), Jump, agachado y muerte.
##
## Equivalencias Unity -> Godot:
## * ``Rigidbody2D.velocity`` en ``FixedUpdate`` -> ``velocity`` en ``_physics_process``.
## * ``Physics2D.OverlapCircle(groundCheck)`` -> ``is_on_floor()`` de CharacterBody2D.
## * ``Animator`` + Blend Tree -> ``AnimatedSprite2D`` con ``SpriteFrames``.
## * Tag "Player" de Unity -> grupo "player" de Godot.

## Grupo que identifica al jugador (equivalente al tag "Player").
const GROUP_PLAYER := "player"

@export_category("Movimiento")
## Velocidad de movimiento horizontal (``moveSpeed`` en la guía).
@export var move_speed: float = 100.0
## Impulso vertical del salto (``jumpForce`` en la guía).
@export var jump_velocity: float = -300.0
## Desaceleración al cambiar de dirección: dura lo suficiente para
## mostrar el frame ``Mario_Skid`` de la guía.
@export var skid_deceleration: float = 600.0

@export_category("Muerte")
## Espera antes de reiniciar la escena tras morir.
@export var death_delay: float = 1.5

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

## ``isCrouching``: Mario agachado, no se puede mover.
var is_crouching := false
## ``Hit``: lo activa el Goomba al pisarlo y Mario rebota.
var hit := false
## Estado del jugador; ``true`` bloquea el control y la física.
var is_dead := false
## ``isGrounded`` de la guía: se expone para verlo en el inspector.
var is_grounded := false


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Input.GetAxis("Horizontal") / Input.GetAxis("Vertical")
	var direction := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("move_up", "move_down")

	# En Unity la gravedad la aplica el Rigidbody2D; aquí es el propio motor
	# el que empuja a los CharacterBody2D, sólo hay que integrarla.
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Rebote al pisar a un enemigo:
	#   if (Hit) { rb.velocity = new Vector2(rb.velocity.x, jumpForce); Hit = false; }
	if hit:
		velocity.y = jump_velocity
		hit = false

	# if (IsGrounded() && Input.GetAxis("Vertical") < 0) isCrouching = true;
	# (en Unity "abajo" es el eje negativo, en Godot el positivo)
	is_crouching = is_on_floor() and vertical > 0.0

	# if (Input.GetButtonDown("Jump") && IsGrounded()) isJumping = true;
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movimiento horizontal: anulado si está agachado; si cambia de sentido
	# frena primero (fracción de segundo mostrando el sprite de frenada).
	var skidding := false
	if direction == 0.0 or is_crouching:
		velocity.x = 0.0
	elif not is_zero_approx(velocity.x) and signf(direction) != signf(velocity.x):
		velocity.x = move_toward(velocity.x, 0.0, skid_deceleration * delta)
		skidding = true
	else:
		velocity.x = direction * move_speed

	move_and_slide()

	# isGrounded = IsGrounded();  (estado visible en el inspector)
	is_grounded = is_on_floor()
	_update_animation(direction, skidding)


## Equivalente al Animator / Blend Tree de la guía.
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

	# spriteRenderer.flipX = movement.x < 0
	if not is_zero_approx(direction):
		_sprite.flip_h = direction < 0.0


## Rebote al pisar la cabeza de un enemigo (``Mario.Hit = true`` en la guía).
## Lo llama el Goomba desde su área de cabeza.
func bounce() -> void:
	if is_dead:
		return
	hit = true


## Muerte del jugador: contacto con un enemigo de lado o caída al vacío.
## Reproduce ``Mario_Die`` y reinicia la escena pasados unos segundos.
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	is_crouching = false
	_sprite.flip_h = false
	_sprite.play(&"dying")  # Mario_Die
	_collision.set_deferred("disabled", true)
	await get_tree().create_timer(death_delay).timeout
	get_tree().reload_current_scene()
