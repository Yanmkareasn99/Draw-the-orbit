extends Node2D
## Presentation only: simulation and collision rules remain in game.gd.
const Art = preload("res://scripts/space_art.gd")
const INK := Color("101a35")
const CREAM := Color("f5f1e5")
const MUTED := Color("9eaacb")
const MINT := Color("8ff0ce")
const PEACH := Color("ff9fa9")
const GOLD := Color("ffda88")
const LAVENDER := Color("b9acf5")
var g: Node2D
var font := SystemFont.new()
var bold := SystemFont.new()
var time := 0.0

func _init(game: Node2D) -> void:
	g = game
	font.font_names = PackedStringArray(["Trebuchet MS", "Verdana"])
	bold.font_names = font.font_names
	bold.font_weight = 700

func _process(delta: float) -> void:
	if g.state != "paused":
		time += delta
	g.update_layout(get_viewport_rect().size)
	queue_redraw()

func text_at(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	draw_string(bold if heavy else font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	var face: Font = bold if heavy else font
	text_at(at - Vector2(face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, 0), value, size, color, heavy)

func text_right(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	draw_string(bold if heavy else font, at, value, HORIZONTAL_ALIGNMENT_RIGHT, -1, size, color)

func screen_size() -> Vector2:
	return get_viewport_rect().size

func is_mobile_layout() -> bool:
	var size := screen_size()
	return size.x < 900.0 or size.y < 700.0

func card(rect: Rect2, color: Color = Color("202b4b"), border: Color = Color("384568"), radius: int = 18, shadow: bool = true) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = border
	if shadow:
		style.shadow_color = Color(0.02, 0.04, 0.1, 0.35)
		style.shadow_size = 3
		style.shadow_offset = Vector2(0, 4)
	draw_style_box(style, rect)

func pill(rect: Rect2, title: String, color: Color = MINT) -> void:
	card(rect, Color(color, 0.1), Color(color, 0.23), 10, false)
	centered(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5 + 4), title, 11, color, true)

func dashed_orbit(radius: float) -> void:
	for i in range(60):
		var angle := TAU * i / 60.0
		draw_arc(g.CENTER, radius, angle, angle + 0.035, 4, Color("b7acd9", 0.09), 1, true)

func draw_background() -> void:
	var screen := screen_size()
	var mobile := is_mobile_layout()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("131b33"))
	card(g.ARENA, Color("19213e"), Color("3b496a"), 22)
	# Low-contrast nebulae sit behind gameplay, never resembling enemies.
	for i in range(7):
		Art.ellipse(self, Vector2(250, 295), Vector2(210 - i * 21, 155 - i * 14), Color(0.37, 0.28, 0.59, 0.018))
		Art.ellipse(self, Vector2(675, 520), Vector2(205 - i * 20, 165 - i * 15), Color(0.17, 0.48, 0.56, 0.016))
	for i in range(g.stars.size()):
		var at: Vector2 = g.stars[i]
		var alpha := 0.2 + (sin(time * 0.7 + i * 2.2) + 1.0) * 0.12
		if i % 17 == 0:
			Art.star(self, at, 3.2, Color(LAVENDER, alpha + 0.1))
		else:
			draw_circle(at, 1.3 if i % 4 == 0 else 0.8, Color(CREAM, alpha))
	dashed_orbit(100)
	dashed_orbit(210)
	dashed_orbit(290)
	if mobile:
		card(Rect2(16, 14, screen.x - 32.0, 92), Color("16203b"), Color("334f73"), 20, false)
		Art.planet(self, Vector2(40, 40), 0.42, false, false, time)
		text_at(Vector2(74, 38), "DRAW THE ORBIT", 24, CREAM, true)
		text_at(Vector2(76, 60), "A tiny planet. A very big responsibility.", 11, MUTED)
		pill(Rect2(16, 88, 154, 24), "PLANET DEFENSE CLUB", LAVENDER)
		var hover_mobile: bool = g.pause_button.has_point(get_global_mouse_position()) and g.state == "playing"
		card(g.pause_button, Color("39476b") if hover_mobile else Color("253251"), Color("53618a"), 11)
		centered(g.pause_button.get_center() + Vector2(0, 4), "II", 14, CREAM, true)
	else:
		pill(Rect2(48, 122, 133, 25), "OUR LITTLE GALAXY", LAVENDER)
		text_at(Vector2(52, 710), "DRAW A LITTLE. SAVE A WORLD.", 10, Color(MUTED, 0.65), true)
		# Header insignia and title.
		Art.planet(self, Vector2(52, 49), 0.48, false, false, time)
		text_at(Vector2(88, 48), "DRAW THE ORBIT", 29, CREAM, true)
		text_at(Vector2(90, 72), "A tiny planet. A very big responsibility.", 13, MUTED)
		pill(Rect2(826, 35, 201, 30), "PLANET DEFENSE CLUB", LAVENDER)
		var hover: bool = g.pause_button.has_point(get_global_mouse_position()) and g.state == "playing"
		card(g.pause_button, Color("39476b") if hover else Color("253251"), Color("53618a"), 13)
		centered(g.pause_button.get_center() + Vector2(0, 5), "II   Pause  P", 14, CREAM, true)

func draw_barriers() -> void:
	for barrier in g.barriers:
		var points: PackedVector2Array = barrier.points
		var fading: bool = barrier.life <= 1.0
		var alpha := clampf(barrier.life, 0.35, 1.0)
		var color := Color(GOLD if fading else MINT, alpha)
		draw_polyline(points, Color(color, alpha * 0.06), 16, true)
		draw_polyline(points, Color(color, alpha * 0.12), 9, true)
		draw_polyline(points, color, 4, true)
		draw_polyline(points, Color(CREAM, alpha * 0.75), 1, true)
		for at in [points[0], points[-1]]:
			draw_circle(at, 4, INK)
			draw_circle(at, 2.5, color)
		var badge: Vector2 = (points[0] + Vector2(10, -24)).clamp(g.ARENA.position + Vector2(6, 6), g.ARENA.end - Vector2(50, 26))
		card(Rect2(badge, Vector2(42, 21)), Color("233a4b"), Color(color, 0.4), 8, false)
		centered(badge + Vector2(21, 15), "%.1fs" % barrier.life, 11, color, true)
	if g.drawing and g.sketch.size() > 1:
		var valid: bool = g.sketch_error() == ""
		var color := MINT if valid else GOLD
		draw_polyline(g.sketch, Color(color, 0.12), 10, true)
		draw_polyline(g.sketch, color, 3, true)
		draw_circle(g.sketch[0], 4, color)
		draw_arc(g.sketch[-1], 8, 0, TAU, 24, color, 1.5, true)
		Art.star(self, g.sketch[-1], 4, CREAM, time)

func draw_enemy(h: Dictionary) -> void:
	var p: Vector2 = h.pos
	var v: Vector2 = h.vel
	var stunned: bool = h.get("recovery", 0.0) > 0.0
	var mode := "stunned" if stunned else "returning" if h.get("redirected", false) else "incoming"
	var color := MINT if stunned else GOLD if mode == "returning" else PEACH
	if h.warmup > 0.0:
		mode = "warning"
		var radius: float = 22 + h.warmup * 8
		draw_arc(p, radius, 0, TAU, 40, Color(GOLD, 0.4), 1.5, true)
		Art.star(self, p + Vector2(22, -21), 4, GOLD, time)
	else:
		draw_line(p + v.normalized() * 21, p + v.normalized() * 44, Color(color, 0.3), 1, true)
		var tip := p + v.normalized() * 44
		draw_line(tip, tip - v.normalized().rotated(0.5) * 5, Color(color, 0.45), 1, true)
		draw_line(tip, tip - v.normalized().rotated(-0.5) * 5, Color(color, 0.45), 1, true)
		if stunned:
			draw_arc(p, 25, -PI / 2, -PI / 2 + TAU * h.recovery / g.UFO_RECOVERY_TIME, 48, Color(MINT, 0.65), 2, true)
	Art.ufo(self, p, 1.15, mode, time, h.get("look", 0))

func draw_world() -> void:
	draw_barriers()
	for h in g.hazards:
		draw_enemy(h)
	Art.planet(self, g.CENTER, 1.0, g.flash > 0.0, g.health <= 2, time)
	if g.drawing:
		for i in range(16):
			var angle := TAU * i / 16.0
			draw_arc(g.CENTER, 58, angle, angle + 0.13, 5, Color(MINT, 0.25), 1.5, true)
	centered(g.CENTER + Vector2(0, 76), "HOME SWEET HOME", 10, MINT, true)
	for s in g.sparks:
		var alpha: float = clampf(s.life * 2.0, 0.0, 1.0)
		draw_line(s.pos - s.vel * 0.035, s.pos, Color(s.color, alpha * 0.5), 2, true)
		Art.star(self, s.pos, 3.5 * alpha + 0.5, Color(s.color, alpha), s.life * 5)
	for pop in g.popups:
		centered(pop.pos, pop.text, 18, Color(pop.color, minf(pop.life * 2, 1.0)), true)

func draw_mobile_hud(screen: Vector2) -> void:
	var left := 12.0
	var width := screen.x - 24.0
	var y := screen.y - 392.0
	card(Rect2(left, y, width, 74), Color("1d2945"), Color("3b4867"), 16)
	text_at(Vector2(left + 14, y + 22), "HOLD ON UNTIL RESCUE", 10, MUTED, true)
	var remaining: float = maxf(0, g.ROUND_TIME - g.elapsed)
	text_right(Vector2(left + width - 14, y + 42), "%02d:%02d" % [int(ceil(remaining)) / 60, int(ceil(remaining)) % 60], 26, CREAM, true)
	pill(Rect2(left + 14, y + 34, 74, 22), "90 SEC", MINT)
	card(Rect2(left, y + 82, width * 0.48, 88), Color("22374a"), Color("3b5867"), 16, false)
	card(Rect2(left + width * 0.52, y + 82, width * 0.48, 88), Color("22374a"), Color("3b5867"), 16, false)
	text_at(Vector2(left + 14, y + 106), "PLANET LOVE", 11, MUTED, true)
	text_right(Vector2(left + width * 0.48 - 14, y + 106), "%d / 5" % g.health, 12, MINT, true)
	for i in range(5):
		var heart_x := left + 18 + i * 26
		Art.heart(self, Vector2(heart_x, y + 136), 18, PEACH if i < g.health else Color("35415e"))
	var active: float = g.active_barrier_length()
	var pending: float = g.Route.length_of(g.sketch) if g.drawing else 0.0
	var free: float = maxf(0.0, g.BUDGET - active - pending)
	text_at(Vector2(left + width * 0.52 + 14, y + 106), "SPACE INK", 11, MINT, true)
	text_right(Vector2(left + width - 14, y + 106), "%.0f%%" % (free / g.BUDGET * 100), 12, CREAM, true)
	card(Rect2(left + width * 0.52 + 14, y + 124, width * 0.48 - 28, 12), INK, INK, 6, false)
	if free > 0:
		card(Rect2(left + width * 0.52 + 14, y + 124, maxf(3, (width * 0.48 - 28) * free / g.BUDGET), 12), MINT, MINT, 6, false)
	if pending > 0:
		draw_rect(Rect2(left + width * 0.52 + 14 + (width * 0.48 - 28) * free / g.BUDGET, y + 127, (width * 0.48 - 28) * pending / g.BUDGET, 6), GOLD)
	text_at(Vector2(left + 14, y + 182), "%d barriers in orbit" % g.barriers.size(), 11, MUTED)
	text_at(Vector2(left + 14, y + 204), g.message if g.message_time > 0.0 else "Drag to draw, release to activate, two-finger tap cancels.", 10, CREAM if g.message_time > 0.0 else MUTED)
	text_right(Vector2(left + width - 14, y + 182), "%04d" % g.score, 26, GOLD, true)
	text_right(Vector2(left + width - 14, y + 204), "%d UFOs down" % g.hits, 11, MUTED)
	card(Rect2(left, y + 228, width, 150), Color("22374a"), Color("3b5867"), 16, false)
	text_at(Vector2(left + 14, y + 252), "MEET THE VISITORS", 11, MUTED, true)
	var modes := ["incoming", "stunned", "returning"]
	var titles := ["Incoming trouble", "Dizzy for 10 seconds", "Back for another go"]
	var colors := [PEACH, MINT, GOLD]
	for i in range(3):
		var icon_x := left + 18 + i * (width / 3.0)
		Art.ufo(self, Vector2(icon_x, y + 286), 0.52, modes[i], time, i)
		text_at(Vector2(icon_x + 18, y + 290), titles[i], 11, colors[i])

func draw_desktop_hud() -> void:
	card(Rect2(922, 104, 250, 110))
	text_at(Vector2(942, 130), "HOLD ON UNTIL RESCUE", 11, MUTED, true)
	var remaining: float = maxf(0, g.ROUND_TIME - g.elapsed)
	text_at(Vector2(941, 174), "%02d:%02d" % [int(ceil(remaining)) / 60, int(ceil(remaining)) % 60], 35, CREAM, true)
	pill(Rect2(1072, 148, 80, 26), "90 SEC", MINT)
	card(Rect2(942, 192, 210, 5), INK, INK, 2, false)
	if remaining > 0.0:
		card(Rect2(942, 192, maxf(2, 210 * remaining / g.ROUND_TIME), 5), LAVENDER, LAVENDER, 2, false)
	card(Rect2(922, 226, 250, 100))
	text_at(Vector2(942, 252), "PLANET LOVE", 11, MUTED, true)
	text_at(Vector2(1118, 252), "%d / 5" % g.health, 12, MINT)
	for i in range(5):
		Art.heart(self, Vector2(960 + i * 43, 286), 28, PEACH if i < g.health else Color("35415e"))
	card(Rect2(922, 338, 250, 152), Color("22374a"), Color("3b5867"))
	var active: float = g.active_barrier_length()
	var pending: float = g.Route.length_of(g.sketch) if g.drawing else 0.0
	var free: float = maxf(0.0, g.BUDGET - active - pending)
	text_at(Vector2(942, 366), "SPACE INK", 12, MINT, true)
	text_at(Vector2(1103, 366), "%.0f%%" % (free / g.BUDGET * 100), 17, CREAM, true)
	card(Rect2(942, 382, 210, 13), INK, INK, 6, false)
	if free > 0:
		card(Rect2(942, 382, maxf(3, 210 * free / g.BUDGET), 13), MINT, MINT, 6, false)
	if pending > 0:
		draw_rect(Rect2(942 + 210 * free / g.BUDGET, 385, 210 * pending / g.BUDGET, 7), GOLD)
	text_at(Vector2(942, 420), "%.0f / %d px ready" % [free, int(g.BUDGET)], 14, CREAM, true)
	text_at(Vector2(942, 445), "%d barriers in orbit" % g.barriers.size(), 12, MUTED)
	text_at(Vector2(942, 470), "Ink returns in %.1fs" % g.next_barrier_expiry() if not g.barriers.is_empty() else "Each barrier lasts 5 seconds", 12, MINT)
	card(Rect2(922, 502, 250, 82))
	text_at(Vector2(942, 527), "COSMIC SCORE", 11, MUTED, true)
	text_at(Vector2(941, 563), "%04d" % g.score, 27, GOLD, true)
	text_at(Vector2(1059, 561), "%d UFOs down" % g.hits, 12, MUTED)
	card(Rect2(922, 596, 250, 136))
	text_at(Vector2(942, 621), "MEET THE VISITORS", 11, MUTED, true)
	for i in range(3):
		var modes := ["incoming", "stunned", "returning"]
		var titles := ["Incoming trouble", "Dizzy for 10 seconds", "Back for another go"]
		var colors := [PEACH, MINT, GOLD]
		Art.ufo(self, Vector2(951, 650 + i * 30), 0.65, modes[i], time, i)
		text_at(Vector2(975, 654 + i * 30), titles[i], 12, colors[i])

func draw_hud() -> void:
	if is_mobile_layout():
		draw_mobile_hud(screen_size())
	else:
		draw_desktop_hud()

func draw_footer() -> void:
	if is_mobile_layout():
		return
	card(Rect2(28, 746, 1144, 42), Color("1c2843"), Color("344563"), 13, false)
	var status := "Drag to draw  /  Release to activate  /  Right-click to cancel"
	var color := MUTED
	if g.available_ink() < g.Route.MIN_BARRIER_LENGTH:
		status = "Out of ink! A barrier disappears in %.1fs." % g.next_barrier_expiry()
		color = GOLD
	if g.drawing:
		var error: String = g.sketch_error()
		status = "Looking good! Release to activate your barrier." if error == "" else error
		color = MINT if error == "" else GOLD
	elif g.message_time > 0:
		status = g.message
	text_at(Vector2(46, 772), status, 13, color)
	text_at(Vector2(955, 772), "P  Pause  /  R  Restart  /  Two-finger tap cancels", 12, MUTED)

func draw_overlay() -> void:
	var screen := screen_size()
	var mobile := is_mobile_layout()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("0c132a", 0.82))
	if mobile:
		var rect := Rect2(14, 68, screen.x - 28.0, screen.y - 112.0)
		card(rect, Color("25304f"), Color("53618a"), 24)
		Art.planet(self, Vector2(screen.x * 0.5, 154), 1.15, false, g.state == "lost", time)
		Art.ufo(self, Vector2(screen.x * 0.22, 145 + sin(time) * 4), 1.5, "stunned", time, 0)
		Art.ufo(self, Vector2(screen.x * 0.78, 156 + sin(time + 2) * 4), 1.5, "incoming", time, 1)
		var title := "SMALL PLANET. BIG TROUBLE."
		var subtitle := "A whole world is counting on your doodles."
		var button := "LET'S SAVE THE PLANET"
		if g.state == "paused":
			title = "TAKE A SPACE BREAK"
			subtitle = "Your planet, UFOs, and timers are waiting for you."
			button = "BACK TO THE ORBIT"
		elif g.state == "won":
			title = "YOU SAVED OUR LITTLE WORLD!"
			subtitle = "%d points  /  %d UFOs down  /  One very happy planet" % [g.score, g.hits]
			button = "ONE MORE ORBIT"
		elif g.state == "lost":
			title = "A LITTLE SPACE MISHAP"
			subtitle = "You held on for %.1fs and earned %d points. Try a new angle!" % [g.elapsed, g.score]
			button = "LET'S TRY AGAIN"
		centered(Vector2(screen.x * 0.5, 292), title, 22, CREAM, true)
		centered(Vector2(screen.x * 0.5, 320), subtitle, 13, MUTED)
		var labels := ["01  DRAW", "02  BONK", "03  PROTECT"]
		var descriptions := [["Drag a barrier.", "5 seconds. Shared ink."], ["Crash UFOs together.", "Rebounds stun for 10s."], ["Survive for 90 seconds.", "Leave a 60-degree gap."]]
		for i in range(3):
			var x := 24 + i * ((screen.x - 48.0) / 3.0)
			var w := (screen.x - 56.0) / 3.0
			card(Rect2(x, 356, w, 82), Color("1d2945"), Color("3b4867"), 14, false)
			text_at(Vector2(x + 12, 380), labels[i], 11, MINT if i == 0 else GOLD if i == 1 else PEACH, true)
			text_at(Vector2(x + 12, 405), descriptions[i][0], 11)
			text_at(Vector2(x + 12, 424), descriptions[i][1], 10, MUTED)
		var hover_mobile: bool = g.start_button.has_point(get_global_mouse_position())
		card(g.start_button, Color("b5ffe0") if hover_mobile else MINT, Color("c6ffe9"), 16)
		centered(g.start_button.get_center() + Vector2(0, 6), button, 16, INK, true)
		centered(Vector2(screen.x * 0.5, screen.y - 122), "Press P / Esc to resume" if g.state == "paused" else "or press Enter to launch", 11, MUTED)
	else:
		var rect_desktop := Rect2(260, 134, 680, 548)
		card(rect_desktop, Color("25304f"), Color("53618a"), 30)
		card(Rect2(278, 151, 644, 180), Color("1b2542"), Color("334265"), 22, false)
		for i in range(16):
			Art.star(self, Vector2(300 + fposmod(i * 107.0, 596), 165 + fposmod(i * 43.0, 146)), 2 + i % 3, Color(LAVENDER, 0.3))
		Art.planet(self, Vector2(600, 239), 1.55, false, g.state == "lost", time)
		Art.ufo(self, Vector2(426, 225 + sin(time) * 5), 2.1, "stunned", time, 0)
		Art.ufo(self, Vector2(774, 242 + sin(time + 2) * 5), 2.1, "incoming", time, 1)
		var title_d := "SMALL PLANET. BIG TROUBLE."
		var subtitle_d := "A whole world is counting on your doodles."
		var button_d := "LET'S SAVE THE PLANET"
		if g.state == "paused":
			title_d = "TAKE A SPACE BREAK"
			subtitle_d = "Your planet, UFOs, and timers are waiting for you."
			button_d = "BACK TO THE ORBIT"
		elif g.state == "won":
			title_d = "YOU SAVED OUR LITTLE WORLD!"
			subtitle_d = "%d points  /  %d UFOs down  /  One very happy planet" % [g.score, g.hits]
			button_d = "ONE MORE ORBIT"
		elif g.state == "lost":
			title_d = "A LITTLE SPACE MISHAP"
			subtitle_d = "You held on for %.1fs and earned %d points. Try a new angle!" % [g.elapsed, g.score]
			button_d = "LET'S TRY AGAIN"
		centered(Vector2(600, 373), title_d, 28, CREAM, true)
		centered(Vector2(600, 402), subtitle_d, 15, MUTED)
		var labels_d := ["01  DRAW", "02  BONK", "03  PROTECT"]
		var descriptions_d := [["Drag a barrier.", "5 seconds. Shared ink."], ["Crash UFOs together.", "Rebounds stun for 10s."], ["Survive for 90 seconds.", "Leave a 60-degree gap."]]
		for i in range(3):
			var x := 288 + i * 211
			card(Rect2(x, 426, 202, 96), Color("1d2945"), Color("3b4867"), 14, false)
			text_at(Vector2(x + 15, 451), labels_d[i], 12, MINT if i == 0 else GOLD if i == 1 else PEACH, true)
			text_at(Vector2(x + 15, 479), descriptions_d[i][0], 13)
			text_at(Vector2(x + 15, 501), descriptions_d[i][1], 12, MUTED)
		var hover: bool = g.start_button.has_point(get_global_mouse_position())
		card(g.start_button, Color("b5ffe0") if hover else MINT, Color("c6ffe9"), 16)
		centered(g.start_button.get_center() + Vector2(0, 6), button_d, 17, INK, true)
		centered(Vector2(600, 634), "Press P / Esc to resume" if g.state == "paused" else "or press Enter to launch", 12, MUTED)

func _draw() -> void:
	draw_background()
	draw_world()
	draw_hud()
	draw_footer()
	if g.state != "playing":
		draw_overlay()
