extends SceneTree
var game: Node2D

func _initialize() -> void:
	call_deferred("capture")

func snapshot(label: String, language: String, size: Vector2i) -> void:
	game.get_child(0).refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/language_%s_%s_%dx%d.png" % [language, label, size.x, size.y])

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
		for language in ["en", "ja", "vi"]:
			game.set_language(language, false)
			for state in ["menu", "paused", "play_menu", "level_select", "intro", "lost", "complete"]:
				game.start_round(3)
				game.highest_unlocked_level = 3
				game.earned_stars = 4
				game.state = state
				game.settings_open = state == "menu" or state == "paused"
				game.update_layout(Vector2(size))
				await snapshot(state, language, size)
			game.settings_open = false
			game.start_tutorial()
			await snapshot("tutorial_start", language, size)
			game.handle_primary_press(game.tutorial_button.get_center())
			await snapshot("tutorial_draw", language, size)
			for stage in [4, 6, 7]:
				game.tutorial_stage = stage
				game.setup_tutorial_stage()
				game.update_layout(Vector2(size))
				await snapshot("tutorial_%d" % stage, language, size)
	game.queue_free()
	await process_frame
	quit()
