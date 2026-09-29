class_name GameManager
extends Node2D
## Gestor de la escena principal (ex ``main.gd``).
##
## Responsabilidades:
## * ``pause`` (Esc): reinicia el nivel (atajo de pruebas del docente).
## * ``complete_level()``: la meta (``LevelGoal``) avisa por el grupo
##   ``game``; se muestra el mensaje de victoria y se recarga el nivel.

## Espera tras morir o ganar antes de recargar la escena.
@export var reload_delay: float = 2.5

var _completed := false


func _ready() -> void:
	add_to_group("game")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().reload_current_scene()


## La meta del nivel avisa aquí al tocar el mástil.
func complete_level() -> void:
	if _completed:
		return
	_completed = true
	get_tree().call_group("hud", "show_message", "¡NIVEL COMPLETO!")
	await get_tree().create_timer(reload_delay).timeout
	get_tree().reload_current_scene()
