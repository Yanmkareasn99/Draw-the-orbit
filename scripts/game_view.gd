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

func screen_size() -> Vector2:
	return get_viewport_rect().size

func is_mobile_layout() -> bool:
	return g.compact_layout

func card(rect: Rect2, color: Color = Color("202b4b"), border: Color = Color("384568"), radius: int = 18, shadow: bool = true) -> void:
	if shadow:
		# Solid offset layers give panels an inked, cut-paper edge.
		rounded_box(Rect2(rect.position + Vector2(0, 5), rect.size), INK, INK, radius, 3)
		rounded_box(rect, color, INK, radius, 3)
		rounded_box(rect.grow(-5), Color.TRANSPARENT, Color(border, 0.6), maxi(3, radius - 5), 2)
		return
	rounded_box(rect, color, border, radius, 1)

func rounded_box(rect: Rect2, color: Color, border: Color, radius: int, width: int = 3) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	style.border_color = border
	style.anti_aliasing = true
	draw_style_box(style, rect)

func button_icon(at: Vector2, kind: String, size: float = 1.0) -> void:
	if kind == "pause":
		for x in [-5, 5]:
			rounded_box(Rect2(at + Vector2(x - 2, -8) * size, Vector2(4, 16) * size), INK, INK, 2, 1)
	elif kind == "retry":
		draw_arc(at, 8 * size, -0.6, PI * 1.55, 24, INK, 2.5 * size, true)
		Art.polygon(self, PackedVector2Array([at + Vector2(0, -12) * size, at + Vector2(0, -4) * size, at + Vector2(6, -8) * size]), INK)
	else:
		Art.polygon(self, PackedVector2Array([at + Vector2(-5, -9) * size, at + Vector2(-5, 9) * size, at + Vector2(9, 0) * size]), INK)

func cartoon_button(rect: Rect2, title: String, color: Color, icon: String = "play", size: int = 18, enabled: bool = true) -> void:
	var hover := enabled and rect.has_point(get_global_mouse_position())
	var pressed := hover and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var lift := 2.0 if pressed else 8.0 if hover else 6.0
	# All layers fit the existing hit rectangle, including the raised face.
	rounded_box(rect, color.darkened(0.42), INK, 16, 3)
	var face := Rect2(rect.position, rect.size - Vector2(0, lift))
	if pressed:
		face.position.y += 3
		face.size.y -= 3
	rounded_box(face, color.lightened(0.12) if hover else color, INK, 16, 3)
	draw_line(face.position + Vector2(15, 8), face.position + Vector2(minf(44, face.size.x - 15), 8), Color(CREAM, 0.9), 3, true)
	var center := face.get_center()
	if title.is_empty():
		button_icon(center, icon)
	else:
		var width := bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		button_icon(center - Vector2(width * 0.5 + 4, 0), icon, 0.85 if size < 20 else 1.0)
		centered(center + Vector2(13, size * 0.34), title, size, INK, true)
		if rect.size.x > 200:
			Art.star(self, face.end - Vector2(19, 15), 4, Color(INK, 0.22), 0.2)

func dashed_orbit(radius: float) -> void:
	for i in range(60):
		var angle := TAU * i / 60.0
		draw_arc(g.CENTER, radius, angle, angle + 0.035, 4, Color("b7acd9", 0.09), 1, true)

func draw_background() -> void:
	draw_rect(g.ARENA, Color("19213e"))
	# Low-contrast nebulae sit behind gameplay, never resembling enemies.
	for i in range(7):
		Art.ellipse(self, Vector2(250, 295), Vector2(210 - i * 21, 155 - i * 14), Color(0.37, 0.28, 0.59, 0.018))
		Art.ellipse(self, Vector2(675, 520), Vector2(205 - i * 20, 165 - i * 15), Color(0.17, 0.48, 0.56, 0.016))
	for i in range(g.stars.size()):
		var at: Vector2 = g.ARENA.position + (g.stars[i] - g.BASE_ARENA.position) / g.BASE_ARENA.size * g.ARENA.size
		var alpha := 0.2 + (sin(time * 0.7 + i * 2.2) + 1.0) * 0.12
		if i % 17 == 0:
			Art.star(self, at, 3.2, Color(LAVENDER, alpha + 0.1))
		else:
			draw_circle(at, 1.3 if i % 4 == 0 else 0.8, Color(CREAM, alpha))
	dashed_orbit(100)
	dashed_orbit(210)
	dashed_orbit(290)

func draw_barriers() -> void:
	for barrier in g.barriers:
		var points: PackedVector2Array = g.BarrierMotion.points_for(barrier)
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
	var kind: String = h.get("type", "saucer")
	var scale := 0.9 if kind == "scout" else 1.55 if kind == "brute" else 1.15
	Art.ufo(self, p, scale, mode, time, h.get("look", 0), kind)

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

func draw_hud() -> void:
	for key in g.hud_cards:
		var rect: Rect2 = g.hud_cards[key]
		var color: Color = {"time": LAVENDER, "score": GOLD, "best": CREAM, "ink": MINT, "health": Color("ffd5d5")}[key]
		compact_card(rect, color)
		if key == "health":
			if g.hud_slim:
				Art.heart(self, rect.position + Vector2(rect.size.x * 0.5, 11), 13, PEACH)
				centered(rect.position + Vector2(rect.size.x * 0.5, 31), str(g.health), g.hud_font_size, INK, true)
			else:
				for i in range(5):
					Art.heart(self, rect.position + Vector2(14 + i * 20, 15), 17, PEACH if i < g.health else Color("71748b"))
		elif g.hud_slim:
			centered(rect.position + Vector2(rect.size.x * 0.5, 13), key.to_upper(), 8, Color("4d5877"), true)
			centered(rect.position + Vector2(rect.size.x * 0.5, 31), g.hud_value(key), g.hud_font_size, INK, true)
		else:
			centered(rect.get_center() + Vector2(0, 4), g.hud_text(key), g.hud_font_size, INK, true)
	cartoon_button(g.pause_button, "", LAVENDER, "pause", 14)

func compact_card(rect: Rect2, color: Color) -> void:
	rounded_box(Rect2(rect.position + Vector2(0, 2), rect.size), INK, INK, 10, 2)
	rounded_box(rect, color, INK, 10, 2)
	draw_line(rect.position + Vector2(10, 4), rect.position + Vector2(23, 4), Color(CREAM, 0.7), 1.5, true)

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
	var at := Vector2((size.x - width) * 0.5, g.toolbar_rect.position.y - 38)
	card(Rect2(at, Vector2(width, 30)), Color("1c2843"), Color("344563"), 10, false)
	text_at(at + Vector2(16, 20), status, 13, GOLD)

func draw_overlay() -> void:
	if g.state != "menu":
		draw_rect(g.screen_arena, Color("0c132a", 0.3))
	compact_card(g.overlay_card, CREAM)
	var label_size := 14
	while g.ui_width(g.overlay_text, label_size) > g.overlay_card.size.x - 16 and label_size > 9:
		label_size -= 1
	centered(g.overlay_card.get_center() + Vector2(0, 4), g.overlay_text, label_size, INK, true)
	var action := "RESUME" if g.state == "paused" else "RETRY" if g.state == "lost" else "PLAY"
	cartoon_button(g.start_button, action, MINT if g.state == "paused" else GOLD, "retry" if g.state == "lost" else "play", 16)
	if g.state == "paused":
		cartoon_button(g.restart_button, "RESTART", LAVENDER, "retry", 14)

func title_orbit(center: Vector2, radii: Vector2, first: float, last: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(81):
		var angle := lerpf(first, last, i / 80.0)
		points.append(center + (Vector2(cos(angle), sin(angle)) * radii).rotated(-0.22))
	return points

func draw_title_screen() -> void:
	var screen := screen_size()
	var unit: float = g.title_scale()
	var center: Vector2 = g.title_center()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
	for i in range(8):
		Art.ellipse(self, center, Vector2(235 - i * 20, 250 - i * 21) * unit, Color(0.38, 0.33, 0.63, 0.025))
	for i in range(g.stars.size()):
		var at: Vector2 = (g.stars[i] - g.BASE_ARENA.position) / g.BASE_ARENA.size * screen
		var alpha := 0.18 + (sin(time * 0.7 + i) + 1.0) * 0.12
		if i % 17 == 0:
			Art.star(self, at, 2.5, Color(LAVENDER, alpha))
		else:
			draw_circle(at, 1, Color(CREAM, alpha))
	# One centered stack: title above the main planet, Play below it.
	var title_at := center - Vector2(0, 220 * unit)
	centered(title_at, "DRAW THE", int(31 * unit), LAVENDER, true)
	var orbit_at := center - Vector2(0, 132 * unit)
	centered(orbit_at + Vector2(3, 5) * unit, "ORBIT", int(96 * unit), Color("405778"), true)
	centered(orbit_at, "ORBIT", int(96 * unit), CREAM, true)
	var radii := Vector2(174, 76) * unit
	var ring := title_orbit(center, radii, 0, TAU)
	draw_polyline(ring, Color(LAVENDER, 0.18), 1.5, true)
	var drift := time * 0.12
	var back := title_orbit(center, radii, PI + drift, TAU + drift)
	draw_polyline(back, Color(MINT, 0.1), 9 * unit, true)
	draw_polyline(back, Color(MINT, 0.65), 2 * unit, true)
	Art.planet(self, center + Vector2(0, sin(time * 0.8) * 3 * unit), 2.6 * unit, false, false, time)
	var front := title_orbit(center, radii, 0.15 + drift, 2.7 + drift)
	draw_polyline(front, Color(MINT, 0.12), 9 * unit, true)
	draw_polyline(front, MINT, 2.5 * unit, true)
	Art.star(self, front[-1], 5 * unit, CREAM, time * 0.2)
	Art.ufo(self, center + Vector2(-158, -30 + sin(time) * 5) * unit, 1.4 * unit, "incoming", time, 0)
	Art.ufo(self, center + Vector2(157, 35 + sin(time + 2) * 5) * unit, 1.3 * unit, "stunned", time, 1, "scout")
	centered(center + Vector2(0, 151 * unit), "Draw barriers. Crash UFOs.", clampi(int(16 * unit), 12, 19), MUTED)
	cartoon_button(g.start_button, "PLAY", GOLD, "play", clampi(int(23 * unit), 18, 27))

func _draw() -> void:
	if g.orientation_blocked:
		if layer == "root":
			draw_rect(Rect2(Vector2.ZERO, screen_size()), INK)
			var center := screen_size() * 0.5
			rounded_box(Rect2(center - Vector2(48, 78), Vector2(96, 54)), LAVENDER, CREAM, 9, 3)
			centered(center + Vector2(0, 12), "TURN YOUR DEVICE", 21, CREAM, true)
			centered(center + Vector2(0, 42), "Play in landscape", 16, MINT)
		return
	if g.state == "menu":
		if layer == "root":
			draw_title_screen()
		return
	if layer == "root":
		draw_rect(Rect2(Vector2.ZERO, screen_size()), Color("19213e"))
	elif layer == "world":
		draw_background()
		draw_world()
	else:
		draw_rect(g.toolbar_rect, Color("10172e"))
		draw_line(g.toolbar_rect.position, Vector2(g.toolbar_rect.end.x, g.toolbar_rect.position.y), Color("53618a"), 2, true)
		if g.state == "playing":
			draw_hud()
			draw_footer()
		else:
			draw_overlay()
