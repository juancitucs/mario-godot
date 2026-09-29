class_name KillZone
extends Area2D
## Trigger de vacío (la guía: "colocar triggers para cuando mario caiga al
## vacío"). Si Mario entra en la zona, muere y la escena se reinicia.
##
## Se sitúa por debajo del suelo del nivel: cualquier caída fuera de las
## plataformas termina aquí en lugar de dejar al jugador perdido.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerMovement:
		body.die()
