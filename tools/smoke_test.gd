extends SceneTree
## Smoke test headless: arranca la escena principal y comprueba los puntos
## clave de la guía sin necesidad de abrir el editor.
##
## Uso:  godot --headless --path . -s tools/smoke_test.gd
## Sale con código 0 si todo pasa, 1 si algo falla.

## Acciones de entrada y la tecla física que debe activarlas.
const EXPECTED_ACTIONS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_down": KEY_S,
	"jump": KEY_SPACE,
	"pause": KEY_ESCAPE,
}

var _failures: PackedStringArray = []
var _elapsed := 0.0
var _phase := 0

var _main: Node2D
var _mario: PlayerMovement
var _goomba: Goomba
var _camera: Camera2D
var _camera_x_before := 0.0
var _dropped := false
var _deepest_y := 0.0
var _bounced := false


func _initialize() -> void:
	_check_input_map()
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main
	_mario = _main.get_node("Mario") as PlayerMovement
	_camera = _main.get_node("Camera2D") as Camera2D


func _process(delta: float) -> bool:
	_elapsed += delta
	_track_bounce()
	match _phase:
		0:
			if _elapsed >= 1.5:
				_phase = 1
				_check_world()
				# Cámara: Mario cruza el 50% del encuadre.
				_camera_x_before = _camera.global_position.x
				_mario.global_position = Vector2(600.0, 160.0)
		1:
			if _elapsed >= 3.0:
				_phase = 2
				_check_camera_follows()
				# Pisotón: suelta a Mario sobre la cabeza del Goomba.
				_goomba = _main.get_node_or_null("Level1/Goomba") as Goomba
				if _goomba == null:
					_fail("el Goomba desapareció antes de poder pisotearlo")
				else:
					_dropped = true
					_deepest_y = 0.0
					_mario.global_position = _goomba.global_position + Vector2(0, -32)
		2:
			if _elapsed >= 4.0:
				_phase = 3
				_check_stomp()
				_check_side_collision()
		3:
			if _elapsed >= 5.0:
				_phase = 4
				_check_death()
		4:
			if _elapsed >= 7.0:
				_check_reload()
				return _finish()
	return false


## Seguimiento del rebote: Mario desciende sobre el Goomba y debe volver
## a subir (si no rebota, se queda en el suelo y esto nunca se cumple).
func _track_bounce() -> void:
	if not _dropped or _bounced or not is_instance_valid(_mario):
		return
	_deepest_y = maxf(_deepest_y, _mario.global_position.y)
	if _deepest_y > 170.0 and _mario.global_position.y < _deepest_y - 6.0:
		_bounced = true


func _finish() -> bool:
	for failure in _failures:
		printerr("FAIL: ", failure)
	if _failures.is_empty():
		print("SMOKE TEST OK")
		quit(0)
	else:
		printerr("SMOKE TEST FAILED (", _failures.size(), " comprobaciones)")
		quit(1)
	return true


func _fail(message: String) -> void:
	_failures.append(message)


# --- Comprobaciones ---------------------------------------------------------


func _check_input_map() -> void:
	for action in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			_fail("falta la acción de entrada '%s'" % action)
			continue
		var event := InputEventKey.new()
		event.physical_keycode = EXPECTED_ACTIONS[action]
		event.pressed = true
		if not InputMap.event_is_action(event, action):
			_fail("la acción '%s' no responde a su tecla" % action)


func _check_world() -> void:
	if not _mario.is_in_group(PlayerMovement.GROUP_PLAYER):
		_fail("Mario no está en el grupo '%s'" % PlayerMovement.GROUP_PLAYER)
	if not _mario.is_on_floor():
		_fail("Mario no está apoyado en el suelo")
	if absf(_mario.global_position.y - 184.0) > 1.0:
		_fail("Mario debería nacer sobre el suelo en y=184 (está en y=%.1f)" % _mario.global_position.y)
	if _mario.get_node("AnimatedSprite2D").animation != &"idle":
		_fail("la animación inicial de Mario no es 'idle'")
	if _camera.global_position.x < 160.0:
		_fail("la cámara ha retrocedido respecto a su posición inicial")

	if _main.get_node_or_null("Level1/PuntoA") == null:
		_fail("falta el punto de patrulla PuntoA en el nivel")
	if _main.get_node_or_null("Level1/PuntoB") == null:
		_fail("falta el punto de patrulla PuntoB en el nivel")
	if _main.get_node_or_null("Level1/KillZone") == null:
		_fail("falta el trigger de vacío (KillZone) en el nivel")

	_goomba = _main.get_node_or_null("Level1/Goomba") as Goomba
	if _goomba == null:
		_fail("no se encontró al Goomba en el nivel")
		return
	if not _goomba.is_on_floor():
		_fail("el Goomba no está apoyado en el suelo")
	if absf(_goomba.global_position.x - 224.0) < 0.5:
		_fail("el Goomba no patrulla: sigue en su posición inicial")
	if _goomba.global_position.x < 175.0 or _goomba.global_position.x > 321.0:
		_fail("el Goomba se ha salido de sus puntos de patrulla (x=%.1f)" % _goomba.global_position.x)


func _check_camera_follows() -> void:
	if _camera.global_position.x <= _camera_x_before + 1.0:
		_fail("la cámara no avanzó al cruzar Mario el 50% del encuadre")


func _check_stomp() -> void:
	if _goomba == null or not is_instance_valid(_goomba) or _goomba.is_squashed:
		pass  # comportamiento esperado: aplastado y eliminado
	else:
		_fail("pisotón: el Goomba no se aplastó")
	if _mario.is_dead:
		_fail("pisotón: Mario murió en lugar de rebotar")
	if not _bounced:
		_fail("pisotón: Mario no rebotó sobre el Goomba")


func _check_side_collision() -> void:
	# Un Goomba nuevo al lado de Mario: el contacto de costado debe matarlo.
	var enemy := (load("res://scenes/enemies/goomba.tscn") as PackedScene).instantiate() as Goomba
	enemy.punto_a_path = NodePath("../PuntoA")
	enemy.punto_b_path = NodePath("../PuntoB")
	_main.get_node("Level1").add_child(enemy)
	enemy.global_position = Vector2(_mario.global_position.x + 6.0, 184.0)
	_mario.global_position = Vector2(_mario.global_position.x, 184.0)


func _check_death() -> void:
	if not _mario.is_dead:
		_fail("colisión lateral: Mario no murió")
	elif _mario.get_node("AnimatedSprite2D").animation != &"dying":
		_fail("colisión lateral: no se reproduce la animación 'dying'")


func _check_reload() -> void:
	var fresh := root.get_node_or_null("Node2D/Mario") as PlayerMovement
	if fresh == null:
		_fail("tras morir la escena no se reinició")
	elif fresh.is_dead or not fresh.is_on_floor():
		_fail("tras reiniciar Mario no vuelve a nacer sobre el suelo")
