extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	for size in [Vector2i(320, 568), Vector2i(390, 844)]:
		root.size = size
		await process_frame
		await process_frame
		for menu_state in ["play_menu", "level_select", "paused"]:
			game.start_round()
			game.highest_unlocked_level = 3
			game.state = menu_state
			game.configure_viewport()
			game.get_child(0).refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/%s_%dx%d.png" % [menu_state, size.x, size.y])
		for number in range(1, 7):
			game.start_round(number)
			game.state = "intro"
			game.intro_clock = 5.0 if number == 4 else 1.8
			game.configure_viewport()
			game.get_child(0).refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/intro_%d_%dx%d.png" % [number, size.x, size.y])
		game.change_screen("playing")
		game.transition_clock = game.TRANSITION_TIME * 0.65
		game.get_child(0).refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/iris_%dx%d.png" % [size.x, size.y])
		game.start_round(5)
		game.advance_boss(0.0)
		for shot in ["boss", "planet_spin"]:
			game.planet_spin_remaining = 0.95 if shot == "planet_spin" else 0.0
			game.get_child(0).refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/%s_%dx%d.png" % [shot, size.x, size.y])
	game.free()
	quit()
