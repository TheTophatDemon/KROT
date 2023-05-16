extends Node2D

const PREFAB_CROP = preload("res://scenes/objects/crop.tscn")
const PREFAB_FARMER = preload("res://scenes/actors/farmer.tscn")

const SEED_PLANT_INTERVAL = 5

const SAFETY_RADIUS = 128.0 #No objects will be spawned within this distance of the player
const OBSTACLE_GRID_SPACING = Vector2(64.0, 64.0)
#Lists pairs of obstacle prefabs and their spawn frequencies
const OBSTACLES = [
	[preload("res://scenes/objects/tree.tscn"), 0.2],
	[preload("res://scenes/objects/stone.tscn"), 0.1],
	#[preload("res://scenes/actors/farmer.tscn"), 0.05]	
]

const MAX_FARMERS = 30

onready var ground_tiles = $Ground
onready var soil_tiles = $Soil
onready var ysort = $YSort

var seed_plant_timer:float = 999.0
var farmer_spawn_timer:float = 0.0
var farmer_phase:int = 0

func generate_map(cols, rows):
	var xs = -int(cols/2)
	var ys = -int(rows/2)
	#Put down random grass tiles
	var grass_id = ground_tiles.tile_set.find_tile_by_name("grass")
	var boundary_id = ground_tiles.tile_set.find_tile_by_name("boundary")
	for x in range(cols):
		for y in range(rows):
			if x == 0 or y == 0 or x == cols - 1 or y == rows - 1:
				var corner = (x == 0 and y == 0) \
					or (x == cols - 1 and y == 0) \
					or (x == cols - 1 and y == rows - 1) \
					or (x == 0 and y == rows - 1)
				#Draw edge tiles sparsely
				if randf() < 0.7 and !corner:
					ground_tiles.set_cell(xs+x, ys+y, grass_id)
				else:
					#Place solid boundaries at the edges
					ground_tiles.set_cell(xs+x, ys+y, boundary_id)
			elif x == 1 or y == 1 or x == cols - 2 or y == rows - 2:
				#Make sure the tiles behind edge tiles aren't flipped.
				#That would mess up the autotiling.
				ground_tiles.set_cell(xs+x, ys+y, grass_id, false, false)
			else:
				#Randomly flip interior tiles
				var flip_x = bool(randi() % 2)
				var flip_y = bool(randi() % 2)
				ground_tiles.set_cell(xs+x, ys+y, grass_id, flip_x, flip_y)
	#Place boundary tiles outside of the map
	for x in range(cols):
		ground_tiles.set_cell(xs+x, ys-1, boundary_id)
		ground_tiles.set_cell(xs+x, -ys, boundary_id)
	for y in range(rows):
		ground_tiles.set_cell(xs, ys+y, boundary_id)
		ground_tiles.set_cell(-xs, ys+y, boundary_id)
	#Update autotiling
	ground_tiles.update_bitmask_region()
	#Put down horizontal strips of soil
	var soil_id = soil_tiles.tile_set.find_tile_by_name("soil")
	for y in range(rows - 4):
		var n_strips = randi() % (cols / 16)
		var strip_x = 2
		for s in range(n_strips):
			var length = (randi() % 8) + 4
			var remaining = (cols - 2 - strip_x - length)
			if remaining > 0:
				strip_x += randi() % remaining
				for o in range(length):
					var x = strip_x + o
					var tile_coords = Vector2(xs + x, ys + y + 2)
					#Place soil only if it's outside the starting area
					if soil_tiles.map_to_world(tile_coords).length() > SAFETY_RADIUS:
						soil_tiles.set_cell(tile_coords.x, tile_coords.y, soil_id)
				strip_x += length
			else:
				break
	#Update autotiling
	soil_tiles.update_bitmask_region()

#Place obstacles throughout the map based on a large grid.
func place_obstacles():
	var ground_rect = ground_tiles.get_used_rect()
	var min_bound = ground_rect.position * ground_tiles.cell_size
	var max_bound = ground_rect.end * ground_tiles.cell_size
	
	#Shrink the boundary so that things don't get placed near the water
	min_bound += ground_tiles.cell_size * 2.0
	max_bound -= ground_tiles.cell_size * 2.0
	
	var grid_size = (max_bound - min_bound) / OBSTACLE_GRID_SPACING
	var cols = floor(grid_size.x)
	var rows = floor(grid_size.y)
	for x in range(cols):
		for y in range(rows):
			var pos = Vector2()
			pos.x = min_bound.x + (x * OBSTACLE_GRID_SPACING.x) + \
				rand_range(OBSTACLE_GRID_SPACING.x / 3.0, 2.0 * OBSTACLE_GRID_SPACING.x / 3.0)
			pos.y = min_bound.y + (y * OBSTACLE_GRID_SPACING.y) + \
				rand_range(OBSTACLE_GRID_SPACING.y / 3.0, 2.0 * OBSTACLE_GRID_SPACING.y / 3.0)
			
			#Don't spawn next to the player
			if pos.length() < SAFETY_RADIUS:
				continue
			
			var key = randf()
			var freq = 0.0
			for p in OBSTACLES:
				freq += p[1]
				if key <= freq:
					var ob = p[0].instance()
					ysort.add_child(ob)
					ob.position = pos
					break	
					
func spawn_crops(density:float, random_growth:bool = false):
	var test_circle = CircleShape2D.new()
	test_circle.radius = 8.0
	var test_params = Physics2DShapeQueryParameters.new()
	test_params.set_shape(test_circle)
	test_params.collide_with_areas = true
	test_params.collide_with_bodies = true
	var space_state = get_world_2d().direct_space_state
	
	var soils = soil_tiles.get_used_cells()
	for pos in soils:
		if randf() < density:
			# Place if there's nothing intersecting
			var w_pos = soil_tiles.map_to_world(pos) + (soil_tiles.cell_size / 2.0)
			test_params.transform = Transform2D(Vector2.RIGHT, Vector2.DOWN, w_pos)
			var blocking = space_state.intersect_shape(test_params)
			if blocking.size() == 0:
				var crop = PREFAB_CROP.instance()
				crop.random_growth = random_growth
				ysort.add_child(crop)
				crop.position = w_pos

# Places a farmer in a random off-screen position.			
func spawn_farmer():
	var test_circle = CircleShape2D.new()
	test_circle.radius = 16.0
	var test_params = Physics2DShapeQueryParameters.new()
	test_params.set_shape(test_circle)
	test_params.collide_with_areas = true
	test_params.collide_with_bodies = true
	test_params.collision_layer = Globals.COL_BIT_HUMANS | Globals.COL_BIT_SOLIDS
	var space_state = get_world_2d().direct_space_state
	
	var camera = get_node("%Camera")
	var camera_rect = get_viewport().get_visible_rect()
	camera_rect.size *= camera.zoom
	camera_rect.position = camera.global_position - camera_rect.size / 2.0
	
	var attempts = 0
	while attempts < 50:
		attempts += 1
		var rect = soil_tiles.get_used_rect()
		var pos = rect.position + Vector2(rand_range(0.0, rect.size.x), rand_range(0.0, rect.size.y))
		
		# Skip if it's on camera
		if camera_rect.has_point(pos):
			continue
		
		# Place if there's nothing intersecting
		test_params.transform = Transform2D(Vector2.RIGHT, Vector2.DOWN, pos)
		var blocking = space_state.intersect_shape(test_params)
		if blocking.size() == 0:
			var farmer = PREFAB_FARMER.instance()
			ysort.add_child(farmer)
			farmer.position = pos
			break
	
func _ready():
	randomize()
	generate_map(64, 64)
	place_obstacles()
	
	#Set camera boundary to map boundary
	var ground_rect = ground_tiles.get_used_rect()
	var camera = get_node("%Camera")
	camera.limit_left = ground_rect.position.x * ground_tiles.cell_size.x
	camera.limit_top = ground_rect.position.y * ground_tiles.cell_size.y
	camera.limit_right = ground_rect.end.x * ground_tiles.cell_size.x
	camera.limit_bottom = ground_rect.end.y * ground_tiles.cell_size.y
	
	var player = get_node("%Krot")
	player.connect("deposited_crop", self, "_on_player_deposit_crop")

func _on_player_deposit_crop():
	# Turn on the farmer spawning once the player deposits the first crop
	if farmer_phase <= 0:
		farmer_phase = 1
		farmer_spawn_timer = 0.0

func get_random_soil_tile():
	var tiles = soil_tiles.get_used_cells()
	return tiles[randi() % tiles.size()] * soil_tiles.cell_size + (soil_tiles.cell_size / 2.0)

func _process(delta):
	
	#Plant new crops at random spots
	seed_plant_timer += delta
	if seed_plant_timer > SEED_PLANT_INTERVAL:
		# The timer is 999 at first, so that we can make sure the first crops are randomly grown
		if seed_plant_timer >= 999.0:
			spawn_crops(0.05, true)
		else:
			spawn_crops(0.01, false)
		seed_plant_timer = 0.0

	if farmer_phase > 0:
		# Farmer phase is 0 until the player deposits the first crop
		# So that nothing will hurt the player until the player figures out the goal of the game.
		farmer_spawn_timer -= delta
		var farmers = get_tree().get_nodes_in_group(Globals.GROUP_FARMERS)
		if len(farmers) < MAX_FARMERS and farmer_spawn_timer < 0.0:
			spawn_farmer()
			
			if farmer_phase < 4:
				farmer_spawn_timer = 15.0
			#elif farmer_phase < 15:
			else:
				farmer_spawn_timer = 60.0
			
			farmer_phase += 1
