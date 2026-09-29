class_name CameraFollow
extends Camera2D
## Adaptación de ``CameraFollow.cs`` de la guía (Unity).
##
## La cámara sólo avanza cuando Mario cruza el punto medio del encuadre
## (el 50% del ancho de la cámara del enunciado) y nunca retrocede, con el
## mismo ``Lerp`` por fotograma que usa el script del docente.
##
## Sobre el tamaño de cámara: la guía calcula ``240 / 16 = 15`` porque en
## Unity el orthographic size es media altura visible y el juego usa 320x240
## px con 16 px por unidad. En Godot la ventana ya mide 320x240 y la cámara
## trabaja con zoom 1, así que el encuadre equivalente es el que trae por
## defecto (15 tiles de alto).

## Nodo que la cámara sigue (Mario, dentro de la escena principal).
@export var target_path: NodePath = ^"../Mario"
## Factor de suavizado por fotograma (``followSpeed`` de la guía).
@export_range(0.01, 1.0, 0.01) var follow_speed: float = 0.1

var _target: Node2D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		push_warning("CameraFollow: no se encontró el objetivo en '%s'." % target_path)


func _process(_delta: float) -> void:
	if _target == null:
		return
	# Vector3 playerPosition = player.position;
	# if (playerPosition.x > cameraMidPointX) -> la cámara sólo avanza.
	if _target.global_position.x > global_position.x:
		global_position.x = lerpf(global_position.x, _target.global_position.x, follow_speed)
