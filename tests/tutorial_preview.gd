extends SceneTree
## Capture the guided encounter and visible health recovery using real input.
var game: Node2D

func _initialize() -> void:
	call_deferred("capture")

func snapshot(label: String, size: Vector2i) -> void:
	game.get_child(0).refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/tutorial_%s_%dx%d.png" % [label, size.x, size.y])

func advance_to(stage: int) -> void:
	for i in range(400):
		if game.tutorial_stage == stage:
			return
		game._physics_process(0.05)
	push_error("Tutorial did not reach stage %d" % stage)
	quit(1)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	game = load("res://main.tscn").instantiate()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.settings_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	for size in [Vector2i(320, 568), Vector2i(390, 844)]:
		root.size = size
		await process_frame
		await process_frame
		game.configure_viewport()
		game.start_tutorial()
		await snapshot("start", size)
		game.handle_primary_press(game.tutorial_button.get_center())
		await snapshot("draw", size)
		var guide: PackedVector2Array = game.tutorial_guide_points()
		game.handle_touch_press(game.world_transform * guide[0], 0)
		game.handle_touch_release(game.world_transform * guide[1], 0)
		advance_to(2)
		await snapshot("rebound", size)
		advance_to(3)
		await snapshot("bonk", size)
		advance_to(4)
		for i in range(100):
			game._physics_process(0.05)
		await snapshot("bomb", size)
		game.use_space_bomb()
		await snapshot("health", size)
		advance_to(6)
		game._physics_process(0.5)
		await snapshot("hurt", size)
		game.handle_primary_press(game.world_transform * Vector2(game.health_pickup.pos))
		game._physics_process(0.15)
		await snapshot("healed", size)
		game._physics_process(1.6)
		await snapshot("complete", size)
	game.queue_free()
	await process_frame
	quit()
