extends Node2D

const Route = preload("res://scripts/route.gd")
const CENTER := Vector2(465, 410)
const ARENA := Rect2(28, 104, 874, 628)
const BUDGET := 1550.0
const BARRIER_LIFETIME := 5.0
const BARRIER_HALF_WIDTH := 2.0
const MAX_TRAVEL_PER_STEP := 4.0
const UFO_RECOVERY_TIME := 10.0
const UFO_TURN_RATE := 2.4
const ROUND_TIME := 90.0
const CYAN := Color("64eadb")
const GOLD := Color("ffce79")
const RED := Color("ff748c")
const WHITE := Color("e5edf8")
const MUTED := Color("879ab8")
var font: Font = ThemeDB.fallback_font
var barriers: Array[Dictionary] = []
var sketch := PackedVector2Array()
var drawing := false
var hazards: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
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
var start_button := Rect2(354, 504, 250, 54)
var pause_button := Rect2(1050, 28, 118, 40)

func _ready() -> void:
	rng.seed = 13829
	for i in range(150):
		stars.append(Vector2(rng.randf_range(30, 900), rng.randf_range(110, 730)))
	rng.randomize()

func start_round() -> void:
	barriers.clear()
	hazards.clear()
	sparks.clear()
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
	notify("Crash UFOs together! Surviving aliens regain control and attack the planet again.")

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
	return Route.validate_barrier(sketch, CENTER, 58.0, available_ink() + 0.001)

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
		hazards.append({"pos": pos, "vel": (CENTER - pos).normalized() * speed, "warmup": 1.2, "radius": 9.0, "redirected": false, "recovery": 0.0})

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
		if elapsed >= ROUND_TIME and state == "playing":
			state = "won"
			drawing = false
			sketch.clear()
	queue_redraw()

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
			flash = 0.4
			if health <= 0:
				state = "lost"
				drawing = false
				sketch.clear()
				return

func draw_ufo(h: Dictionary) -> void:
	var p: Vector2 = h.pos
	var v: Vector2 = h.vel
	var recovering: bool = h.get("recovery", 0.0) > 0.0
	var color := CYAN if recovering else GOLD if h.get("redirected", false) else RED
	if h.warmup > 0.0:
		color = GOLD
		draw_arc(p, 18, 0, TAU, 24, GOLD, 1.5, true)
	else:
		draw_line(p, p + v * 0.8, Color(color, 0.5), 1.5, true)
		var exhaust := -v.normalized()
		draw_line(p + exhaust * 8, p + exhaust * (17.0 + sin(elapsed * 25.0 + p.x) * 3.0), Color(color, 0.7), 3, true)
		if recovering:
			draw_arc(p, 18, -PI / 2.0, -PI / 2.0 + TAU * h.recovery / UFO_RECOVERY_TIME, 24, CYAN, 1.5, true)
	draw_circle(p, 17, Color(color, 0.08))
	# Glass canopy, green alien pilot, and a metal saucer with running lights.
	draw_circle(p + Vector2(0, -4), 7, Color("224f67"))
	draw_arc(p + Vector2(0, -4), 7, PI, TAU, 16, Color("9eeef5"), 1.2, true)
	draw_circle(p + Vector2(0, -5), 4, Color("9cf082"))
	draw_line(p + Vector2(-3, -6), p + Vector2(-1, -4), Color("132934"), 1.5, true)
	draw_line(p + Vector2(3, -6), p + Vector2(1, -4), Color("132934"), 1.5, true)
	var hull := PackedVector2Array([p + Vector2(-13, 1), p + Vector2(-6, -2), p + Vector2(6, -2), p + Vector2(13, 1), p + Vector2(8, 6), p + Vector2(-8, 6)])
	draw_colored_polygon(hull, Color("536c85"))
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[5], hull[0]]), color, 1.2, true)
	for x in [-6, 0, 6]:
		draw_circle(p + Vector2(x, 3), 1.5, color)

func label_at(pos: Vector2, value: String, size: int = 16, color: Color = WHITE) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2, color: Color = Color("101c30")) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	draw_style_box(style, rect)

func _draw() -> void:
	panel(ARENA, Color("091323"))
	for i in range(stars.size()):
		draw_circle(stars[i], 1.2 if i % 5 == 0 else 0.65, Color(0.4, 0.57, 0.75, 0.4))
	for radius in [100, 200, 280]:
		draw_arc(CENTER, radius, 0, TAU, 100, Color(0.2, 0.4, 0.5, 0.12), 1, true)
	for barrier in barriers:
		var points: PackedVector2Array = barrier.points
		var opacity := clampf(barrier.life, 0.25, 1.0)
		var ink := Color(CYAN if barrier.life > 1.0 else GOLD, opacity)
		draw_polyline(points, Color(ink, opacity * 0.12), 12, true)
		draw_polyline(points, ink, BARRIER_HALF_WIDTH * 2.0, true)
		draw_circle(points[0], BARRIER_HALF_WIDTH, ink)
		draw_circle(points[-1], BARRIER_HALF_WIDTH, ink)
		label_at((points[0] + Vector2(8, -8)).clamp(ARENA.position + Vector2(4, 16), ARENA.end - Vector2(40, 4)), "%.1fs" % barrier.life, 12, ink)
	for h in hazards:
		draw_ufo(h)
	draw_circle(CENTER, 53, Color(0.2, 0.7, 1, 0.06))
	draw_circle(CENTER, 40, Color("184f74"))
	draw_circle(CENTER + Vector2(-10,-10), 23, Color("246d88"))
	draw_arc(CENTER, 43, 0, TAU, 64, CYAN if flash <= 0 else RED, 2, true)
	draw_arc(CENTER, 58, 0, TAU, 64, Color(0.4, 0.7, 0.8, 0.2), 1, true)
	for s in sparks:
		draw_circle(s.pos, 2, Color(s.color, s.life * 2.0))
	if drawing and sketch.size() > 1:
		var valid := sketch_error() == ""
		var ink := CYAN if valid else GOLD
		draw_polyline(sketch, ink, 3, true)
		draw_circle(sketch[0], 4, ink)
	label_at(Vector2(30, 46), "DRAW THE ORBIT", 27)
	label_at(Vector2(31, 73), "ALIEN UFO DEFENSE  /  DRAW, DEFLECT, DESTROY", 12, MUTED)
	panel(pause_button)
	label_at(Vector2(1070, 54), "Pause [P]", 15)
	panel(Rect2(922, 104, 250, 628))
	label_at(Vector2(944, 141), "MISSION STATUS", 13, MUTED)
	label_at(Vector2(944, 182), "%02d:%02d" % [int(maxf(0, ROUND_TIME-elapsed))/60, int(maxf(0, ROUND_TIME-elapsed))%60], 32)
	label_at(Vector2(944, 212), "remaining", 13, MUTED)
	label_at(Vector2(944, 257), "PLANET INTEGRITY", 13, MUTED)
	for i in range(5):
		draw_rect(Rect2(944 + i * 42, 272, 34, 9), CYAN if i < health else Color("27364b"))
	label_at(Vector2(944, 324), "%04d" % score, 29)
	label_at(Vector2(944, 349), "%d UFOs destroyed" % hits, 14, MUTED)
	label_at(Vector2(944, 400), "SHARED INK BUDGET", 13, MUTED)
	var active := active_barrier_length()
	var pending := Route.length_of(sketch) if drawing else 0.0
	var used := active + pending
	draw_rect(Rect2(944, 414, 206, 6), Color("27364b"))
	draw_rect(Rect2(944, 414, 206 * minf(active / BUDGET, 1), 6), CYAN)
	if pending > 0.0:
		draw_rect(Rect2(944 + 206 * active / BUDGET, 414, 206 * minf(pending / BUDGET, 1.0 - active / BUDGET), 6), GOLD)
	label_at(Vector2(944, 447), "%.0f / %d px used" % [used, int(BUDGET)], 15)
	label_at(Vector2(944, 476), "Next refill: %.1fs" % next_barrier_expiry() if not barriers.is_empty() else "Barriers last 5 seconds", 15, MUTED)
	label_at(Vector2(944, 501), "%d active / %.0f px free" % [barriers.size(), maxf(0.0, BUDGET - used)], 13, MUTED)
	label_at(Vector2(944, 528), "HOW TO PLAY", 13, MUTED)
	var lines := ["Drag, release: barrier", "Crash UFOs together!", "Cyan: stunned for 10s", "Gold: attacking again", "Right-click: cancel", "P: pause / R: restart"]
	for i in range(lines.size()):
		label_at(Vector2(944, 557 + i * 25), lines[i], 14)
	var status := "CRASH UFOs TOGETHER / surviving pilots turn back toward the planet"
	if available_ink() < Route.MIN_BARRIER_LENGTH:
		status = "WAIT FOR INK / next barrier disappears in %.1fs" % next_barrier_expiry()
	if drawing:
		status = "RELEASE TO ACTIVATE" if sketch_error() == "" else sketch_error()
		if available_ink() - Route.length_of(sketch) < 0.5 and sketch_error() == "":
			status = "INK LIMIT / release to activate, or wait for a barrier to disappear"
	label_at(Vector2(30, 764), status, 15, GOLD if drawing else CYAN)
	if message_time > 0:
		label_at(Vector2(30, 790), message, 13, MUTED)
	if state != "playing":
		draw_rect(Rect2(0,0,1200,800), Color(0.015, 0.025, 0.05, 0.82))
		panel(Rect2(238, 231, 484, 351))
		var title := "DRAW THE ORBIT"
		var subtitle := "Protect the planet for 90 seconds."
		if state == "paused":
			title = "MISSION PAUSED"
			subtitle = "Barriers, timers, and UFOs are frozen."
		elif state == "won":
			title = "PLANET SECURED"
			subtitle = "%d points / %d UFOs destroyed" % [score, hits]
		elif state == "lost":
			title = "PLANET LOST"
			subtitle = "Survived %.1fs / %d points" % [elapsed, score]
		label_at(Vector2(274, 288), title, 28)
		label_at(Vector2(274, 325), subtitle, 18, CYAN)
		label_at(Vector2(274, 376), "Draw barriers to crash alien UFOs together: +200.", 16)
		label_at(Vector2(274, 407), "Rebounds stun pilots for 10s. Aim before they recover!", 15, MUTED)
		label_at(Vector2(274, 437), "Surviving UFOs turn back and attack the planet again.", 15, MUTED)
		label_at(Vector2(274, 467), "5 seconds per barrier. Shared ink returns on expiry.", 15, MUTED)
		panel(start_button, Color("24665f"))
		label_at(Vector2(387, 538), "RESUME" if state == "paused" else "START ROUND  [Enter]", 18)
