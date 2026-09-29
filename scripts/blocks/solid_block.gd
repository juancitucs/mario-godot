class_name SolidBlock
extends StaticBody2D
## Bloque sólido genérico (ladrillo ``block.png`` o piedra ``immovableBlock.png``).
##
## La guía de Unity usa un único Tilemap con colliders para todo el suelo y los
## bloques. En Godot separamos responsabilidades: el suelo sigue en el
## TileMapLayer y cada bloque interactivo es una escena instanciable con su
## propio ``bump()`` (el saltito al golpearlo por debajo).

## Textura del bloque (ladrillo, piedra, ...). Se asigna por instancia.
@export var texture: Texture2D:
	set(value):
		texture = value
		_apply_texture()

@onready var _sprite: Sprite2D = $Sprite2D

var _bumping := false


func _ready() -> void:
	collision_layer = 1 # Ground: lo pisan Mario y los Goombas.
	collision_mask = 0
	_apply_texture()


func _apply_texture() -> void:
	if is_node_ready():
		_sprite.texture = texture


## Saltito visual al golpear el bloque por debajo (sin romperlo: la guía no
## incluye potenciadores, Mario siempre es pequeño).
func bump() -> void:
	if _bumping:
		return
	_bumping = true
	var base_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", base_y - 6.0, 0.08)
	tween.tween_property(self, "position:y", base_y, 0.12)
	tween.tween_callback(func() -> void: _bumping = false)
