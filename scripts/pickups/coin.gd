class_name Coin
extends Area2D
## Moneda giratoria (``coin.png``, 4 frames).
##
## Dos usos: estática sobre los puentes de ladrillos (se recoge al tocarla) y
## emergente de los bloques interrogante (``pop()``: suma y se va con un
## saltito, como en el Mario original). Avisa al HUD con ``call_group`` para
## no acoplarse a la escena principal.

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player.
	_sprite.play(&"spin")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMovement:
		collect()


## Recogida por contacto.
func collect() -> void:
	if _collected:
		return
	_collected = true
	get_tree().call_group("hud", "add_coin")
	queue_free()


## Salida del bloque interrogante: suma la moneda y se eleva hasta desvanecerse.
func pop() -> void:
	if _collected:
		return
	_collected = true
	set_deferred("monitoring", false)
	get_tree().call_group("hud", "add_coin")
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 40.0, 0.35)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)
