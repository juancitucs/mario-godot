class_name Hud
extends CanvasLayer
## HUD mínimo del nivel: contador de monedas y mensaje central.
##
## La guía de Unity no incluye HUD; se añade porque los bloques interrogante
## dan monedas y el jugador necesita verlas. Las monedas y la meta avisan por
## el grupo ``hud`` / ``game`` para no acoplarse a la escena principal.

var coins := 0

@onready var _coins_label: Label = $CoinsLabel
@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	add_to_group("hud")
	_update_coins()
	_message_label.visible = false


func add_coin() -> void:
	coins += 1
	_update_coins()


func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.visible = true


func _update_coins() -> void:
	_coins_label.text = "MONEDAS x%02d" % coins
