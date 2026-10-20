extends Node2D

const Route = preload("res://scripts/route.gd")
const GameView = preload("res://scripts/game_view.gd")
const CENTER := Vector2(465, 410)
const BASE_ARENA := Rect2(28, 104, 874, 628)
var ARENA := BASE_ARENA
const BUDGET := 1550.0
const BARRIER_LIFETIME := 5.0
const BARRIER_HALF_WIDTH := 2.0
const MAX_TRAVEL_PER_STEP := 4.0
const UFO_RECOVERY_TIME := 10.0
const UFO_TURN_RATE := 2.4
const UFO_RADIUS := 9.0
const MAX_UFOS := 48
const MAX_BASE_SPEED := 78.0
const CROWD_SLOWDOWN_AT := 20
const CROWD_SPAWN_MULTIPLIER := 2.5
const MAX_HEALTH := 5
const HEALTH_PICKUP_RADIUS := 22.0
const HEALTH_PICKUP_LIFETIME := 9.0
const HEALTH_PICKUP_FIRST_MIN := 18.0
const HEALTH_PICKUP_FIRST_MAX := 28.0
const HEALTH_PICKUP_REPEAT_MIN := 20.0
const HEALTH_PICKUP_REPEAT_MAX := 34.0
const BOMB_KILLS_REQUIRED := 10
const BOMB_RADIUS := 270.0
const BOMB_FLASH_TIME := 0.7
const UFO_TYPES := {
	"saucer": {"speed": 1.0, "radius": 9.0, "damage": 1, "look": 0},
	"scout": {"speed": 1.55, "radius": 7.0, "damage": 1, "look": 1},
	"weaver": {"speed": 1.1, "radius": 9.0, "damage": 1, "look": 2},
	"brute": {"speed": 0.72, "radius": 15.0, "damage": 2, "look": 3},
}
const BarrierMotion = preload("res://scripts/barrier_motion.gd")
const CYAN := Color("64eadb")
const GOLD := Color("ffce79")
const RED := Color("ff748c")
const WHITE := Color("e5edf8")
const MUTED := Color("879ab8")
var barriers: Array[Dictionary] = []
var sketch := PackedVector2Array()
var drawing := false
var hazards: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var stars := PackedVector2Array()
var rng := RandomNumberGenerator.new()
var state := "menu"
var elapsed := 0.0
var spawn_clock := 1.5
var wave := 0
var health := MAX_HEALTH
var health_pickup: Dictionary = {}
var health_pickup_clock := HEALTH_PICKUP_FIRST_MIN
var score := 0
var highest_score := 0
var score_save_path := "user://highest_score.cfg"
var hits := 0
var space_bombs := 0
var bomb_flash := 0.0
var redraws := 0
var message := ""
var message_time := 0.0
var flash := 0.0
var start_button := Rect2(414, 506, 372, 58)
var pause_button := Rect2(1050, 28, 118, 44)
var bomb_button := Rect2()
var active_touch_index := -1
var world_transform := Transform2D.IDENTITY
var screen_arena := ARENA
var layout_size := Vector2.ZERO
var compact_layout := false
var portrait_layout := false
var hud_rect := Rect2()
var restart_button := Rect2()
var hud_cards: Dictionary = {}
var overlay_card := Rect2()
var overlay_text := ""
var ui_font := SystemFont.new()
var toolbar_rect := Rect2()
var hud_slim := false
var hud_tiny := false
var hud_font_size := 14
const TOOLBAR_HEIGHT := 60.0
var mobile_landscape_only := false
var orientation_blocked := false

func _init() -> void:
	ui_font.font_names = PackedStringArray(["Trebuchet MS", "Verdana"])
	ui_font.font_weight = 700

func _ready() -> void:
	mobile_landscape_only = OS.has_feature("android") or OS.has_feature("ios")
	if OS.has_feature("web"):
		mobile_landscape_only = bool(JavaScriptBridge.eval("window.orbitMobile === true"))
	load_highest_score()
	# Let the window finish updating its physical viewport before changing scale.
	get_window().size_changed.connect(configure_viewport, CONNECT_DEFERRED)
	configure_viewport()
	rng.seed = 13829
	for i in range(150):
		stars.append(Vector2(rng.randf_range(30, 900), rng.randf_range(110, 730)))
	rng.randomize()
	add_child(GameView.new(self))
	update_layout(get_viewport_rect().size)

func configure_viewport() -> void:
	# Layout in CSS pixels on the web, independent of the phone's pixel density.
	var logical_size := Vector2(get_window().size)
	if OS.has_feature("web"):
		var css_size = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify([document.getElementById('canvas').clientWidth, document.getElementById('canvas').clientHeight])")))
		if css_size != null and css_size[0] > 0 and css_size[1] > 0:
			logical_size = Vector2(css_size[0], css_size[1])
	elif OS.has_feature("android") or OS.has_feature("ios"):
		logical_size /= maxf(1.0, DisplayServer.screen_get_dpi() / 160.0)
	logical_size /= maxf(1.0, minf(logical_size.x / 1200.0, logical_size.y / 800.0))
	if get_window().content_scale_size != Vector2i(logical_size):
		get_window().content_scale_size = Vector2i(logical_size)
	update_layout(logical_size)

func update_layout(viewport_size: Vector2) -> void:
	if layout_size != Vector2.ZERO and not layout_size.is_equal_approx(viewport_size):
		cancel_sketch()
	layout_size = viewport_size
	compact_layout = viewport_size.x < 1100.0 or viewport_size.y < 740.0
	portrait_layout = viewport_size.y > viewport_size.x
	orientation_blocked = mobile_landscape_only and viewport_size.y >= viewport_size.x
	if orientation_blocked:
		cancel_sketch()
		if state == "playing":
			state = "paused"
	var w := viewport_size.x
	var h := viewport_size.y
	toolbar_rect = Rect2(0, h - TOOLBAR_HEIGHT, w, TOOLBAR_HEIGHT)
	var play_size := Vector2(w, maxf(1, h - TOOLBAR_HEIGHT))
	var angle := PI / 2.0 if portrait_layout else 0.0
	var oriented_size := Vector2(BASE_ARENA.size.y, BASE_ARENA.size.x) if portrait_layout else BASE_ARENA.size
	var factor := minf(play_size.x / oriented_size.x, play_size.y / oriented_size.y)
	world_transform = Transform2D(angle, Vector2.ONE * factor, 0.0, Vector2.ZERO)
	world_transform.origin = play_size * 0.5 - world_transform * CENTER
	screen_arena = Rect2(Vector2.ZERO, play_size)
	# Expand the world to the window edges, preserving uniform art/physics scale.
	var a := screen_to_world(Vector2.ZERO)
	var b := screen_to_world(play_size)
	ARENA = Rect2(a.min(b), (a - b).abs())
	update_hud_layout(w)
	overlay_text = "PAUSED" if state == "paused" else "GAME OVER  /  %s  /  %d pts" % [survival_time(), score] if state == "lost" else "Draw barriers. Crash UFOs."
	var action := "RESUME" if state == "paused" else "RETRY" if state == "lost" else "PLAY"
	var button_width := ui_width(action, 16) + 48
	var restart_width := ui_width("RESTART", 14) + 44
	var extra_width := restart_width + 6 if state == "paused" else 0.0
	var panel_width := minf(w - 32, ui_width(overlay_text) + 32)
	var center := viewport_size * 0.5
	var left := (w - button_width - extra_width) * 0.5
	overlay_card = Rect2(Vector2((w - panel_width) * 0.5, center.y - 52), Vector2(panel_width, 44))
	restart_button = Rect2(left, center.y + 8, restart_width, 44)
	start_button = Rect2(left + extra_width, center.y + 8, button_width, 44)
	if state == "menu":
		var unit := title_scale()
		var button_size := Vector2(clampf(220 * unit, 160, 300), clampf(56 * unit, 44, 68))
		start_button = Rect2(Vector2(w * 0.5 - button_size.x * 0.5, title_center().y + 178 * unit), button_size)

func title_scale() -> float:
	return minf(layout_size.x / 440.0, layout_size.y / 680.0)

func title_center() -> Vector2:
	return layout_size * 0.5 + Vector2(0, 20 * title_scale())

func ui_width(value: String, size: int = 14) -> float:
	return ceilf(ui_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)

func hud_text(key: String) -> String:
	match key:
		"time": return survival_time()
		"score": return "SCORE %d" % score
		"best": return "BEST %d" % highest_score
		"ink":
			var pending := Route.length_of(sketch) if drawing else 0.0
			return "INK %.0f%%" % (maxf(0.0, available_ink() - pending) / BUDGET * 100.0)
	return ""

func update_hud_layout(width: float) -> void:
	hud_cards.clear()
	hud_slim = width < 700
	hud_tiny = width < 500
	hud_font_size = 10 if hud_tiny else 12 if hud_slim else 14
	var keys := ["time", "score", "best", "health", "ink"]
	var widths: Array[float] = []
	var total := 0.0
	var bomb_width := 50.0 if hud_tiny else 62.0 if hud_slim else 82.0
	while true:
		widths.clear()
		total = 44 + bomb_width + 6 * 4
		for key in keys:
			var card_width := (28.0 if hud_tiny else 36.0 if hud_slim else 108.0) if key == "health" else ui_width(hud_value(key) if hud_slim else hud_text(key), hud_font_size) + (8 if hud_tiny else 16)
			widths.append(card_width)
			total += card_width
		if total <= width - 16 or hud_font_size <= (7 if hud_tiny else 9):
			break
		hud_font_size -= 1
	var left := (width - total) * 0.5
	var middle := toolbar_rect.get_center().y
	var card_height := 40.0 if hud_slim else 32.0
	for i in range(keys.size()):
		hud_cards[keys[i]] = Rect2(left, middle - card_height * 0.5, widths[i], card_height)
		left += widths[i] + 4
	bomb_button = Rect2(left, middle - 22, bomb_width, 44)
	left += bomb_width + 4
	pause_button = Rect2(left, middle - 22, 44, 44)
	hud_rect = Rect2((width - total) * 0.5, middle - 22, total, 44)

func hud_value(key: String) -> String:
	if key == "time":
		return survival_time()
	if key == "ink":
		return hud_text(key).trim_prefix("INK ")
	var value := highest_score if key == "best" else score
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (value / 1000.0)
	return str(value)

func hud_has_point(point: Vector2) -> bool:
	if toolbar_rect.has_point(point):
		return true
	for rect: Rect2 in hud_cards.values():
		if rect.grow(2).has_point(point):
			return true
	return bomb_button.has_point(point) or pause_button.has_point(point)

func screen_to_world(point: Vector2) -> Vector2:
	return world_transform.affine_inverse() * point

func load_highest_score() -> void:
	if score_save_path.is_empty():
		return
	var save := ConfigFile.new()
	if save.load(score_save_path) == OK:
		var value = save.get_value("scores", "highest", 0)
		if value is int and value >= 0:
			highest_score = maxi(highest_score, value)

func award_points(points: int) -> void:
	score += points
	if score <= highest_score:
		return
	highest_score = score
	if score_save_path.is_empty():
		return
	var save := ConfigFile.new()
	save.set_value("scores", "highest", highest_score)
	var error := save.save(score_save_path)
	if error != OK:
		push_warning("Could not save highest score: %s" % error_string(error))

func register_ufo_destructions(count: int) -> void:
	var previous_rewards := hits / BOMB_KILLS_REQUIRED
	hits += count
	var earned := hits / BOMB_KILLS_REQUIRED - previous_rewards
	if earned > 0:
		space_bombs += earned
		notify("SPACE BOMB READY!")

func bomb_progress_text() -> String:
	if space_bombs > 0:
		return "x%d" % space_bombs
	return "%d/%d" % [hits % BOMB_KILLS_REQUIRED, BOMB_KILLS_REQUIRED]

func use_space_bomb() -> bool:
	if state != "playing" or space_bombs <= 0:
		if state == "playing":
			notify("Destroy %d more UFOs" % (BOMB_KILLS_REQUIRED - hits % BOMB_KILLS_REQUIRED))
		return false
	cancel_sketch()
	space_bombs -= 1
	bomb_flash = BOMB_FLASH_TIME
	var destroyed := 0
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if CENTER.distance_to(h.pos) <= BOMB_RADIUS + h.radius:
			burst(h.pos, GOLD)
			hazards.remove_at(i)
			destroyed += 1
	if destroyed > 0:
		register_ufo_destructions(destroyed)
		award_points(destroyed * 100)
		popups.append({"pos": CENTER + Vector2(0, -72), "text": "+%d" % (destroyed * 100), "color": GOLD, "life": 1.0})
	else:
		notify("SPACE BOMB DEPLOYED")
	return true

func start_round() -> void:
	barriers.clear()
	hazards.clear()
	sparks.clear()
	popups.clear()
	sketch.clear()
	drawing = false
	active_touch_index = -1
	elapsed = 0.0
	spawn_clock = 2.0
	wave = 0
	health = MAX_HEALTH
	health_pickup.clear()
	health_pickup_clock = rng.randf_range(HEALTH_PICKUP_FIRST_MIN, HEALTH_PICKUP_FIRST_MAX)
	score = 0
	hits = 0
	space_bombs = 0
	bomb_flash = 0.0
	redraws = 0
	flash = 0.0
	state = "playing"
	message = ""
	message_time = 0.0

func notify(value: String) -> void:
	message = value
	message_time = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		state = "paused"
		cancel_sketch()

func cancel_sketch() -> void:
	drawing = false
	active_touch_index = -1
	sketch.clear()

func handle_primary_press(point: Vector2) -> void:
	if layout_size != Vector2.ZERO:
		update_layout(layout_size)
	if orientation_blocked:
		return
	if state in ["menu", "lost", "paused"]:
		if state == "paused" and restart_button.has_point(point):
			start_round()
			return
		if start_button.has_point(point):
			if state == "paused":
				state = "playing"
			else:
				start_round()
			return
	if pause_button.has_point(point) and state == "playing":
		state = "paused"
		cancel_sketch()
		return
	if bomb_button.has_point(point) and state == "playing":
		use_space_bomb()
		return
	if state == "playing" and collect_health_pickup(point):
		return
	if state == "playing" and screen_arena.has_point(point) and not hud_has_point(point):
		begin_sketch(screen_to_world(point))

func handle_touch_press(point: Vector2, index: int) -> void:
	if active_touch_index != -1 and active_touch_index != index:
		if state == "playing" and drawing:
			cancel_sketch()
			message_time = 0.0
		return
	handle_primary_press(point)
	if state == "playing" and drawing and active_touch_index == -1:
		active_touch_index = index

func handle_touch_release(point: Vector2, index: int) -> void:
	if index != active_touch_index:
		return
	if state == "playing" and drawing:
		append_sketch_point(screen_to_world(point))
		if drawing:
			finish_sketch()
	active_touch_index = -1

func _input(event: InputEvent) -> void:
	if orientation_blocked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and state in ["menu", "lost"]:
			start_round()
		elif event.keycode == KEY_R and state != "menu":
			start_round()
		elif event.keycode in [KEY_P, KEY_ESCAPE] and state in ["playing", "paused"]:
			state = "paused" if state == "playing" else "playing"
			cancel_sketch()
		elif event.keycode == KEY_B and state == "playing":
			use_space_bomb()
	if event is InputEventScreenTouch:
		var touch_point: Vector2 = event.position
		if event.canceled:
			if event.index == active_touch_index:
				cancel_sketch()
		elif event.pressed:
			handle_touch_press(touch_point, event.index)
		else:
			handle_touch_release(touch_point, event.index)
	if event is InputEventScreenDrag and state == "playing" and drawing and event.index == active_touch_index:
		append_sketch_point(screen_to_world(event.position))
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and active_touch_index == -1:
		var point: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_sketch()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				handle_primary_press(point)
			elif drawing and active_touch_index == -1:
				append_sketch_point(screen_to_world(point))
				if drawing:
					finish_sketch()
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and active_touch_index == -1 and drawing and state == "playing":
		append_sketch_point(screen_to_world(event.position))

func active_barrier_length() -> float:
	var used := 0.0
	for barrier in barriers:
		used += barrier.length
	return used

func available_ink() -> float:
	return maxf(0.0, BUDGET - active_barrier_length())

func next_barrier_expiry() -> float:
	var next := BARRIER_LIFETIME
	for barrier in barriers:
		next = minf(next, barrier.life)
	return next

func begin_sketch(point: Vector2) -> void:
	if available_ink() < Route.MIN_BARRIER_LENGTH:
		notify("Ink refills in %.1fs" % next_barrier_expiry())
		return
	drawing = true
	sketch = PackedVector2Array([point])

func append_sketch_point(point: Vector2) -> void:
	if hud_has_point(world_transform * point):
		cancel_sketch()
		return
	point = point.clamp(ARENA.position, ARENA.end)
	if sketch[-1].distance_to(point) >= 6.0:
		var remaining := available_ink() - Route.length_of(sketch)
		if remaining > 0.5:
			sketch.append(sketch[-1].move_toward(point, remaining))

func sketch_error() -> String:
	if Route.length_of(sketch) > available_ink() + 0.001:
		return "Not enough ink"
	var error := Route.validate_barrier(sketch, CENTER, 58.0, available_ink() + 0.001)
	if error != "":
		return error
	var paths: Array[PackedVector2Array] = [sketch]
	for barrier in barriers:
		paths.append(barrier.points)
	if Route.planet_is_enclosed(paths, CENTER):
		return "Leave a gap"
	return ""

func finish_sketch() -> void:
	drawing = false
	var error := sketch_error()
	if error != "":
		notify(error)
	else:
		var barrier := {"points": sketch.duplicate(), "length": Route.length_of(sketch), "life": BARRIER_LIFETIME}
		BarrierMotion.prepare(barrier)
		barriers.append(barrier)
		redraws += 1
		message_time = 0.0
	sketch.clear()

func survival_time() -> String:
	var seconds := int(elapsed)
	if seconds >= 3600:
		return "%d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func make_ufo(kind: String, pos: Vector2, base_speed: float) -> Dictionary:
	var stats: Dictionary = UFO_TYPES[kind]
	return {"type": kind, "pos": pos, "vel": (CENTER - pos).normalized() * base_speed * stats.speed,
		"warmup": 1.2, "radius": stats.radius, "damage": stats.damage, "look": stats.look,
		"redirected": false, "recovery": 0.0, "flight_time": 0.0, "weave_phase": rng.randf_range(0, TAU)}

func spawn_attack() -> void:
	if hazards.size() >= MAX_UFOS:
		return
	wave += 1
	var phase := int(elapsed / 15.0) % 3
	var angle := rng.randf_range(0, TAU)
	var count := mini(2 + int(minf(elapsed, 180.0) / 60.0), MAX_UFOS - hazards.size())
	var types := ["saucer"]
	if elapsed >= 10.0:
		types.append("scout")
	if elapsed >= 25.0:
		types.append("weaver")
	if elapsed >= 45.0:
		types.append("brute")
	for i in range(count):
		var direction := angle + (i * 0.15 if phase == 0 else (i % 2) * PI + (i / 2) * 0.18 if phase == 1 else i * TAU / count)
		var unit := Vector2.from_angle(direction)
		var extent := ARENA.size * 0.5 - Vector2(24, 24)
		var edge := minf(extent.x / maxf(absf(unit.x), 0.001), extent.y / maxf(absf(unit.y), 0.001))
		var pos := CENTER + unit * edge
		var speed := minf(MAX_BASE_SPEED, rng.randf_range(32, 43) + elapsed * 0.16)
		hazards.append(make_ufo(types[(wave + i - 1) % types.size()], pos, speed))

func next_spawn_delay() -> float:
	var delay := maxf(2.3, 4.5 - elapsed * 0.02)
	if hazards.size() >= CROWD_SLOWDOWN_AT:
		delay *= CROWD_SPAWN_MULTIPLIER
	return delay

func reset_health_pickup_clock() -> void:
	health_pickup_clock = rng.randf_range(HEALTH_PICKUP_REPEAT_MIN, HEALTH_PICKUP_REPEAT_MAX)

func spawn_health_pickup() -> void:
	var area := ARENA.grow(-HEALTH_PICKUP_RADIUS - 12.0)
	var at := area.get_center()
	for attempt in range(16):
		at = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var clear_of_ufos := true
		for h in hazards:
			if at.distance_to(h.pos) < HEALTH_PICKUP_RADIUS + h.radius + 28.0:
				clear_of_ufos = false
				break
		if at.distance_to(CENTER) > 105.0 and clear_of_ufos:
			break
	health_pickup = {"pos": at, "life": HEALTH_PICKUP_LIFETIME}

func advance_health_pickup(delta: float) -> void:
	if not health_pickup.is_empty():
		health_pickup.life -= delta
		if health_pickup.life <= 0.0:
			health_pickup.clear()
			reset_health_pickup_clock()
		return
	health_pickup_clock = maxf(0.0, health_pickup_clock - delta)
	if health_pickup_clock <= 0.0 and health < MAX_HEALTH:
		spawn_health_pickup()

func collect_health_pickup(screen_point: Vector2) -> bool:
	if health_pickup.is_empty():
		return false
	var at: Vector2 = health_pickup.pos
	if screen_to_world(screen_point).distance_to(at) > HEALTH_PICKUP_RADIUS * 1.35:
		return false
	if health >= MAX_HEALTH:
		notify("Health is full")
		return true
	health = mini(MAX_HEALTH, health + 1)
	health_pickup.clear()
	reset_health_pickup_clock()
	burst(at, RED)
	popups.append({"pos": at + Vector2(0, -28), "text": "+1 HP", "color": RED, "life": 1.2})
	notify("PLANET REPAIRED!")
	return true

func burst(pos: Vector2, color: Color) -> void:
	for i in range(10):
		sparks.append({"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(25, 130), "life": 0.5, "color": color})

func _physics_process(delta: float) -> void:
	if orientation_blocked:
		return
	if state == "playing":
		elapsed += delta
		message_time = maxf(0, message_time - delta)
		flash = maxf(0, flash - delta)
		bomb_flash = maxf(0, bomb_flash - delta)
		step_world(delta)
		if state == "playing":
			advance_health_pickup(delta)
		spawn_clock -= delta
		if state == "playing" and spawn_clock <= 0:
			spawn_attack()
			spawn_clock = next_spawn_delay()
		for i in range(sparks.size() - 1, -1, -1):
			sparks[i].pos += sparks[i].vel * delta
			sparks[i].life -= delta
			if sparks[i].life <= 0:
				sparks.remove_at(i)
		for i in range(popups.size() - 1, -1, -1):
			popups[i].pos.y -= delta * 22.0
			popups[i].life -= delta
			if popups[i].life <= 0.0:
				popups.remove_at(i)

func step_world(dt: float) -> void:
	# Limit travel to less than a hazard radius, including during slow frames.
	var fastest := 0.0
	for h in hazards:
		fastest = maxf(fastest, h.vel.length())
	var steps := maxi(1, ceili(fastest * dt / MAX_TRAVEL_PER_STEP))
	for step in range(steps):
		age_barriers(dt / steps)
		step_hazards(dt / steps)
		if state != "playing":
			break

func age_barriers(dt: float) -> void:
	for i in range(barriers.size() - 1, -1, -1):
		BarrierMotion.advance(barriers[i], dt)
		barriers[i].life -= dt
		if barriers[i].life <= 0.00001:
			barriers.remove_at(i)

func reflect_hazard(h: Dictionary) -> void:
	if barriers.is_empty():
		return
	# Nearest contact handles both segment faces and rounded endpoints.
	# Repeat to separate a hazard from tight corners without a bounce cooldown.
	for contact in range(4):
		var nearest := {}
		var hit_barrier := {}
		var best := INF
		for barrier in barriers:
			var candidate := Route.nearest(barrier.points, h.pos)
			var distance: float = h.pos.distance_squared_to(candidate.point)
			if distance < best:
				best = distance
				nearest = candidate
				hit_barrier = barrier
		var closest: Vector2 = nearest.point
		var offset: Vector2 = h.pos - closest
		var clearance: float = h.radius + BARRIER_HALF_WIDTH
		if offset.length_squared() >= clearance * clearance:
			break
		var normal := offset.normalized()
		if normal.is_zero_approx():
			# A newly drawn barrier may pass exactly through a hazard center.
			normal = nearest.normal
			if h.vel.dot(normal) > 0.0:
				normal = -normal
		h.pos = closest + normal * (clearance + 0.05)
		if h.vel.dot(normal) < 0.0:
			BarrierMotion.impact(hit_barrier, nearest.distance, -normal, absf(h.vel.dot(normal)), h.radius / UFO_RADIUS)
			h.vel = h.vel.bounce(normal)
			h.redirected = true
			h.recovery = UFO_RECOVERY_TIME
			burst(closest, CYAN)

func steer_ufo(h: Dictionary, dt: float) -> void:
	if not h.get("redirected", false):
		if h.get("type", "saucer") == "weaver":
			h.flight_time += dt
			var target: Vector2 = CENTER - h.pos
			var heading := target.angle() + sin(h.flight_time * 3.4 + h.weave_phase) * 0.65
			var turn := clampf(angle_difference(h.vel.angle(), heading), -2.8 * dt, 2.8 * dt)
			h.vel = h.vel.rotated(turn)
		return
	# Preserve the reflected trajectory while the pilot is stunned. Only the
	# portion of this step after recovery contributes to the turn.
	var recovery: float = h.get("recovery", 0.0)
	h.recovery = maxf(0.0, recovery - dt)
	var steering_time := maxf(0.0, dt - recovery)
	var speed: float = h.vel.length()
	var target: Vector2 = CENTER - h.pos
	if steering_time <= 0.0 or speed <= 0.0 or target.is_zero_approx():
		return
	var turn := clampf(h.vel.angle_to(target), -UFO_TURN_RATE * steering_time, UFO_TURN_RATE * steering_time)
	h.vel = h.vel.rotated(turn).normalized() * speed

func keep_ufo_in_arena(h: Dictionary) -> void:
	# Keep stunned UFOs inside without shortening their recovery timer.
	var flight_area := ARENA.grow(-h.radius - 3.0)
	var bounded: Vector2 = h.pos.clamp(flight_area.position, flight_area.end)
	if not h.pos.is_equal_approx(bounded):
		if h.get("recovery", 0.0) > 0.0:
			if (h.pos.x - bounded.x) * h.vel.x > 0.0:
				h.vel.x = -h.vel.x
			if (h.pos.y - bounded.y) * h.vel.y > 0.0:
				h.vel.y = -h.vel.y
		else:
			h.vel = (CENTER - bounded).normalized() * h.vel.length()
		h.pos = bounded

func step_hazards(dt: float) -> void:
	for h in hazards:
		if h.warmup > 0.0:
			h.warmup = maxf(0.0, h.warmup - dt)
			continue
		steer_ufo(h, dt)
		h.pos += h.vel * dt
		reflect_hazard(h)
		keep_ufo_in_arena(h)
	# Resolve pairs after all hazards move so array order cannot change motion.
	var destroyed := {}
	for i in range(hazards.size()):
		var a: Dictionary = hazards[i]
		if destroyed.has(i) or a.warmup > 0.0:
			continue
		for j in range(i + 1, hazards.size()):
			var b: Dictionary = hazards[j]
			if destroyed.has(j) or b.warmup > 0.0:
				continue
			if not (a.get("redirected", false) or b.get("redirected", false)):
				continue
			if a.pos.distance_to(b.pos) <= a.radius + b.radius:
				destroyed[i] = true
				destroyed[j] = true
				burst((a.pos + b.pos) * 0.5, GOLD)
				popups.append({"pos": (a.pos + b.pos) * 0.5 + Vector2(0, -20), "text": "+200", "color": GOLD, "life": 1.0})
				register_ufo_destructions(2)
				award_points(200)
				break
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if destroyed.has(i):
			hazards.remove_at(i)
			continue
		if h.warmup > 0.0:
			continue
		if CENTER.distance_to(h.pos) < 38.0 + h.radius:
			burst(h.pos, RED)
			hazards.remove_at(i)
			var damage: int = h.get("damage", 1)
			health = maxi(0, health - damage)
			popups.append({"pos": CENTER + Vector2(0, -54), "text": "-%d" % damage, "color": RED, "life": 1.0})
			flash = 0.4
			if health <= 0:
				state = "lost"
				drawing = false
				sketch.clear()
				return
