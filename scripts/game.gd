extends Node2D

const Route = preload("res://scripts/route.gd")
const CENTER := Vector2(465, 410)
const ARENA := Rect2(28, 104, 874, 628)
const BUDGET := 1550.0
const BARRIER_HALF_WIDTH := 2.0
const MAX_TRAVEL_PER_STEP := 4.0
const ROUND_TIME := 90.0
const CYAN := Color("64eadb")
const GOLD := Color("ffce79")
const RED := Color("ff748c")
const WHITE := Color("e5edf8")
const MUTED := Color("879ab8")
var font: Font = ThemeDB.fallback_font
var barrier := PackedVector2Array()
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
var message := "Draw a barrier. Bounce hazards into each other."
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
	barrier.clear()
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
	notify("Draw a barrier and release. Angle it to bounce hazards into each other.")

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
				return
			if state == "playing":
				if event.pressed and ARENA.has_point(point):
					drawing = true
					sketch = PackedVector2Array([point])
				elif not event.pressed and drawing:
					append_sketch_point(point)
					finish_sketch()
	if event is InputEventMouseMotion and drawing and state == "playing":
		append_sketch_point(get_global_mouse_position())

func append_sketch_point(point: Vector2) -> void:
	point = point.clamp(ARENA.position, ARENA.end)
	if sketch[-1].distance_to(point) >= 6.0:
		var remaining := BUDGET - Route.length_of(sketch)
		if remaining > 0.5:
			sketch.append(sketch[-1].move_toward(point, remaining))

func sketch_error() -> String:
	return Route.validate_barrier(sketch, CENTER, 58.0, BUDGET)

func finish_sketch() -> void:
	drawing = false
	var error := sketch_error()
	if error != "":
		notify(error + " - previous barrier kept.")
	else:
		barrier = sketch.duplicate()
		redraws += 1
		notify("Barrier activated. Bounce hazards into each other to destroy them.")
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
		hazards.append({"pos": pos, "vel": (CENTER - pos).normalized() * speed, "warmup": 1.2, "radius": 9.0, "redirected": false})

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
		step_hazards(dt / steps)
		if state != "playing":
			break

func reflect_hazard(h: Dictionary) -> void:
	if barrier.size() < 2:
		return
	# Nearest contact handles both segment faces and rounded endpoints.
	# Repeat to separate a hazard from tight corners without a bounce cooldown.
	for contact in range(4):
		var nearest := Route.nearest(barrier, h.pos)
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
			burst(closest, CYAN)

func step_hazards(dt: float) -> void:
	for h in hazards:
		if h.warmup > 0.0:
			h.warmup = maxf(0.0, h.warmup - dt)
			continue
		h.pos += h.vel * dt
		reflect_hazard(h)
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
		elif not ARENA.grow(h.radius + 20.0).has_point(h.pos):
			hazards.remove_at(i)

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
	if barrier.size() > 1:
		draw_polyline(barrier, Color(CYAN, 0.12), 12, true)
		draw_polyline(barrier, CYAN, BARRIER_HALF_WIDTH * 2.0, true)
		draw_circle(barrier[0], BARRIER_HALF_WIDTH, CYAN)
		draw_circle(barrier[-1], BARRIER_HALF_WIDTH, CYAN)
	for h in hazards:
		var p: Vector2 = h.pos
		var v: Vector2 = h.vel
		if h.warmup > 0:
			draw_arc(p, 17, 0, TAU, 24, GOLD, 2, true)
			draw_line(p, p + v.normalized() * 42, Color(1, 0.8, 0.4, 0.5), 1, true)
		else:
			var hazard_color := CYAN if h.get("redirected", false) else RED
			draw_line(p, p + v * 0.8, Color(hazard_color, 0.5), 2, true)
			draw_circle(p, 15, Color(hazard_color, 0.12))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0,-10), p + Vector2(9,-3), p + Vector2(7,8), p + Vector2(-7,9), p + Vector2(-10,-3)]), hazard_color)
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
	label_at(Vector2(31, 73), "DRAW / DEFLECT / DESTROY  /  90 SECOND SURVIVAL", 12, MUTED)
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
	label_at(Vector2(944, 349), "%d hazards destroyed" % hits, 14, MUTED)
	label_at(Vector2(944, 400), "BARRIER LENGTH", 13, MUTED)
	var used := Route.length_of(sketch) if drawing else Route.length_of(barrier)
	draw_rect(Rect2(944, 414, 206, 6), Color("27364b"))
	draw_rect(Rect2(944, 414, 206 * minf(used / BUDGET, 1), 6), GOLD if drawing else CYAN)
	label_at(Vector2(944, 447), "%d / %d px" % [int(used), int(BUDGET)], 15)
	label_at(Vector2(944, 476), "Cyan = bounced hazard", 15, MUTED)
	label_at(Vector2(944, 528), "HOW TO PLAY", 13, MUTED)
	var lines := ["Drag, release: barrier", "Angle it to aim rebounds.", "Hit hazards with hazards!", "Right-click: cancel", "P / Esc: pause", "R: restart round"]
	for i in range(lines.size()):
		label_at(Vector2(944, 557 + i * 25), lines[i], 14)
	var status := "BARRIER ACTIVE / bounce hazards into each other" if barrier.size() > 1 else "DRAW A BARRIER / drag and release to protect the planet"
	if drawing:
		status = "RELEASE TO ACTIVATE" if sketch_error() == "" else sketch_error()
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
			subtitle = "Your barrier and hazards are frozen."
		elif state == "won":
			title = "PLANET SECURED"
			subtitle = "%d points / %d hazards destroyed" % [score, hits]
		elif state == "lost":
			title = "PLANET LOST"
			subtitle = "Survived %.1fs / %d points" % [elapsed, score]
		label_at(Vector2(274, 288), title, 28)
		label_at(Vector2(274, 325), subtitle, 18, CYAN)
		label_at(Vector2(274, 376), "Draw a barrier. Release to activate it.", 16)
		label_at(Vector2(274, 407), "Angle the barrier to bounce hazards into each other.", 15, MUTED)
		label_at(Vector2(274, 437), "A bounced hazard destroys both on impact: +200.", 15, MUTED)
		label_at(Vector2(274, 467), "Each new barrier replaces the last. Protect the planet!", 15, MUTED)
		panel(start_button, Color("24665f"))
		label_at(Vector2(387, 538), "RESUME" if state == "paused" else "START ROUND  [Enter]", 18)
