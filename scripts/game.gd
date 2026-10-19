extends Node2D

const Route = preload("res://scripts/route.gd")
const CENTER := Vector2(465, 410)
const ARENA := Rect2(28, 104, 874, 628)
const BUDGET := 1550.0
const DRONE_SPEED := 430.0
const ROUND_TIME := 90.0
const CYAN := Color("64eadb")
const GOLD := Color("ffce79")
const RED := Color("ff748c")
const WHITE := Color("e5edf8")
const MUTED := Color("879ab8")
var font: Font = ThemeDB.fallback_font
var route := PackedVector2Array()
var sketch := PackedVector2Array()
var drone := Vector2.ZERO
var route_distance := 0.0
var transfer_target := Vector2.ZERO
var transferring := false
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
var message := "Draw a loop. Let the drone do the catching."
var message_time := 0.0
var flash := 0.0
var start_button := Rect2(354, 504, 250, 54)
var pause_button := Rect2(1050, 28, 118, 40)

func _ready() -> void:
	rng.seed = 13829
	for i in range(150):
		stars.append(Vector2(rng.randf_range(30, 900), rng.randf_range(110, 730)))
	rng.randomize()
	default_route()

func default_route() -> void:
	route.clear()
	for i in range(81):
		route.append(CENTER + Vector2.from_angle(-PI / 2.0 + TAU * i / 80.0) * 150.0)
	route_distance = 0.0
	drone = route[0]
	transferring = false

func start_round() -> void:
	default_route()
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
	notify("Default route active. Draw a new loop anywhere in the arena.")

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
					finish_sketch()
	if event is InputEventMouseMotion and drawing and state == "playing":
		var point := get_global_mouse_position().clamp(ARENA.position, ARENA.end)
		if sketch[-1].distance_to(point) >= 6.0:
			var remaining := BUDGET - Route.length_of(sketch)
			if remaining > 0.5:
				sketch.append(sketch[-1].move_toward(point, remaining))

func closed_sketch() -> PackedVector2Array:
	var closed := sketch.duplicate()
	if closed.size() > 2:
		if closed[-1].distance_to(closed[0]) < 1.0:
			closed[-1] = closed[0]
		else:
			closed.append(closed[0])
	return closed

func sketch_error() -> String:
	if sketch.size() < 3 or sketch[-1].distance_to(sketch[0]) > 30.0:
		return "Finish inside the start circle"
	return Route.validate(closed_sketch(), CENTER, 58.0, BUDGET)

func finish_sketch() -> void:
	drawing = false
	var error := sketch_error()
	if error != "":
		notify(error + " — previous route kept.")
	else:
		route = closed_sketch()
		var entry := Route.nearest(route, drone)
		transfer_target = entry.point
		route_distance = entry.distance
		transferring = drone.distance_to(transfer_target) > 1.0
		redraws += 1
		notify("Route activated. Drone is relocating." if transferring else "Route activated.")
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
		hazards.append({"pos": pos, "vel": (CENTER - pos).normalized() * speed, "warmup": 1.2, "radius": 9.0})

func burst(pos: Vector2, color: Color) -> void:
	for i in range(10):
		sparks.append({"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(25, 130), "life": 0.5, "color": color})

func _physics_process(delta: float) -> void:
	if state == "playing":
		elapsed += delta
		message_time = maxf(0, message_time - delta)
		flash = maxf(0, flash - delta)
		# Small substeps prevent the fast drone tunnelling through hazards.
		for step in range(4):
			step_world(delta / 4.0)
			if state != "playing":
				break
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
	var inactive := transferring
	if transferring:
		drone = drone.move_toward(transfer_target, DRONE_SPEED * dt)
		if drone.distance_to(transfer_target) < 0.1:
			transferring = false
	else:
		route_distance = fposmod(route_distance + DRONE_SPEED * dt, Route.length_of(route))
		drone = Route.at_distance(route, route_distance)
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if h.warmup > 0:
			h.warmup -= dt
			continue
		h.pos += h.vel * dt
		if not inactive and drone.distance_to(h.pos) < 23.0:
			burst(h.pos, CYAN)
			hazards.remove_at(i)
			hits += 1
			score += 100
		elif CENTER.distance_to(h.pos) < 47.0:
			burst(h.pos, RED)
			hazards.remove_at(i)
			health -= 1
			flash = 0.4
			if health <= 0:
				state = "lost"
				drawing = false
				sketch.clear()
				return

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
	draw_polyline(route, Color(0.2, 0.85, 0.8, 0.09), 12, true)
	draw_polyline(route, Color(0.35, 0.9, 0.83, 0.6), 2, true)
	# Moving markers make route direction visible.
	for i in range(10):
		var dot := Route.at_distance(route, route_distance - i * 10.0)
		draw_circle(dot, 2.0, Color(0.4, 0.95, 0.85, 0.45 * (1.0 - i / 10.0)))
	if transferring:
		draw_dashed_line(drone, transfer_target, GOLD, 1.5, 7)
	for h in hazards:
		var p: Vector2 = h.pos
		var v: Vector2 = h.vel
		if h.warmup > 0:
			draw_arc(p, 17, 0, TAU, 24, GOLD, 2, true)
			draw_line(p, p + v.normalized() * 42, Color(1, 0.8, 0.4, 0.5), 1, true)
		else:
			draw_line(p, p + v * 0.8, Color(1, 0.4, 0.5, 0.22), 1, true)
			draw_circle(p, 15, Color(1, 0.4, 0.5, 0.08))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0,-10), p + Vector2(9,-3), p + Vector2(7,8), p + Vector2(-7,9), p + Vector2(-10,-3)]), RED)
	draw_circle(CENTER, 53, Color(0.2, 0.7, 1, 0.06))
	draw_circle(CENTER, 40, Color("184f74"))
	draw_circle(CENTER + Vector2(-10,-10), 23, Color("246d88"))
	draw_arc(CENTER, 43, 0, TAU, 64, CYAN if flash <= 0 else RED, 2, true)
	draw_arc(CENTER, 58, 0, TAU, 64, Color(0.4, 0.7, 0.8, 0.2), 1, true)
	var drone_color := GOLD if transferring else CYAN
	draw_circle(drone, 20, Color(drone_color, 0.12))
	draw_circle(drone, 12, drone_color)
	draw_circle(drone, 5, WHITE)
	for s in sparks:
		draw_circle(s.pos, 2, Color(s.color, s.life * 2.0))
	if drawing and sketch.size() > 1:
		var valid := sketch_error() == ""
		var ink := CYAN if valid else GOLD
		draw_polyline(sketch, ink, 3, true)
		draw_arc(sketch[0], 30, 0, TAU, 32, ink, 2, true)
		if valid:
			var closed := closed_sketch()
			draw_line(sketch[-1], sketch[0], CYAN, 2, true)
			var entry := Route.nearest(closed, drone)
			draw_dashed_line(drone, entry.point, GOLD, 1.5, 7)
	label_at(Vector2(30, 46), "DRAW THE ORBIT", 27)
	label_at(Vector2(31, 73), "ROUTE-PLANNING PROTOTYPE  /  90 SECOND SURVIVAL", 12, MUTED)
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
	label_at(Vector2(944, 349), "%d interceptions" % hits, 14, MUTED)
	label_at(Vector2(944, 400), "ROUTE LENGTH", 13, MUTED)
	var used := Route.length_of(sketch) if drawing else Route.length_of(route)
	draw_rect(Rect2(944, 414, 206, 6), Color("27364b"))
	draw_rect(Rect2(944, 414, 206 * minf(used / BUDGET, 1), 6), GOLD if drawing else CYAN)
	label_at(Vector2(944, 447), "%d / %d px" % [int(used), int(BUDGET)], 15)
	label_at(Vector2(944, 476), "Lap: %.1f seconds" % (Route.length_of(route) / DRONE_SPEED), 15, MUTED)
	label_at(Vector2(944, 528), "HOW TO PLAY", 13, MUTED)
	var lines := ["Drag to draw a loop.", "Close near its start.", "Release to activate.", "Right-click: cancel", "P / Esc: pause", "R: restart round"]
	for i in range(lines.size()):
		label_at(Vector2(944, 557 + i * 25), lines[i], 14)
	var status := "RELOCATING / interception offline" if transferring else "DRONE ACTIVE / only the drone blocks hazards"
	if drawing:
		status = "RELEASE TO ACTIVATE" if sketch_error() == "" else sketch_error()
	label_at(Vector2(30, 764), status, 15, GOLD if drawing or transferring else CYAN)
	if message_time > 0:
		label_at(Vector2(30, 790), message, 13, MUTED)
	if state != "playing":
		draw_rect(Rect2(0,0,1200,800), Color(0.015, 0.025, 0.05, 0.82))
		panel(Rect2(238, 231, 484, 351))
		var title := "DRAW THE ORBIT"
		var subtitle := "Protect the planet for 90 seconds."
		if state == "paused":
			title = "MISSION PAUSED"
			subtitle = "Your route and hazards are frozen."
		elif state == "won":
			title = "PLANET SECURED"
			subtitle = "%d points / %d interceptions" % [score, hits]
		elif state == "lost":
			title = "PLANET LOST"
			subtitle = "Survived %.1fs / %d points" % [elapsed, score]
		label_at(Vector2(274, 288), title, 28)
		label_at(Vector2(274, 325), subtitle, 18, CYAN)
		label_at(Vector2(274, 376), "Draw a closed route for your defense drone.", 16)
		label_at(Vector2(274, 407), "Short routes return faster. Wide routes reach farther.", 15, MUTED)
		label_at(Vector2(274, 437), "Only the drone destroys hazards. The line is a rail.", 15, MUTED)
		label_at(Vector2(274, 467), "Redrawing moves the drone without teleporting.", 15, MUTED)
		panel(start_button, Color("24665f"))
		label_at(Vector2(387, 538), "RESUME" if state == "paused" else "START ROUND  [Enter]", 18)
