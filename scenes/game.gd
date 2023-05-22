extends Node2D

const PREFAB_CROP = preload("res://scenes/objects/crop.tscn")
const PREFAB_FARMER = preload("res://scenes/actors/farmer.tscn")

const SEED_PLANT_INTERVAL = 5

const MAX_FARMERS = 30

onready var ground_tiles = $Ground
onready var soil_tiles = $Soil
onready var ysort = $YSort

var seed_plant_timer:float = 999.0
var farmer_spawn_timer:float = 0.0
var farmer_phase:int = 0

var high_score:int = 0
var best_time:int = 0
					
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

func update_stats():
	high_score = max(high_score, get_node("%Krot").score)
	best_time = max(best_time, floor(get_node("%Krot").life_time))

func end_game():
	# Save the high score
	var config = ConfigFile.new()
	config.set_value("player_stats", "high_score", high_score)
	config.set_value("player_stats", "best_time", best_time)
	config.save("user://scores.cfg")

	get_tree().change_scene("res://scenes/title.tscn")

# Places a farmer in a random off-screen position.			
func spawn_farmer():
	var spawners = get_tree().get_nodes_in_group(Globals.GROUP_SPAWNER)
	spawners.shuffle()
	
	for spawner in spawners:
		if spawner.can_spawn():
			var farmer = PREFAB_FARMER.instance()
			ysort.add_child(farmer)
			farmer.global_position = spawner.global_position
			print("Farmer spawned")
			return
	print("Spawn failed")
	
func _init():
	# Read in high score and best time
	var config = ConfigFile.new()
	var err = config.load("user://scores.cfg")
	if err != OK:
		print("Could not load configuration file: ")
		printerr(err)
		return
	high_score = config.get_value("player_stats", "high_score", 0)
	best_time = config.get_value("player_stats", "best_time", 0)

	
func _ready():
	randomize()
	
	# Make the navigation tilemap invisible without disabling its navigation mesh.
	$Nav.visible = true
	$Nav.modulate = Color.transparent
	
	var player = get_node("%Krot")
	player.connect("deposited_crop", self, "_on_player_deposit_crop")
	player.connect("die", self, "update_stats")

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
			
			if farmer_phase < 6:
				farmer_spawn_timer = 15.0
			elif farmer_phase < 12:
				farmer_spawn_timer = 10.0
			else:
				farmer_spawn_timer = 20.0
			
			farmer_phase += 1
