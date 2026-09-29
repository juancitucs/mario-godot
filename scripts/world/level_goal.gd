class_name LevelGoal
extends Node2D
## Meta del nivel 1-1: mástil con bandera (``flag-mast.png`` + ``final-flag.png``).
##
## La guía no implementa condición de victoria (termina en las animaciones),
## así que se añade la mínima fiel al original: tocar el mástil completa el
## nivel a través del grupo ``game`` (ver ``scripts/main.gd``).

@onready var _win_area: Area2D = $WinArea

var _done := false


func _ready() -> void:
	_win_area.body_entered.connect(_on_win_body_entered)


func _on_win_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body is PlayerMovement:
		_done = true
		get_tree().call_group("game", "complete_level")
