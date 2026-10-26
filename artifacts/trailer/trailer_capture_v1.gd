extends SceneTree
## Deterministic promotional capture. Uses live game geometry, collision and audio.
const Game = preload("res://scripts/game.gd")
const Promo = preload("res://tests/trailer_overlay.gd")
const BEAT := 60.0 / 104.0
const CUTS := [0.0, 0.25 + BEAT * 4, 0.25 + BEAT * 8, 0.25 + BEAT * 16,
	0.25 + BEAT * 24, 0.25 + BEAT * 32, 0.25 + BEAT * 40, 0.25 + BEAT * 48,
	0.25 + BEAT * 56, 0.25 + BEAT * 64, 0.25 + BEAT * 72, 0.25 + BEAT * 80,
	0.25 + BEAT * 88, 0.25 + BEAT * 96, 0.25 + BEAT * 104]
var game: Node2D
var overlay: Node2D
var frame := 0
var scene_index := -1
var started := false
var drawn := false
var action_done := false
var guide := PackedVector2Array()

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	root.size = Vector2i(1080, 1920)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game = Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.settings_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.game_sound.set_process(false)
	game.game_sound.set_mix_volumes(0.0, 0.7)
	root.content_scale_size = Vector2i(1080, 1920)
	game.scale = Vector2(3, 3)
	game.update_layout(Vector2(360, 640))
	game.rng.seed = 1042026
	game.set_language("en", false)
	overlay = Promo.new(game)
	overlay.scale = Vector2(3, 3)
	root.add_child(overlay)
	started = true

func point(x: float, y: float) -> Vector2:
	return game.screen_to_world(Vector2(x, y))

func ship(at: Vector2, velocity: Vector2, kind: String = "saucer", redirected: bool = false) -> Dictionary:
	var h: Dictionary = game.make_ufo(kind, at, velocity.length())
	h.vel = velocity
	h.warmup = 0.0
	h.redirected = redirected
	h.recovery = 10.0 if redirected else 0.0
	game.hazards.append(h)
	game.total_ufos_spawned += 1
	return h

func rebound_scene() -> void:
	game.start_tutorial()
	game.tutorial_stage = 1
	game.setup_tutorial_stage()
	guide = game.tutorial_guide_points()
	game.tutorial_active = false
	game.spawn_clock = 100.0
	game.elapsed = 12.0
	game.highest_bonks = 32

func enter_scene(index: int) -> void:
	drawn = false
	action_done = false
	if index not in [2, 6]:
		game.start_round(1)
		game.spawn_clock = 100.0
		game.highest_bonks = 32
	game.get_child(0).visible = index not in [3, 4, 12, 13]
	match index:
		0:
			for i in range(8):
				var angle := i * TAU / 8
				var at: Vector2 = game.CENTER + Vector2.from_angle(angle) * 240
				ship(at, (game.CENTER - at).normalized() * 32, "scout" if i % 3 == 0 else "saucer")
		1, 5:
			rebound_scene()
		2:
			pass
		7:
			game.bonks = 4
			game.bomb_bonk_progress = 4
			for i in range(11):
				var at: Vector2 = game.CENTER + Vector2.from_angle(i * TAU / 11) * 205
				ship(at, (game.CENTER - at).normalized() * 12, "scout" if i % 3 == 0 else "saucer")
			ship(point(115, 170), Vector2(0, -70), "saucer", true)
			ship(point(150, 170), Vector2.ZERO)
		8:
			game.health = 4
			game.flash = 0.4
			game.health_pickup = {"pos": point(265, 300), "life": 9.0}
			game.play_sound("hurt")
			game.bonks = 9
			for i in range(4):
				var at := point(40 + i * 90, 160)
				ship(at, (game.CENTER - at).normalized() * 20)
		9:
			game.start_round(4)
			game.elapsed = 42
			game.bonks = 18
			game.hits = 36
			game.total_ufos_spawned = 48
			game.space_bombs = 1
			game.spawn_clock = 1.0
			for pair in [[Vector2(65, 190), Vector2(160, 225)], [Vector2(230, 355), Vector2(305, 315)]]:
				game.sketch = PackedVector2Array([game.screen_to_world(pair[0]), game.screen_to_world(pair[1])])
				game.finish_sketch()
			for i in range(12):
				var at: Vector2 = game.CENTER + Vector2.from_angle(i * TAU / 12) * 250
				ship(at, (game.CENTER - at).normalized() * 48, ["saucer", "scout", "weaver", "brute"][i % 4])
		10:
			game.start_round(5)
			game.boss.health = 6
			game.boss.clock = 0.5
			game.spawn_clock = 1.0
			game.bonks = 12
			for i in range(4):
				var at: Vector2 = game.boss.pos + Vector2(80 + i * 42, -30 + i * 20)
				ship(at, (game.boss.pos - at).normalized() * 150, "saucer", true)
		11:
			game.start_round(3)
			game.highest_unlocked_level = 3
			game.elapsed = 89.5
			game.health = 4
			game.bonks = 23
			game.highest_bonks = 32
			game.hits = 48
			game.total_ufos_spawned = 60
			game.spawn_clock = 100.0
	game.update_layout(Vector2(360, 640))
	print("TRAILER scene ", index + 1, " at ", frame / 30.0)

func _process(_delta: float) -> bool:
	if not started:
		return false
	var t := frame / 30.0
	if t >= CUTS[-1]:
		quit()
		return false
	var next := 0
	for i in range(CUTS.size() - 1):
		if t >= CUTS[i]:
			next = i
	if next != scene_index:
		scene_index = next
		enter_scene(scene_index)
	var local: float = t - CUTS[scene_index]
	var simulate := scene_index not in [3, 4, 12, 13]
	if scene_index in [1, 5]:
		if local >= 0.15 and not drawn:
			game.begin_sketch(guide[0])
			drawn = true
		if game.drawing:
			game.append_sketch_point(guide[0].lerp(guide[1], clampf((local - 0.15) / 0.85, 0, 1)))
			if local >= 1.0:
				game.finish_sketch()
		simulate = local >= 1.0
	if scene_index == 7 and local >= 2.4 and not action_done and game.space_bombs > 0:
		game.use_space_bomb()
		action_done = true
	if scene_index == 8 and local >= 1.5 and not action_done:
		game.collect_health_pickup(game.world_transform * Vector2(game.health_pickup.pos))
		action_done = true
	if simulate:
		game._physics_process(1.0 / 30.0)
	else:
		game.advance_feedback(1.0 / 30.0)
		game.advance_particles(1.0 / 30.0)
	game.update_layout(Vector2(360, 640))
	game.get_child(0).time = t
	game.get_child(0).refresh()
	overlay.time = t
	overlay.scene_index = scene_index
	overlay.local_time = local
	overlay.scene_duration = CUTS[scene_index + 1] - CUTS[scene_index]
	overlay.queue_redraw()
	frame += 1
	return false
