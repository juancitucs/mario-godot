extends Camera2D
@onready var player = $"../Mario"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player.position.x <= 160.0:
		self.position.x = player.position.x
