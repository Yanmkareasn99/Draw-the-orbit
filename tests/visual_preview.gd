extends SceneTree
## Run with a graphics renderer to capture reproducible UI review screenshots.
var game: Node2D

func _initialize() -> void:
	call_deferred("capture")

func snapshot(filename: String) -> void:
	game.get_child(0).queue_redraw()
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
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.get_child(0).time = 1.0
	await snapshot("menu")
	game.start_round()
	game.elapsed = 27.5
	game.score = 1200
	game.hits = 12
	game.health = 4
	game.message_time = 0.0
	game.sketch = PackedVector2Array([Vector2(278, 270), Vector2(340, 245), Vector2(399, 250)])
	game.finish_sketch()
	game.barriers[0].life = 3.2
	game.sketch = PackedVector2Array([Vector2(615, 420), Vector2(650, 460), Vector2(650, 530)])
	game.finish_sketch()
	game.barriers[1].life = 0.8
	game.message_time = 0.0
	for i in range(8):
		var at := Vector2(170, 260) + Vector2((i % 4) * 185, (i / 4) * 310)
		game.hazards.append({"pos": at, "vel": (game.CENTER - at).normalized() * 40, "warmup": 0.8 if i == 0 else 0.0, "radius": 9.0, "redirected": i % 3 != 0, "recovery": 7.0 if i % 3 == 1 else 0.0, "look": i % 3})
	game.popups.append({"pos": Vector2(335, 470), "text": "+200  BONK!", "color": game.GOLD, "life": 0.8})
	game.burst(Vector2(335, 490), game.GOLD)
	await snapshot("gameplay")
	game.drawing = true
	game.sketch = PackedVector2Array([Vector2(380, 540), Vector2(410, 570), Vector2(470, 590)])
	await snapshot("drawing")
	game.drawing = false
	game.sketch.clear()
	game.state = "paused"
	await snapshot("paused")
	game.state = "won"
	await snapshot("victory")
	game.state = "lost"
	game.health = 0
	await snapshot("defeat")
	game.free()
	quit()
