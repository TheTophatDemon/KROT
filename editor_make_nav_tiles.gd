tool
extends EditorScript

func _run():
	var scene = get_scene()
	var nav_tiles:TileMap = scene.find_node("Nav")
	var ground_tiles:TileMap = scene.find_node("Ground")
	var tile_shape = RectangleShape2D.new()
	tile_shape.extents = Vector2(8.0, 8.0)
	nav_tiles.clear()
	for idx in ground_tiles.get_used_cells():
		# Place nav tiles wherever there is grass
		var ground_tile_id = ground_tiles.get_cell(idx.x, idx.y)
		if ground_tiles.tile_set.tile_get_name(ground_tile_id) == "grass":
			# Do not place the nav tile if there is an obstacle in the way
			var dont_place = false
			for obstacle in scene.get_tree().get_nodes_in_group("obstacle"):
				var collision_shape:CollisionShape2D = obstacle.get_node("CollisionShape2D")
				var obstacle_shape_tform = collision_shape.global_transform
				var tile_global_pos = ground_tiles.to_global(ground_tiles.map_to_world(idx) + ground_tiles.cell_size / 2.0)
				var tile_shape_tform = Transform2D(0.0, tile_global_pos)
				if collision_shape.shape.collide(obstacle_shape_tform, tile_shape, tile_shape_tform):
					dont_place = true
					break
			if not dont_place:
				nav_tiles.set_cell(idx.x, idx.y, 0)
