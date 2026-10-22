extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func stroke(game: Node, points: PackedVector2Array) -> void:
	game.sketch = points.duplicate()
	game.finish_sketch()

func _initialize() -> void:
	var game := Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	var original := PackedVector2Array([Vector2(100, 180), Vector2(300, 180)])
	var invalid := [
		PackedVector2Array([Vector2(200, 140), Vector2(200, 220)]),
		PackedVector2Array([Vector2(150, 180), Vector2(350, 180)]),
		PackedVector2Array([Vector2(350, 180), Vector2(150, 180)]),
		PackedVector2Array([Vector2(100, 183), Vector2(300, 183)]),
		PackedVector2Array([Vector2(300, 180), Vector2(350, 180)])
	]
	for points in invalid:
		game.start_round()
		stroke(game, original)
		var ink: float = game.available_ink()
		game.sketch = points.duplicate()
		check(game.sketch_error() != "", "preview still rejects crossing, overlap, or touching")
		game.finish_sketch()
		check(game.barriers.size() == 1 and game.available_ink() == ink, "invalid stroke preserves existing barrier and ink")
	for points in [
		PackedVector2Array([Vector2(305, 180), Vector2(400, 180)]),
		PackedVector2Array([Vector2(200, 185), Vector2(200, 260)]),
		PackedVector2Array([Vector2(305, 140), Vector2(305, 220)])
	]:
		game.start_round()
		stroke(game, original)
		stroke(game, points)
		check(game.barriers.size() == 2, "narrow non-overlapping end-to-end and end-to-side gaps are accepted")
	game.start_round()
	stroke(game, original)
	stroke(game, PackedVector2Array([Vector2(324, 180), Vector2(400, 180)]))
	check(game.barriers.size() == 2, "exact twenty-four pixel endpoint gap is accepted")
	var ufo := game.make_ufo("saucer", Vector2(312, 140), 40)
	ufo.vel = Vector2(0, 40)
	ufo.warmup = 0
	game.hazards.append(ufo)
	game.step_world(2.0)
	check(not ufo.redirected and ufo.pos.y > 200, "standard UFO physically passes between both rounded barrier ends")
	game.start_round()
	stroke(game, original)
	game.age_barriers(5.0)
	stroke(game, PackedVector2Array([Vector2(200, 140), Vector2(200, 220)]))
	check(game.barriers.size() == 1, "expired barriers no longer block new strokes")
	game.start_round()
	stroke(game, PackedVector2Array([Vector2(100, 180), Vector2(200, 180), Vector2(150, 180)]))
	check(game.barriers.is_empty(), "backtracking over the same stroke is rejected")
	game.free()
	print("Barrier spacing checks: ", checks, "; failures: ", failures)
	quit(failures)
