class_name Pipe
extends StaticBody2D
## Tubería verde de la guía (``pipe1/2/3.png``).
##
## En Unity el docente arrastra el sprite de la tubería y le pone un
## BoxCollider2D. Aquí una sola escena cubre las tres alturas del nivel 1-1
## (2, 3 y 4 tiles) mediante ``height_tiles``: el script elige la textura y
## ajusta la colisión al tamaño exacto del sprite.

const TEXTURES := {
	2: preload("res://assets/pipe2.png"),
	3: preload("res://assets/pipe1.png"),
	4: preload("res://assets/pipe3.png"),
}

## Altura en tiles (cada tile son 16 px). El origen queda en el centro.
@export_range(2, 4, 1) var height_tiles: int = 2:
	set(value):
		height_tiles = clampi(value, 2, 4)
		_apply()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _shape_owned := false


func _ready() -> void:
	collision_layer = 1 # Ground.
	collision_mask = 0
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var texture: Texture2D = TEXTURES[height_tiles]
	_sprite.texture = texture
	# La forma se comparte entre instancias: se duplica una vez por tubería
	# para poder dimensionarla sin afectar a las demás.
	if not _shape_owned:
		_collision.shape = _collision.shape.duplicate()
		_shape_owned = true
	(_collision.shape as RectangleShape2D).size = texture.get_size()
