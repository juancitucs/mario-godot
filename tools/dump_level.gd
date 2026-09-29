extends SceneTree
## Utilidad temporal: imprime la geometría del nivel (celdas del TileMap, sprite y cuerpos).


func _init() -> void:
	var level: PackedScene = load("res://scenes/levels/level1.tscn")
	var root: Node2D = level.instantiate()

	var tile_map: TileMapLayer = root.get_node("TileMapLayer") as TileMapLayer
	var cells: Array[Vector2i] = tile_map.get_used_cells()
	var min_x := 1 << 30
	var max_x := -(1 << 30)
	var min_y := 1 << 30
	var max_y := -(1 << 30)
	for c in cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)
	print("TileMap cells: ", cells.size(), " x[", min_x, "..", max_x, "] y[", min_y, "..", max_y, "]")
	print("TileMap global position: ", tile_map.global_position)
	var rows: Dictionary = {}
	for c in cells:
		rows[c.y] = int(rows.get(c.y, 0)) + 1
	var keys := rows.keys()
	keys.sort()
	for k in keys:
		print("  row y=", k, " tiles=", rows[k])

	var stage: Sprite2D = root.get_node("Stage11") as Sprite2D
	print("Stage pos=", stage.position, " size=", stage.get_rect().size)

	for child in root.get_children():
		if child is Node2D and child.name != "Stage11" and child.name != "TileMapLayer":
			print("Child: ", child.name, " pos=", (child as Node2D).position)

	root.free()
	quit()
