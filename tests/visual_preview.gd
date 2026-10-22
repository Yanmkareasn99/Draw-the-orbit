extends SceneTree
## Run with a graphics renderer to capture reproducible UI review screenshots.
var game: Node2D
const Flow = preload("res://tests/screen_flow.gd")

func _initialize() -> void:
	call_deferred("capture")

func snapshot(filename: String) -> void:
	game.update_layout(root.get_visible_rect().size)
	game.get_child(0).refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot == null or screenshot.is_empty():
		push_error("Visual preview needs a graphics renderer, not --headless.")
		quit(1)
		return
	screenshot.save_png("res://artifacts/" + filename + ".png")
	print("Captured ", filename)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	game = load("res://main.tscn").instantiate()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.get_child(0).time = 1.0
	Flow.settle(game)
	await snapshot("menu")
	game.handle_primary_press(game.start_button.get_center())
	Flow.skip_intro(game)
	if game.state != "playing":
		push_error("Title Play button did not start the round.")
		quit(1)
		return
	game.elapsed = 147.5
	game.wave = 40
	game.bonks = 12
	game.highest_bonks = 36
	game.hits = 12
	game.space_bombs = 2
	game.health = 4
	game.health_pickup = {"pos": Vector2(710, 275), "life": 6.0}
	game.message_time = 0.0
	game.sketch = PackedVector2Array([Vector2(278, 270), Vector2(340, 245), Vector2(399, 250)])
	game.finish_sketch()
	game.barriers[0].life = 4.4
	game.sketch = PackedVector2Array([Vector2(615, 420), Vector2(650, 460), Vector2(650, 530)])
	game.finish_sketch()
	game.barriers[1].life = 0.8
	game.message_time = 0.0
	for i in range(8):
		var at := Vector2(170, 260) + Vector2((i % 4) * 185, (i / 4) * 310)
		var h: Dictionary = game.make_ufo(["saucer", "scout", "weaver", "brute"][i % 4], at, 40.0)
		h.warmup = 0.8 if i == 0 else 0.0
		h.redirected = i % 3 != 0
		h.recovery = 7.0 if i % 3 == 1 else 0.0
		game.hazards.append(h)
	game.popups.append({"pos": Vector2(335, 450), "text": "BONK!", "color": game.GOLD, "life": 0.9})
	game.burst(Vector2(335, 490), game.GOLD)
	await snapshot("gameplay")
	game.BarrierMotion.impact(game.barriers[0], 65.0, Vector2.DOWN, 100.0, 1.5)
	game.BarrierMotion.advance(game.barriers[0], 0.07)
	await snapshot("barrier_flex")
	game.BarrierMotion.advance(game.barriers[0], 0.18)
	await snapshot("barrier_spring_back")
	game.BarrierMotion.advance(game.barriers[0], 2.0)
	game.bomb_flash = game.BOMB_FLASH_TIME * 0.5
	await snapshot("bomb_blast")
	game.bomb_flash = 0.0
	game.drawing = true
	game.sketch = PackedVector2Array([Vector2(380, 540), Vector2(410, 570), Vector2(470, 590)])
	await snapshot("drawing")
	game.drawing = false
	game.sketch.clear()
	game.state = "paused"
	await snapshot("paused")
	game.state = "lost"
	game.health = 0
	await snapshot("defeat")
	for size in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(320, 568), Vector2i(568, 320), Vector2i(768, 1024)]:
		root.size = size
		await process_frame
		await process_frame
		game.health = 4
		for preview_state in ["menu", "playing", "paused"]:
			game.state = preview_state
			await snapshot("mobile_%dx%d_%s" % [size.x, size.y, preview_state])
	game.state = "playing"
	game.elapsed = 3661.0
	root.size = Vector2i(320, 568)
	await process_frame
	await process_frame
	await snapshot("mobile_hour_survival")
	game.free()
	quit()
