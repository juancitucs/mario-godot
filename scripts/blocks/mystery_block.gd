class_name MysteryBlock
extends StaticBody2D

const COIN_SCENE: PackedScene = preload("res://scenes/pickups/coin.tscn")

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hit_area: Area2D = $BottomHit

var used := false
var _bumping := false


func _ready() -> void:
	collision_layer = 1 # Ground.
	collision_mask = 0
	_sprite.play(&"idle")
	_hit_area.body_entered.connect(_on_bottom_body_entered)


func _on_bottom_body_entered(body: Node2D) -> void:
	if used or _bumping:
		return
	if not body is PlayerMovement:
		return
	if body.global_position.y > global_position.y + 2.0 and not body.is_falling():
		hit()


func hit() -> void:
	if used:
		return
	used = true
	_bumping = true
	_sprite.play(&"used")
	_spawn_coin()
	var base_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", base_y - 6.0, 0.08)
	tween.tween_property(self, "position:y", base_y, 0.12)
	tween.tween_callback(func() -> void: _bumping = false)


func _spawn_coin() -> void:
	var coin := COIN_SCENE.instantiate() as Coin
	get_parent().add_child(coin)
	coin.global_position = global_position + Vector2(0, -16)
	coin.pop()
