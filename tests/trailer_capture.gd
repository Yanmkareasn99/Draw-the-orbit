extends SceneTree
## Staged live combat: editorial speed ramps, real collisions, no idle holds.
const Game = preload("res://scripts/game.gd")
const Promo = preload("res://tests/trailer_overlay.gd")
const Timeline = preload("res://tests/trailer_timeline.gd")
var game: Node2D
var overlay: Node2D
var frame := 0
var scene_index := -1
var started := false
var cuts: Array[float] = [0.0]
var guide := PackedVector2Array()
var action_anchor := Vector2(180, 300)
var bomb_done := false
var healed := false
var wave_returned := false
var next_pair := 0.0
var shake := 0.0
var scene_bonks := 0
var total_bonks := 0
var empty_frames := 0
var density := 6
var output_scale := 6.0

func _initialize() -> void:
	var elapsed := 0.25
	for shot in Timeline.SHOTS:
		elapsed += shot.beats * Timeline.BEAT
		cuts.append(elapsed)
	call_deferred("setup")

func setup() -> void:
	var size := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	output_scale = size.x / 360.0
	root.size = size
	root.content_scale_size = size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game = Game.new()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.settings_save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.get_child(0).set_process(false)
	game.game_sound.set_process(false)
	game.game_sound.set_mix_volumes(0.0, 0.65)
	root.content_scale_size = size
	game.scale = Vector2.ONE * output_scale
	game.update_layout(Vector2(360, 640))
	game.rng.seed = 1042026
	game.set_language("en", false)
	overlay = Promo.new(game)
	overlay.scale = Vector2.ONE * output_scale
	root.add_child(overlay)
	started = true

func point(at: Vector2) -> Vector2:
	return game.screen_to_world(at)

func ship(at: Vector2, velocity: Vector2, kind: String = "saucer", redirected: bool = false) -> Dictionary:
	var h: Dictionary = game.make_ufo(kind, at, minf(72.0, velocity.length()))
	h.vel = velocity
	h.warmup = 0.0
	h.redirected = redirected
	h.recovery = 10.0 if redirected else 0.0
	game.hazards.append(h)
	game.total_ufos_spawned += 1
	return h

func moving_field(count: int, warning: float = 0.0) -> void:
	var types := ["saucer", "scout", "weaver", "brute", "dodger", "phantom"]
	for i in range(count):
		var angle := i * TAU / count + scene_index * 0.47
		var radial := Vector2.from_angle(angle)
		var at: Vector2 = game.CENTER + radial * (210 + (i % 3) * 35)
		var direction := radial.orthogonal() * (-1 if i % 2 == 0 else 1) - radial * 0.18
		var h := ship(at, direction.normalized() * (54 + i % 4 * 8), types[(i + scene_index) % types.size()])
		h.warmup = warning

func collision_pair(at: Vector2, close: bool = false) -> void:
	var distance := 14.0 if close else 23.0
	var a := point(at - Vector2(distance, 0))
	var b := point(at + Vector2(distance, 0))
	ship(a, (b - a).normalized() * 180, "saucer", true)
	ship(b, (a - b).normalized() * 30, "scout")

func barrier_action(animated: bool) -> void:
	guide = PackedVector2Array([point(action_anchor + Vector2(-55, 0)), point(action_anchor + Vector2(55, 0))])
	if animated:
		game.begin_sketch(guide[0])
	else:
		game.sketch = guide.duplicate()
		game.finish_sketch()
	var mid: Vector2 = point(action_anchor)
	var tangent := (guide[1] - guide[0]).normalized()
	var outward := (point(action_anchor + Vector2(0, -20)) - mid).normalized()
	var clearance: float = game.UFO_RADIUS + game.BARRIER_HALF_WIDTH
	var gap := 32.0 if animated else 8.0
	var direction := (tangent * 0.65 - outward * 0.76).normalized()
	var at: Vector2 = mid + outward * (clearance + gap) - tangent * 20
	ship(at, direction * 72)
	var time_to_contact := gap / (-direction.dot(outward) * 72)
	var contact := at + direction * 72 * time_to_contact + outward * 0.05
	ship(contact + direction.bounce(outward) * 62, Vector2.ZERO)

func enter_scene(index: int) -> void:
	if scene_index >= 0:
		print("SHOT_RESULT ", scene_index + 1, " bonks=", game.bonks - scene_bonks, " actors=", game.hazards.size())
		total_bonks = game.bonks
	scene_index = index
	var kind: String = Timeline.SHOTS[index].kind
	game.start_round(5 if kind in ["boss", "finisher"] else 4)
	game.elapsed = 20 + index % 40
	game.spawn_clock = 100.0
	game.highest_bonks = maxi(32, total_bonks)
	game.bonks = total_bonks
	game.hits = total_bonks * 2
	game.total_ufos_spawned = total_bonks * 2 + 12
	game.space_bombs = 1
	game.bomb_bonk_progress = 4
	scene_bonks = game.bonks
	density = 6 + int(index / float(Timeline.SHOTS.size()) * 12)
	action_anchor = [Vector2(112, 195), Vector2(247, 365), Vector2(112, 385), Vector2(247, 190)][index % 4]
	bomb_done = false
	healed = false
	wave_returned = false
	shake = 0.0
	next_pair = 0.8
	moving_field(density)
	match kind:
		"draw", "bounce":
			barrier_action(kind == "draw")
			collision_pair(Vector2(250 if action_anchor.x < 180 else 100, 360 if action_anchor.y < 260 else 190))
		"chain", "swarm":
			collision_pair(action_anchor, true)
			collision_pair(Vector2(360 - action_anchor.x, 560 - action_anchor.y))
			if kind == "swarm":
				barrier_action(false)
		"bomb":
			collision_pair(action_anchor, true)
		"heal":
			game.health = 4
			game.flash = 0.25
			game.health_pickup = {"pos": point(Vector2(260, 305)), "life": 9.0}
			collision_pair(action_anchor, true)
		"boss", "finisher":
			game.boss.health = 2 if kind == "finisher" else 12
			game.boss.clock = 0.1
			for i in range(5):
				var at: Vector2 = game.boss.pos + Vector2(68 + i * 22, -18 + i * 8)
				ship(at, (game.boss.pos - at).normalized() * 180, "saucer", true)
		"cta":
			collision_pair(Vector2(110, 380), true)
			collision_pair(Vector2(250, 190))
	game.update_layout(Vector2(360, 640))
	print("SHOT ", index + 1, " ", kind, " at=", frame / 30.0, " beats=", Timeline.SHOTS[index].beats)

func _process(_delta: float) -> bool:
	if not started:
		return false
	var t := frame / 30.0
	if t >= cuts[-1]:
		print("CAPTURE_COMPLETE empty_action_frames=", empty_frames, " total_bonks=", game.bonks)
		quit()
		return false
	var next := 0
	for i in range(Timeline.SHOTS.size()):
		if t >= cuts[i]:
			next = i
	if next != scene_index:
		enter_scene(next)
	var local: float = t - cuts[scene_index]
	var duration: float = cuts[scene_index + 1] - cuts[scene_index]
	var kind: String = Timeline.SHOTS[scene_index].kind
	var intensity := t / cuts[-1]
	var dt := (1.0 + intensity * 0.65) / 30.0
	if kind == "draw" and game.drawing:
		var progress := clampf(local / minf(0.3, duration * 0.28), 0, 1)
		game.append_sketch_point(guide[0].lerp(guide[1], progress))
		if progress >= 1.0:
			game.finish_sketch()
	if kind == "bomb":
		var trigger := 0.48 if duration > 2 else 0.12
		if local >= trigger and not bomb_done:
			game.use_space_bomb()
			bomb_done = true
			shake = 0.26
		if local > trigger + 0.32 and not wave_returned and duration > 1:
			moving_field(density, 0.15)
			collision_pair(Vector2(120, 355), true)
			wave_returned = true
	if kind == "heal" and local >= 0.28 and not healed:
		game.collect_health_pickup(game.world_transform * Vector2(game.health_pickup.pos))
		healed = true
	if local >= next_pair and duration > 1.4:
		collision_pair(Vector2(112 if int(next_pair * 10) % 2 == 0 else 248, 375 if next_pair < 1.5 else 185))
		next_pair += maxf(0.45, 0.85 - intensity * 0.4)
	var before: int = game.bonks
	game.advance_feedback(dt)
	game.advance_particles(dt)
	game.advance_boss(dt)
	game.step_world(dt)
	game.advance_health_pickup(dt)
	if game.hazards.is_empty() and game.bomb_flash < 0.1:
		moving_field(density, 0.1)
	if game.bonks > before:
		shake = maxf(shake, 0.16)
	if game.state != "playing":
		push_error("Trailer action stopped in shot %d: %s" % [scene_index + 1, game.state])
		quit(1)
		return false
	if game.hazards.is_empty() and game.sparks.is_empty() and game.shockwaves.is_empty() and game.bomb_flash <= 0 and not game.drawing:
		empty_frames += 1
	shake = maxf(0.0, shake - 1.0 / 30.0)
	game.update_layout(Vector2(360, 640))
	var view: Node2D = game.get_child(0)
	view.time = t * (1 + intensity * 0.5)
	view.refresh()
	var zoom := 1.03 + intensity * 0.12 + clampf(local / duration, 0, 1) * 0.05
	var pivot := Vector2(180, 285)
	var shift := Vector2(sin(t * 61), cos(t * 47)) * shake * (12 + intensity * 5)
	var camera := Transform2D(0.0, Vector2.ONE * zoom, 0.0, pivot * (1 - zoom) + shift)
	view.get_child(0).transform = camera * game.world_transform
	overlay.time = t
	overlay.scene_index = scene_index
	overlay.local_time = local
	overlay.scene_duration = duration
	overlay.intensity = intensity
	overlay.queue_redraw()
	frame += 1
	return false
