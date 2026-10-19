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
var layer := "root"

func _init(game: Node2D, render_layer: String = "root") -> void:
	g = game
	layer = render_layer
	font.font_names = PackedStringArray(["Trebuchet MS", "Verdana"])
	bold.font_names = font.font_names
	bold.font_weight = 700

func _ready() -> void:
	if layer == "root":
		add_child(get_script().new(g, "world"))
		add_child(get_script().new(g, "hud"))
	else:
		set_process(false)

func refresh() -> void:
	queue_redraw()
	for child in get_children():
		child.time = time
		child.transform = g.world_transform if child.layer == "world" else Transform2D.IDENTITY
		child.queue_redraw()

func _process(delta: float) -> void:
	if g.state != "paused":
		time += delta
	g.update_layout(get_viewport_rect().size)
	refresh()

func text_at(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	draw_string(bold if heavy else font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	var face: Font = bold if heavy else font
	text_at(at - Vector2(face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5, 0), value, size, color, heavy)

func text_right(at: Vector2, value: String, size: int = 16, color: Color = CREAM, heavy: bool = false) -> void:
	var face: Font = bold if heavy else font
	text_at(at - Vector2(face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, 0), value, size, color, heavy)

func screen_size() -> Vector2:
	return get_viewport_rect().size

func is_mobile_layout() -> bool:
	return g.compact_layout

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

func draw_header() -> void:
	if is_mobile_layout():
		Art.planet(self, Vector2(32, 36), 0.34, false, false, time)
		text_at(Vector2(57, 43), "DRAW THE ORBIT", 17, CREAM, true)
		var hover_mobile: bool = g.pause_button.has_point(get_global_mouse_position()) and g.state == "playing"
		card(g.pause_button, Color("39476b") if hover_mobile else Color("253251"), Color("53618a"), 11)
		centered(g.pause_button.get_center() + Vector2(0, 4), "II", 14, CREAM, true)
	else:
		# Header insignia and title.
		Art.planet(self, Vector2(52, 49), 0.48, false, false, time)
		text_at(Vector2(88, 48), "DRAW THE ORBIT", 29, CREAM, true)
		var hover: bool = g.pause_button.has_point(get_global_mouse_position()) and g.state == "playing"
		card(g.pause_button, Color("39476b") if hover else Color("253251"), Color("53618a"), 13)
		centered(g.pause_button.get_center() + Vector2(0, 5), "II   [P]", 14, CREAM, true)

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
		if not is_mobile_layout():
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
	for s in g.sparks:
		var alpha: float = clampf(s.life * 2.0, 0.0, 1.0)
		draw_line(s.pos - s.vel * 0.035, s.pos, Color(s.color, alpha * 0.5), 2, true)
		Art.star(self, s.pos, 3.5 * alpha + 0.5, Color(s.color, alpha), s.life * 5)
	for pop in g.popups:
		draw_set_transform(pop.pos, -global_rotation)
		centered(Vector2.ZERO, pop.text, 18, Color(pop.color, minf(pop.life * 2, 1.0)), true)
		draw_set_transform(Vector2.ZERO)

func ink_meter(rect: Rect2) -> void:
	var pending: float = g.Route.length_of(g.sketch) if g.drawing else 0.0
	var free: float = maxf(0.0, g.available_ink() - pending)
	text_at(rect.position + Vector2(18, 26), "INK", 12, MINT, true)
	text_right(rect.position + Vector2(rect.size.x - 18, 26), "%.0f%%" % (free / g.BUDGET * 100), 17, CREAM, true)
	var bar := Rect2(rect.position + Vector2(18, 40), Vector2(rect.size.x - 36, 12))
	card(bar, INK, INK, 6, false)
	if free > 0:
		card(Rect2(bar.position, Vector2(maxf(3, bar.size.x * free / g.BUDGET), 12)), MINT, MINT, 6, false)
	if pending > 0:
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * free / g.BUDGET, 3), Vector2(bar.size.x * pending / g.BUDGET, 6)), GOLD)
	if not g.barriers.is_empty():
		text_at(rect.position + Vector2(18, 76), "Refill %.1fs" % g.next_barrier_expiry(), 12, MUTED)

func draw_mobile_hud(_screen: Vector2) -> void:
	var rect: Rect2 = g.hud_rect
	var at := rect.position
	var width := rect.size.x
	card(rect)
	var remaining: int = int(ceil(maxf(0, g.ROUND_TIME - g.elapsed)))
	text_at(at + Vector2(14, 31), "%02d:%02d" % [remaining / 60, remaining % 60], 23, CREAM, true)
	if g.portrait_layout:
		for i in range(5):
			Art.heart(self, at + Vector2(width * 0.5 - 42 + i * 21, 23), 16, PEACH if i < g.health else Color("35415e"))
		text_right(at + Vector2(width - 14, 29), "%d" % g.score, 17, GOLD, true)
	else:
		for i in range(5):
			Art.heart(self, at + Vector2(24 + i * 25, 59), 19, PEACH if i < g.health else Color("35415e"))
		text_at(at + Vector2(14, 101), "%d" % g.score, 25, GOLD, true)
	var ink_y := 51.0 if g.portrait_layout else 130.0
	var pending: float = g.Route.length_of(g.sketch) if g.drawing else 0.0
	var free: float = maxf(0, g.available_ink() - pending) / g.BUDGET
	text_at(at + Vector2(14, ink_y + 3), "INK", 10, MINT, true)
	var refill := "%.1fs" % g.next_barrier_expiry() if not g.barriers.is_empty() else ""
	text_right(at + Vector2(width - 14, ink_y + 3), refill, 11, MUTED)
	var bar := Rect2(at + Vector2(14, ink_y + 12), Vector2(width - 28, 10))
	card(bar, INK, INK, 5, false)
	if free > 0:
		card(Rect2(bar.position, Vector2(maxf(2, bar.size.x * free), 10)), MINT, MINT, 5, false)
	if pending > 0:
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * free, 2), Vector2(bar.size.x * pending / g.BUDGET, 6)), GOLD)

func draw_desktop_hud() -> void:
	card(Rect2(922, 104, 250, 110))
	text_at(Vector2(942, 130), "TIME", 11, MUTED, true)
	var remaining: float = maxf(0, g.ROUND_TIME - g.elapsed)
	text_at(Vector2(941, 174), "%02d:%02d" % [int(ceil(remaining)) / 60, int(ceil(remaining)) % 60], 35, CREAM, true)
	card(Rect2(942, 192, 210, 5), INK, INK, 2, false)
	if remaining > 0.0:
		card(Rect2(942, 192, maxf(2, 210 * remaining / g.ROUND_TIME), 5), LAVENDER, LAVENDER, 2, false)
	card(Rect2(922, 226, 250, 72))
	for i in range(5):
		Art.heart(self, Vector2(960 + i * 43, 260), 28, PEACH if i < g.health else Color("35415e"))
	var ink_rect := Rect2(922, 310, 250, 96)
	card(ink_rect, Color("22374a"), Color("3b5867"))
	ink_meter(ink_rect)
	card(Rect2(922, 418, 250, 96))
	text_at(Vector2(942, 445), "SCORE", 11, MUTED, true)
	text_at(Vector2(941, 486), "%04d" % g.score, 29, GOLD, true)

func draw_hud() -> void:
	if is_mobile_layout():
		draw_mobile_hud(screen_size())
	else:
		draw_desktop_hud()

func draw_footer() -> void:
	# Only show actionable feedback; ordinary play has no text banner.
	var status := ""
	if g.drawing and g.sketch.size() > 1:
		status = g.sketch_error()
	elif g.available_ink() < g.Route.MIN_BARRIER_LENGTH:
		status = "Ink refills in %.1fs" % g.next_barrier_expiry()
	elif g.message_time > 0:
		status = g.message
	if status.is_empty():
		return
	var size := screen_size()
	var width := minf(size.x - 40, font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 32)
	var at := Vector2(28, 746) if not is_mobile_layout() else Vector2((size.x - width) * 0.5, 67)
	card(Rect2(at, Vector2(width, 30)), Color("1c2843"), Color("344563"), 10, false)
	text_at(at + Vector2(16, 20), status, 13, GOLD)

func title_orbit(at: Vector2, radii: Vector2, start: float, end: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(81):
		var angle := lerpf(start, end, i / 80.0)
		points.append(at + (Vector2(cos(angle), sin(angle)) * radii).rotated(-0.35))
	return points

func draw_title_screen() -> void:
	var screen := screen_size()
	var mobile: bool = g.portrait_layout
	var unit := minf(screen.x / 1200.0, screen.y / 800.0)
	var hero := Vector2(screen.x * 0.70, screen.y * 0.47)
	var hero_scale := 2.9 * unit
	if mobile:
		unit = minf(screen.x / 420.0, screen.y / 800.0)
		hero = Vector2(screen.x * 0.5, screen.y * 0.47)
		hero_scale = 1.8 * unit
	draw_rect(Rect2(Vector2.ZERO, screen), Color("10172e"))
	# Broad translucent washes give the hero a little depth without a panel.
	for i in range(10):
		Art.ellipse(self, hero, Vector2(330 - i * 22, 290 - i * 20) * hero_scale / 2.9, Color(0.29, 0.32, 0.58, 0.025))
		Art.ellipse(self, Vector2(screen.x * 0.15, screen.y * 0.2), Vector2(240 - i * 14, 200 - i * 12) * unit, Color(0.34, 0.22, 0.48, 0.012))
	for i in range(95):
		var at := Vector2(fposmod(i * 173.7 + 39, screen.x - 36) + 18, fposmod(i * 97.3 + 57, screen.y - 36) + 18)
		var alpha := 0.15 + (sin(time * 0.6 + i) + 1) * 0.12
		if i % 11 == 0:
			Art.star(self, at, (3 + i % 3) * unit, Color(LAVENDER, alpha), 0.1)
		else:
			Art.circle(self, at, maxf(0.7, unit), Color(CREAM, alpha))
	var radii := Vector2(85, 46) * hero_scale
	var orbit := title_orbit(hero, radii, 0, TAU)
	draw_polyline(orbit, Color(LAVENDER, 0.13), 1.5, true)
	var drift := time * 0.13
	var back_arc := title_orbit(hero, radii, PI + drift, TAU + drift)
	draw_polyline(back_arc, Color(MINT, 0.05), 16 * unit, true)
	draw_polyline(back_arc, Color(MINT, 0.18), 6 * unit, true)
	draw_polyline(back_arc, Color(MINT, 0.65), 2 * unit, true)
	Art.ufo(self, hero + Vector2(-55, -52) * hero_scale + Vector2(0, sin(time * 1.1) * 6), hero_scale * 0.94, "incoming", time, 0)
	Art.planet(self, hero + Vector2(0, sin(time * 0.8) * 4), hero_scale, false, false, time)
	var front_arc := title_orbit(hero, radii, 0.1 + drift, 2.6 + drift)
	draw_polyline(front_arc, Color(MINT, 0.06), 16 * unit, true)
	draw_polyline(front_arc, Color(MINT, 0.2), 7 * unit, true)
	draw_polyline(front_arc, MINT, 2.5 * unit, true)
	Art.star(self, front_arc[-1], 7 * unit, CREAM, time * 0.2)
	Art.ufo(self, hero + Vector2(65, 25) * hero_scale + Vector2(0, sin(time + 2) * 8), hero_scale * 0.88, "stunned", time, 1)
	Art.ufo(self, hero + Vector2(-15, 67) * hero_scale + Vector2(0, sin(time * 0.9 + 1) * 5), hero_scale * 0.66, "returning", time, 2)
	if mobile:
		centered(Vector2(screen.x * 0.5, 69 * unit), "DRAW THE", int(23 * unit), LAVENDER, true)
		centered(Vector2(screen.x * 0.5 + 3, 127 * unit + 5), "ORBIT", int(58 * unit), Color("304562"), true)
		centered(Vector2(screen.x * 0.5, 127 * unit), "ORBIT", int(58 * unit), CREAM, true)
		centered(Vector2(screen.x * 0.5, g.start_button.position.y - 25), "Draw barriers. Crash UFOs.", 14, MUTED)
	else:
		var left := screen.x * (0.08 if is_mobile_layout() else 0.0967)
		text_at(Vector2(left, screen.y * 0.30), "DRAW THE", maxi(18, int(37 * unit)), LAVENDER, true)
		text_at(Vector2(left + 4, screen.y * 0.425 + 7), "ORBIT", int(104 * unit), Color("304562"), true)
		text_at(Vector2(left, screen.y * 0.425), "ORBIT", int(104 * unit), CREAM, true)
		Art.star(self, Vector2(left + 330 * unit, screen.y * 0.30 - 10), 9 * unit, GOLD, 0.2)
		text_at(Vector2(left + 2, screen.y * 0.49), "Draw barriers. Crash UFOs.", maxi(13, int(19 * unit)), MUTED)
	var hover: bool = g.start_button.has_point(get_global_mouse_position())
	var pulse := (sin(time * 2.0) + 1.0) * 0.5
	card(g.start_button.grow(7 + pulse * 3), Color(GOLD, 0.025 + pulse * 0.025), Color(GOLD, 0.06 + pulse * 0.06), 26, false)
	card(Rect2(g.start_button.position + Vector2(0, 6), g.start_button.size), Color("a87940"), Color("a87940"), 19, false)
	card(g.start_button, Color("ffe8ad") if hover else GOLD, Color("fff1ce"), 19, false)
	var center: Vector2 = g.start_button.get_center()
	var triangle := PackedVector2Array([center + Vector2(-52, -9), center + Vector2(-52, 9), center + Vector2(-37, 0)])
	Art.polygon(self, triangle, INK)
	centered(center + Vector2(14, 7), "PLAY", 23, INK, true)
	if not is_mobile_layout():
		centered(Vector2(center.x, g.start_button.end.y + 33), "Enter", 12, MUTED)

func draw_overlay() -> void:
	var screen := screen_size()
	var mobile := is_mobile_layout()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("0c132a", 0.82))
	var title := "DRAW THE ORBIT"
	var subtitle := "Draw barriers. Crash UFOs."
	var button := "PLAY"
	if g.state == "paused":
		title = "PAUSED"
		subtitle = ""
		button = "RESUME"
	elif g.state == "won":
		title = "PLANET SAVED"
		subtitle = "%d points" % g.score
		button = "PLAY AGAIN"
	elif g.state == "lost":
		title = "GAME OVER"
		subtitle = "%d points" % g.score
		button = "RETRY"
	if mobile:
		var panel := Rect2(maxf(14, screen.x * 0.5 - 220), 20, minf(screen.x - 28, 440), screen.y - 40)
		card(panel, Color("25304f"), Color("53618a"), 24)
		var hero_y := minf(screen.y * 0.32, g.start_button.position.y - 130)
		var hero_scale := clampf(screen.y / 600, 0.65, 1.4)
		Art.planet(self, Vector2(screen.x * 0.5, hero_y), hero_scale, false, g.state == "lost", time)
		Art.ufo(self, Vector2(screen.x * 0.5 - 105 * hero_scale, hero_y + sin(time) * 4), hero_scale, "stunned", time, 0)
		Art.ufo(self, Vector2(screen.x * 0.5 + 105 * hero_scale, hero_y + sin(time + 2) * 4), hero_scale, "incoming", time, 1)
		centered(Vector2(screen.x * 0.5, hero_y + 72 * hero_scale), title, 24, CREAM, true)
		centered(Vector2(screen.x * 0.5, hero_y + 100 * hero_scale), subtitle, 14, MUTED)
	else:
		card(Rect2(300, 166, 600, 452), Color("25304f"), Color("53618a"), 30)
		card(Rect2(318, 184, 564, 180), Color("1b2542"), Color("334265"), 22, false)
		for i in range(12):
			Art.star(self, Vector2(340 + fposmod(i * 107.0, 520), 198 + fposmod(i * 43.0, 146)), 2 + i % 3, Color(LAVENDER, 0.3))
		Art.planet(self, Vector2(600, 272), 1.55, false, g.state == "lost", time)
		Art.ufo(self, Vector2(426, 258 + sin(time) * 5), 2.1, "stunned", time, 0)
		Art.ufo(self, Vector2(774, 275 + sin(time + 2) * 5), 2.1, "incoming", time, 1)
		centered(Vector2(600, 410), title, 28, CREAM, true)
		centered(Vector2(600, 445), subtitle, 15, MUTED)
		button += "  [P]" if g.state == "paused" else "  [Enter]"
	var hover: bool = g.start_button.has_point(get_global_mouse_position())
	card(g.start_button, Color("b5ffe0") if hover else MINT, Color("c6ffe9"), 16)
	centered(g.start_button.get_center() + Vector2(0, 6), button, 17, INK, true)
	if g.state == "paused":
		card(g.restart_button, Color("2e3c5c"), Color("53618a"), 12, false)
		centered(g.restart_button.get_center() + Vector2(0, 5), "RESTART", 13, CREAM, true)

func _draw() -> void:
	if g.state == "menu":
		if layer == "root":
			draw_title_screen()
		return
	if layer == "root":
		draw_rect(Rect2(Vector2.ZERO, screen_size()), Color("131b33"))
	elif layer == "world":
		draw_background()
		draw_world()
	else:
		draw_header()
		draw_hud()
		draw_footer()
		if g.state != "playing":
			draw_overlay()
