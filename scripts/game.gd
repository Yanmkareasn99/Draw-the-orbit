extends Node2D

const Route = preload("res://scripts/route.gd")
const GameView = preload("res://scripts/game_view.gd")
const CENTER := Vector2(465, 410)
const ARENA := Rect2(28, 104, 874, 628)
const BUDGET := 1550.0
const BARRIER_LIFETIME := 5.0
const BARRIER_HALF_WIDTH := 2.0
const MAX_TRAVEL_PER_STEP := 4.0
const UFO_RECOVERY_TIME := 10.0
const UFO_TURN_RATE := 2.4
const UFO_RADIUS := 9.0
const MIN_PLANET_OPENING := PI / 3.0
const ROUND_TIME := 90.0
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
var health := 5
var score := 0
var hits := 0
var redraws := 0
var message := "Draw a barrier. Crash the alien UFOs into each other."
var message_time := 0.0
var flash := 0.0
var start_button := Rect2(414, 547, 372, 58)
var pause_button := Rect2(1050, 28, 118, 44)

func _ready() -> void:
	rng.seed = 13829
	for i in range(150):
		stars.append(Vector2(rng.randf_range(30, 900), rng.randf_range(110, 730)))
	rng.randomize()
	add_child(GameView.new(self))

func start_round() -> void:
	barriers.clear()
	hazards.clear()
	sparks.clear()
	popups.clear()
	sketch.clear()
	drawing = false
	elapsed = 0.0
	spawn_clock = 2.0
	health = 5
	score = 0
	hits = 0
	redraws = 0
	flash = 0.0
	state = "playing"
	notify("Crash UFOs together! Leave a wide opening to the planet; enclosing shields cannot activate.")

func notify(value: String) -> void:
	message = value
	message_time = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		state = "paused"
		drawing = false
		sketch.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and state in ["menu", "won", "lost"]:
			start_round()
		elif event.keycode == KEY_R and state != "menu":
			start_round()
		elif event.keycode in [KEY_P, KEY_ESCAPE] and state in ["playing", "paused"]:
			state = "paused" if state == "playing" else "playing"
			drawing = false
			sketch.clear()
	if event is InputEventMouseButton:
		var point := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			drawing = false
			sketch.clear()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and state in ["menu", "won", "lost", "paused"]:
				if start_button.has_point(point):
					if state == "paused":
						state = "playing"
					else:
						start_round()
				return
			if event.pressed and pause_button.has_point(point) and state == "playing":
				state = "paused"
				drawing = false
				sketch.clear()
				return
			if state == "playing":
				if event.pressed and ARENA.has_point(point):
					begin_sketch(point)
				elif not event.pressed and drawing:
					append_sketch_point(point)
					finish_sketch()
	if event is InputEventMouseMotion and drawing and state == "playing":
		append_sketch_point(get_global_mouse_position())

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
		notify("Not enough ink. Wait for a barrier to disappear (next in %.1fs)." % next_barrier_expiry())
		return
	drawing = true
	sketch = PackedVector2Array([point])

func append_sketch_point(point: Vector2) -> void:
	point = point.clamp(ARENA.position, ARENA.end)
	if sketch[-1].distance_to(point) >= 6.0:
		var remaining := available_ink() - Route.length_of(sketch)
		if remaining > 0.5:
			sketch.append(sketch[-1].move_toward(point, remaining))

func sketch_error() -> String:
	if Route.length_of(sketch) > available_ink() + 0.001:
		return "Not enough ink - wait for a barrier to disappear"
	var error := Route.validate_barrier(sketch, CENTER, 58.0, available_ink() + 0.001)
	if error != "":
		return error
	var paths: Array[PackedVector2Array] = [sketch]
	for barrier in barriers:
		paths.append(barrier.points)
	if Route.largest_planet_opening(paths, CENTER, UFO_RADIUS + BARRIER_HALF_WIDTH) < MIN_PLANET_OPENING:
		return "Leave a wider opening to the planet (at least 60 degrees)"
	return ""

func finish_sketch() -> void:
	drawing = false
	var error := sketch_error()
	if error != "":
		notify(error + " - active barriers kept.")
	else:
		barriers.append({"points": sketch.duplicate(), "length": Route.length_of(sketch), "life": BARRIER_LIFETIME})
		redraws += 1
		notify("Barrier active for 5 seconds. %.0f px ink available." % available_ink())
	sketch.clear()

func spawn_attack() -> void:
	var phase := int(elapsed / 15.0) % 3
	var angle := rng.randf_range(0, TAU)
	var count := 2 if elapsed < 30.0 else 3
	for i in range(count):
		var direction := angle + (i * 0.15 if phase == 0 else i * PI if phase == 1 else i * 2.1)
		var unit := Vector2.from_angle(direction)
		var edge := minf(420.0 / maxf(absf(unit.x), 0.001), 290.0 / maxf(absf(unit.y), 0.001))
		var pos := CENTER + unit * edge
		var speed := rng.randf_range(32, 43) + elapsed * 0.22
		hazards.append({"pos": pos, "vel": (CENTER - pos).normalized() * speed, "warmup": 1.2, "radius": UFO_RADIUS, "redirected": false, "recovery": 0.0, "look": (phase + i) % 3})

func burst(pos: Vector2, color: Color) -> void:
	for i in range(10):
		sparks.append({"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(25, 130), "life": 0.5, "color": color})

func _physics_process(delta: float) -> void:
	if state == "playing":
		elapsed += delta
		message_time = maxf(0, message_time - delta)
		flash = maxf(0, flash - delta)
		step_world(delta)
		spawn_clock -= delta
		if state == "playing" and spawn_clock <= 0:
			spawn_attack()
			spawn_clock = maxf(2.3, 4.5 - elapsed * 0.02)
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
		if elapsed >= ROUND_TIME and state == "playing":
			state = "won"
			drawing = false
			sketch.clear()

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
		var best := INF
		for barrier in barriers:
			var candidate := Route.nearest(barrier.points, h.pos)
			var distance: float = h.pos.distance_squared_to(candidate.point)
			if distance < best:
				best = distance
				nearest = candidate
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
			h.vel = h.vel.bounce(normal)
			h.redirected = true
			h.recovery = UFO_RECOVERY_TIME
			burst(closest, CYAN)

func steer_ufo(h: Dictionary, dt: float) -> void:
	if not h.get("redirected", false):
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
				popups.append({"pos": (a.pos + b.pos) * 0.5 + Vector2(0, -20), "text": "+200  BONK!", "color": GOLD, "life": 1.0})
				hits += 2
				score += 200
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
			health -= 1
			popups.append({"pos": CENTER + Vector2(0, -54), "text": "OUCH!", "color": RED, "life": 1.0})
			flash = 0.4
			if health <= 0:
				state = "lost"
				drawing = false
				sketch.clear()
				return

