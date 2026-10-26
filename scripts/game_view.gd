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
const BARRIER_BLUE := Color("68c8ff")
const GAMEPLAY_UFO_SCALE := 1.5
const GAMEPLAY_PLANET_SCALE := 1.5
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
		add_child(get_script().new(g, "transition"))
	else:
		set_process(false)
		if layer == "world":
			add_child(get_script().new(g, "planet"))
			for i in range(6):
				add_child(get_script().new(g, "planet_trail_%d" % i))

func refresh() -> void:
	queue_redraw()
	for child in get_children():
		child.time = time
		child.transform = g.world_transform if child.layer == "world" else Transform2D.IDENTITY
		child.refresh()

func _process(delta: float) -> void:
	g.configure_viewport()
	g.advance_presentation(delta)
	if g.state != "paused" and not g.orientation_blocked:
		time += delta
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
	elif kind == "settings":
		for i in range(8):
			var direction := Vector2.from_angle(i * TAU / 8.0)
			draw_line(at + direction * 8 * size, at + direction * 12 * size, INK, 3.5 * size, true)
		draw_arc(at, 8 * size, 0, TAU, 24, INK, 3 * size, true)
		draw_circle(at, 2.5 * size, INK)
	elif kind == "bomb":
		draw_circle(at, 7 * size, INK)
		draw_circle(at, 4.5 * size, Color("ffda88"))
		draw_line(at + Vector2(4, -5) * size, at + Vector2(8, -10) * size, INK, 2 * size, true)
		Art.star(self, at + Vector2(9, -11) * size, 3 * size, CREAM, time * 2.0)
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
		if icon == "none":
			centered(center + Vector2(0, size * 0.34), title, size, INK, true)
		else:
			button_icon(center - Vector2(width * 0.5 + 4, 0), icon, 0.85 if size < 20 else 1.0)
			centered(center + Vector2(13, size * 0.34), title, size, INK, true)
		if rect.size.x > 200:
			Art.star(self, face.end - Vector2(19, 15), 4, Color(INK, 0.22), 0.2)

func volume_slider(rect: Rect2, value: float, muted: bool) -> void:
	var rail_y: float = rect.get_center().y
	var rail_start := Vector2(rect.position.x, rail_y)
	var rail_end := Vector2(rect.end.x, rail_y)
	var knob := Vector2(lerpf(rail_start.x, rail_end.x, value), rail_y)
	draw_line(rail_start, rail_end, Color("111a31"), 12, true)
	draw_line(rail_start, knob, Color("68728e") if muted else MINT, 10, true)
	draw_circle(knob + Vector2(0, 4), 17, Color(INK, 0.7))
	draw_circle(knob, 16, LAVENDER if not muted else Color("68728e"))
	draw_arc(knob, 16, 0, TAU, 32, INK, 3, true)
	draw_circle(knob, 5, CREAM)

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

func barrier_life_color(life: float) -> Color:
	var remaining := clampf(life / g.BARRIER_LIFETIME, 0.0, 1.0)
	if remaining >= 0.5:
		return GOLD.lerp(BARRIER_BLUE, (remaining - 0.5) * 2.0)
	return PEACH.lerp(GOLD, remaining * 2.0)

func draw_barriers() -> void:
	for barrier in g.barriers:
		var points: PackedVector2Array = g.BarrierMotion.points_for(barrier)
		var alpha := clampf(barrier.life, 0.35, 1.0)
		var color := Color(barrier_life_color(barrier.life), alpha)
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
	if not g.phantom_visible(h):
		return
	var p: Vector2 = h.pos
	var v: Vector2 = h.vel
	var stunned: bool = h.get("recovery", 0.0) > 0.0
	var mode := "stunned" if stunned else "returning" if h.get("redirected", false) else "incoming"
	var color := MINT if stunned else GOLD if mode == "returning" else PEACH
	if h.warmup > 0.0:
		mode = "warning"
		var radius: float = (22 + h.warmup * 8) * GAMEPLAY_UFO_SCALE
		draw_arc(p, radius, 0, TAU, 40, Color(GOLD, 0.4), 1.5, true)
		Art.star(self, p + Vector2(22, -21) * GAMEPLAY_UFO_SCALE, 4, GOLD, time)
	else:
		draw_line(p + v.normalized() * 21 * GAMEPLAY_UFO_SCALE, p + v.normalized() * 44 * GAMEPLAY_UFO_SCALE, Color(color, 0.3), 1, true)
		var tip := p + v.normalized() * 44 * GAMEPLAY_UFO_SCALE
		draw_line(tip, tip - v.normalized().rotated(0.5) * 5, Color(color, 0.45), 1, true)
		draw_line(tip, tip - v.normalized().rotated(-0.5) * 5, Color(color, 0.45), 1, true)
		if stunned:
			draw_arc(p, 25 * GAMEPLAY_UFO_SCALE, -PI / 2, -PI / 2 + TAU * h.recovery / g.UFO_RECOVERY_TIME, 48, Color(MINT, 0.65), 2, true)
	var kind: String = h.get("type", "saucer")
	if h.get("dodge_available", false):
		draw_arc(p, 27 * GAMEPLAY_UFO_SCALE, 0, TAU, 48, MINT, 2, true)
	var scale := (0.9 if kind == "scout" else 1.55 if kind == "brute" else 1.15) * GAMEPLAY_UFO_SCALE
	Art.ufo(self, p, scale, mode, time, h.get("look", 0), kind)

func draw_health_pickup() -> void:
	if g.health_pickup.is_empty() or g.state == "lost":
		return
	var at: Vector2 = g.health_pickup.pos
	var pulse := 1.0 + sin(time * 5.0) * 0.08
	draw_set_transform(at, -global_rotation, Vector2.ONE * pulse)
	draw_circle(Vector2(0, 3), 27, Color(INK, 0.35))
	draw_circle(Vector2.ZERO, 25, Color("ffd5d5"))
	draw_arc(Vector2.ZERO, 25, 0, TAU, 40, CREAM, 2, true)
	Art.heart(self, Vector2(0, -3), 29, PEACH)
	centered(Vector2(0, 20), "+1", 11, INK, true)
	for i in range(3):
		Art.star(self, Vector2.from_angle(time * 1.8 + i * TAU / 3.0) * 34, 3, GOLD, time)
	draw_set_transform(Vector2.ZERO)

func draw_world() -> void:
	draw_barriers()
	if g.boss_alive():
		var at: Vector2 = g.boss.pos
		Art.mothership(self, at, g.boss.velocity.angle(), time, g.boss.flash > 0, g.BOSS_VISUAL_SCALE)
		draw_set_transform(at, -global_rotation)
		centered(Vector2(0, -55), "MOTHERSHIP", 12, GOLD, true)
		draw_rect(Rect2(-39, -47, 78, 7), INK)
		draw_rect(Rect2(-39, -47, 78 * float(g.boss.health) / g.boss.max_health, 7), PEACH)
		draw_set_transform(Vector2.ZERO)
	# Each UFO bonk emits a short expanding ring; this is visual only.
	for wave in g.shockwaves:
		var wave_progress: float = clampf(1.0 - wave.life / g.SHOCKWAVE_VISUAL_TIME, 0.0, 1.0)
		var ring_radius: float = maxf(1.0, g.SHOCKWAVE_RADIUS * wave_progress)
		var ring_alpha: float = 1.0 - wave_progress
		draw_circle(wave.pos, ring_radius, Color(GOLD, 0.09 * ring_alpha))
		draw_arc(wave.pos, ring_radius, 0.0, TAU, 72, Color(CREAM, ring_alpha), 3.0, true)
		draw_arc(wave.pos, maxf(1.0, ring_radius * 0.78), 0.0, TAU, 72, Color(GOLD, ring_alpha * 0.8), 2.0, true)
	if g.bomb_flash > 0.0:
		var progress: float = 1.0 - g.bomb_flash / g.BOMB_FLASH_TIME
		var radius: float = g.BOMB_RADIUS * ease(progress, 0.45)
		var alpha: float = 1.0 - progress
		draw_circle(g.CENTER, radius, Color(GOLD, alpha * 0.08))
		draw_arc(g.CENTER, radius, 0, TAU, 96, Color(CREAM, alpha), 5, true)
		draw_arc(g.CENTER, radius * 0.82, 0, TAU, 96, Color(GOLD, alpha * 0.8), 3, true)
		for i in range(12):
			Art.star(self, g.CENTER + Vector2.from_angle(TAU * i / 12.0 + time) * radius, 5 * alpha + 1, GOLD, time)
	for h in g.hazards:
		draw_enemy(h)
	draw_health_pickup()
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
	if g.is_boss_level():
		centered(Vector2(screen_size().x * 0.5, g.toolbar_rect.position.y - 12), "BOSS: DEFLECT UFOs INTO THE MOTHERSHIP" if g.boss_alive() else "MOTHERSHIP DEFEATED", 11, GOLD, true)
	for key in g.hud_cards:
		var rect: Rect2 = g.hud_cards[key]
		var color: Color = {"time": LAVENDER, "bonks": GOLD, "record": CREAM, "ink": MINT, "health": Color("ffd5d5")}[key]
		hud_stat_card(rect, color)
		if key == "health":
			if g.hud_slim:
				centered(rect.position + Vector2(rect.size.x * 0.5, 14), "HEALTH", 9, Color("4d5877"), true)
				Art.heart(self, rect.position + Vector2(rect.size.x * 0.5 - 10, 31), 14, PEACH)
				centered(rect.position + Vector2(rect.size.x * 0.5 + 12, 36), str(g.health), g.hud_font_size, INK, true)
			else:
				for i in range(g.MAX_HEALTH):
					Art.heart(self, rect.position + Vector2(14 + i * 20, 15), 17, PEACH if i < g.health else Color("71748b"))
		elif key == "ink":
			if g.hud_slim:
				centered(rect.position + Vector2(rect.size.x * 0.5, 14), "INK", 9, Color("4d5877"), true)
				centered(rect.position + Vector2(rect.size.x * 0.5, 33), g.hud_value(key), g.hud_font_size, INK, true)
			else:
				centered(rect.get_center(), g.hud_text(key), g.hud_font_size, INK, true)
			ink_meter(rect)
		elif g.hud_slim:
			var label: String = "HIGH" if key == "record" else "LVL %d" % g.current_level() if key == "time" else key.to_upper()
			centered(rect.position + Vector2(rect.size.x * 0.5, 13), label, 9, Color("4d5877"), true)
			centered(rect.position + Vector2(rect.size.x * 0.5, 31), g.hud_value(key), g.hud_font_size, INK, true)
		else:
			centered(rect.get_center() + Vector2(0, 4), g.hud_text(key), g.hud_font_size, INK, true)
	var bomb_ready: bool = g.space_bombs > 0
	cartoon_button(g.bomb_button, g.bomb_progress_text(), GOLD if bomb_ready else Color("9aa8c8"), "bomb", 13, bomb_ready)
	cartoon_button(g.pause_button, "", LAVENDER, "pause", 14)

func ink_meter(card_rect: Rect2) -> void:
	var meter := Rect2(card_rect.position + Vector2(8, card_rect.size.y - 8), Vector2(card_rect.size.x - 16, 4))
	rounded_box(meter, Color("11182d"), Color("34415f"), 2, 1)
	var ratio: float = g.remaining_ink_ratio()
	if ratio <= 0.0:
		return
	var fill_color := MINT if ratio > 0.5 else GOLD if ratio > 0.2 else PEACH
	var fill := meter.grow(-1)
	fill.size.x *= ratio
	if fill.size.x >= 1.0:
		rounded_box(fill, fill_color, fill_color, 2, 0)

func hud_stat_card(rect: Rect2, accent: Color) -> void:
	# Keep the tidy shared geometry while restoring each stat's playful color.
	rounded_box(Rect2(rect.position + Vector2(0, 2), rect.size), Color("0b1124"), Color("0b1124"), 11, 1)
	rounded_box(rect, accent, INK, 11, 2)
	draw_line(rect.position + Vector2(12, 4), Vector2(rect.end.x - 12, rect.position.y + 4), Color(CREAM, 0.85), 2.0, true)

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
	if g.visible_state() == "paused":
		# Keep the persistent bottom controls visible; only dim the play arena.
		draw_rect(g.screen_arena, Color("0c132a", 0.7))
		card(g.overlay_card, CREAM, LAVENDER)
		var center_x: float = g.overlay_card.get_center().x
		var top: float = g.overlay_card.position.y
		centered(Vector2(center_x, top + 30), "PAUSED / LEVEL %d" % g.level, 20, INK, true)
		centered(Vector2(center_x, top + 51), "Leaving ends this attempt", 12, Color("4d5877"))
		cartoon_button(g.start_button, "RESUME", MINT, "play", 16)
		cartoon_button(g.restart_button, "RESTART", LAVENDER, "retry", 16)
		cartoon_button(g.select_level_button, "LEVEL SELECT", GOLD, "play", 16)
		cartoon_button(g.title_button, "RETURN TO TITLE", Color("a6b1cb"), "retry", 16)
		return
	if g.state == "complete":
		draw_rect(Rect2(Vector2.ZERO, screen_size()), Color("0c132a", 0.8))
		card(g.overlay_card, CREAM, GOLD)
		var center_x: float = g.overlay_card.get_center().x
		var top: float = g.overlay_card.position.y
		var spacing: float = (g.start_button.position.y - top - 43) / 3.0
		centered(Vector2(center_x, top + 29), "LEVEL %d COMPLETE!" % g.current_level(), 20, INK, true)
		var labels := ["BONKS", "HIGHEST BONKS", "TOTAL UFOs DESTROYED"]
		var values := [g.bonks, g.highest_bonks, g.hits]
		for i in range(labels.size()):
			var y: float = top + 43 + spacing * (i + 0.65)
			text_at(Vector2(g.overlay_card.position.x + 20, y), labels[i], 12, INK, true)
			var value := str(values[i])
			text_at(Vector2(g.overlay_card.end.x - 20 - bold.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x, y), value, 16, INK, true)
		cartoon_button(g.start_button, "PLAY AGAIN", LAVENDER, "retry", 15)
		cartoon_button(g.next_level_button, "NEXT LEVEL", MINT, "play", 15)
		cartoon_button(g.title_button, "RETURN TO TITLE", GOLD, "play", 15)
		return
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

func draw_intro() -> void:
	var screen := screen_size()
	if g.is_boss_level():
		draw_boss_intro(screen)
		return
	var kind: String = g.intro_kind()
	var stats: Dictionary = g.UFO_TYPES[kind]
	var cycle: float = fmod(g.intro_clock, 6.0)
	var planet_at: Vector2 = g.screen_planet_center()
	var start := Vector2(screen.x * 0.5, screen.y * 0.30)
	var destination := planet_at - Vector2(0, 45)
	var duration: float = 3.0 / stats.speed
	var progress := clampf((cycle - 0.6) / duration, 0.0, 1.0)
	var impact := progress >= 1.0 and cycle < 5.7
	var ship_at := start.lerp(destination, progress)
	var stunned := kind == "weaver" and progress >= 0.5
	if kind == "dodger":
		impact = false
		stunned = progress >= 0.75
		if stunned:
			ship_at = start.lerp(destination, 1.5 - progress)
	if kind == "weaver":
		impact = false
		if stunned:
			ship_at = start.lerp(destination, 1.0 - progress)
		else:
			ship_at.x += sin(progress * TAU * 2.0) * minf(screen.x * 0.15, 48) * sin(progress * PI)
	draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
	var title := "LEVEL %d / NEW UFO" % g.level if g.level <= g.UFO_UNLOCK_ORDER.size() else "LEVEL %d / FLEET BRIEFING" % g.level
	centered(Vector2(screen.x * 0.5, 30), title, 14, GOLD, true)
	centered(Vector2(screen.x * 0.5, 64), kind.to_upper(), 28, CREAM, true)
	var descriptions := {
		"saucer": ["Flies straight toward your planet.", "A hit costs 1 heart."],
		"scout": ["Small and fast: 1.55x Saucer speed.", "Draw your barrier early!"],
		"weaver": ["Weaves from side to side as it approaches.", "A barrier bounce stops its weaving."],
		"brute": ["Big and slow, but hits twice as hard.", "A hit costs 2 hearts."],
		"dodger": ["Passes through one barrier in its lifetime.", "Then barriers bounce it normally."],
		"phantom": ["Cloaks for 1.5 seconds, then reappears.", "Invisible UFOs still hit barriers!"]}
	var text_size := 13 if screen.x < 400 else 15
	centered(Vector2(screen.x * 0.5, 88), descriptions[kind][0], text_size, CREAM)
	centered(Vector2(screen.x * 0.5, 109), descriptions[kind][1], text_size, MUTED)
	draw_line(start, planet_at, Color(MUTED, 0.25), 2, true)
	if kind == "dodger":
		for fraction in [0.30, 0.75]:
			var barrier_at := start.lerp(destination, fraction)
			draw_line(barrier_at - Vector2(32, 0), barrier_at + Vector2(32, 0), BARRIER_BLUE, 4, true)
		if progress < 0.30:
			draw_arc(ship_at, 27, 0, TAU, 48, MINT, 2, true)
		elif not stunned:
			centered(ship_at + Vector2(0, -37), "DODGE!", 14, MINT, true)
	if kind == "weaver":
		var barrier_at := start.lerp(destination, 0.5)
		draw_line(barrier_at - Vector2(32, 0), barrier_at + Vector2(32, 0), BARRIER_BLUE, 4, true)
	if kind == "scout":
		var reference := start.lerp(destination, clampf((cycle - 0.6) / 3.0, 0, 1)) + Vector2(55, 0)
		Art.ufo(self, reference, 0.65, "incoming", cycle, 0, "saucer")
		centered(start + Vector2(55, -26), "SAUCER", 11, MUTED)
	Art.planet(self, planet_at, 0.85, impact, false, cycle)
	var cloaked := kind == "phantom" and fmod(cycle, 4.0) >= 2.5
	if not impact and not cloaked:
		var scale := 0.85 if kind == "scout" else 1.6 if kind == "brute" else 1.1
		Art.ufo(self, ship_at, scale, "stunned" if stunned else "incoming", cycle, stats.look, kind)
	elif impact:
		Art.star(self, planet_at - Vector2(25, 0), 20, GOLD, cycle)
		centered(planet_at + Vector2(0, -46), "-%d HP" % stats.damage, 22, PEACH, true)
	for i in range(5):
		Art.heart(self, planet_at + Vector2((i - 2) * 16, 45), 13, Color("535b73") if impact and i >= 5 - stats.damage else PEACH)
	centered(Vector2(screen.x * 0.5, screen.y - 88), "STUNNED: FLIES STRAIGHT" if stunned else "DEMO LOOPS • SKIP WHEN READY", 11, MINT if stunned else MUTED)
	cartoon_button(g.skip_button, "SKIP", GOLD, "play", 18)
	if cloaked:
		centered(Vector2(screen.x * 0.5, screen.y - 112), "CLOAKED / STILL DANGEROUS", 11, LAVENDER, true)

func draw_boss_intro(screen: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
	centered(Vector2(screen.x * 0.5, 30), "LEVEL %d / BOSS" % g.level, 14, GOLD, true)
	centered(Vector2(screen.x * 0.5, 66), "MOTHERSHIP", 28, CREAM, true)
	centered(Vector2(screen.x * 0.5, 92), "No timer. Destroy it to clear the level.", 14, CREAM)
	centered(Vector2(screen.x * 0.5, 114), "UFO waves also arrive from the arena edges.", 13, MUTED)
	var ship_at := Vector2(screen.x * 0.5, screen.y * 0.38)
	Art.mothership(self, ship_at, sin(time * 0.7) * 0.2, time, fmod(time, 2.0) < 0.25, 1.35)
	centered(ship_at + Vector2(0, 76), "DEFLECT UFOs INTO THE SHIP", 13, GOLD, true)
	Art.planet(self, Vector2(screen.x * 0.5, screen.y * 0.68), 0.85, false, false, time)
	centered(Vector2(screen.x * 0.5, screen.y - 88), "BOSS MOVES FREELY / WATCH EVERY EDGE", 11, MINT, true)
	cartoon_button(g.skip_button, "SKIP", GOLD, "play", 18)

func draw_transition() -> void:
	if g.transition_phase.is_empty():
		return
	var screen := screen_size()
	var at: Vector2 = g.screen_planet_center()
	var reach := 0.0
	for corner in [Vector2.ZERO, Vector2(screen.x, 0), screen, Vector2(0, screen.y)]:
		reach = maxf(reach, at.distance_to(corner))
	reach += 4.0
	var progress: float = smoothstep(0.0, 1.0, g.transition_clock / g.TRANSITION_TIME)
	var radius: float = reach * (1.0 - progress if g.transition_phase == "close" else progress)
	if radius < 0.5:
		draw_rect(Rect2(Vector2.ZERO, screen), Color.BLACK)
		return
	for i in range(128):
		var a := Vector2.from_angle(TAU * i / 128.0)
		var b := Vector2.from_angle(TAU * (i + 1) / 128.0)
		draw_colored_polygon(PackedVector2Array([at + a * radius, at + a * (reach + 8), at + b * (reach + 8), at + b * radius]), Color.BLACK)

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
	var title_at := center - Vector2(0, 145 * unit)
	centered(title_at + Vector2(4, 6) * unit, "BONK!", int(104 * unit), Color("405778"), true)
	centered(title_at, "BONK!", int(104 * unit), CREAM, true)
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
	cartoon_button(g.settings_button, "", LAVENDER, "settings", 16)
	if g.settings_open:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(INK, 0.78))
		card(g.settings_card, Color("273354"), LAVENDER)
		centered(g.settings_card.position + Vector2(g.settings_card.size.x * 0.5, 38), "SETTINGS", 22, CREAM, true)
		centered(g.settings_card.position + Vector2(g.settings_card.size.x * 0.5, 67), "BGM", 14, MUTED if g.game_muted else MINT, true)
		volume_slider(g.bgm_slider, g.bgm_volume, g.game_muted)
		centered(g.settings_card.position + Vector2(g.settings_card.size.x * 0.5, 145), "EFFECTS", 14, MUTED if g.game_muted else MINT, true)
		volume_slider(g.effects_slider, g.effects_volume, g.game_muted)
		cartoon_button(g.mute_button, "UNMUTE" if g.game_muted else "MUTE", PEACH, "none", 15)
		cartoon_button(g.close_settings_button, "DONE", GOLD, "none", 16)

func draw_play_menu() -> void:
	var screen := screen_size()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
	Art.planet(self, g.screen_planet_center(), 0.65, false, false, time)
	centered(Vector2(screen.x * 0.5, g.beginning_button.position.y - 12), "CHOOSE YOUR FLIGHT", 15, CREAM, true)
	cartoon_button(g.beginning_button, "FROM BEGINNING", GOLD, "play", 16)
	cartoon_button(g.continue_button, "CONTINUE / LVL %d" % g.highest_unlocked_level, MINT, "play", 16)
	cartoon_button(g.select_level_button, "SELECT LEVEL", LAVENDER, "play", 16)
	cartoon_button(g.back_button, "BACK", Color("a6b1cb"), "retry", 14)

func draw_level_select() -> void:
	var screen := screen_size()
	draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
	Art.planet(self, g.screen_planet_center(), 0.55, false, false, time)
	centered(Vector2(screen.x * 0.5, 76), "SELECT LEVEL", 20, CREAM, true)
	centered(Vector2(screen.x * 0.5, 94), "DEV / ALL UNLOCKED" if g.developer_unlocked else "Win to unlock the next level", 12, GOLD if g.developer_unlocked else MUTED)
	for number in g.level_buttons:
		var rect: Rect2 = g.level_buttons[number]
		var unlocked: bool = g.is_level_unlocked(number)
		var complete: bool = number < g.highest_unlocked_level
		compact_card(rect, MINT if complete else GOLD if unlocked else Color("414c68"))
		var ink := INK if unlocked else MUTED
		centered(rect.get_center() + Vector2(0, -3), "%s %d" % ["BOSS" if number % 5 == 0 else "LEVEL", number], 16, ink, true)
		centered(rect.get_center() + Vector2(0, 16), "CLEARED" if complete else "PLAY" if unlocked else "LOCKED", 10, ink, true)
	cartoon_button(g.back_button, "BACK", LAVENDER, "retry", 14)
	if g.level_page > 0:
		cartoon_button(g.previous_page_button, "<", GOLD, "retry", 14)
	if g.level_page + 1 < g.level_page_count():
		cartoon_button(g.next_page_button, ">", GOLD, "play", 14)

func _draw() -> void:
	if g.orientation_blocked:
		if layer == "root":
			var screen := screen_size()
			draw_rect(Rect2(Vector2.ZERO, screen), Color("19213e"))
			var at := screen * 0.5
			rounded_box(Rect2(at - Vector2(24, 92), Vector2(48, 72)), Color("293755"), MINT, 8, 3)
			centered(at + Vector2(0, 16), "ROTATE TO PORTRAIT", 22, CREAM, true)
			centered(at + Vector2(0, 46), "Turn your phone upright to continue.", 15, MUTED)
		return
	if layer == "transition":
		draw_transition()
		return
	var screen_state: String = g.visible_state()
	if layer.begins_with("planet"):
		if screen_state in ["menu", "intro", "play_menu", "level_select"]:
			return
		var progress: float = 1.0 - g.planet_spin_remaining / g.PLANET_SPIN_TIME
		var spin: float = TAU * 3.0 * (1.0 - pow(1.0 - progress, 3))
		if layer.begins_with("planet_trail"):
			if g.planet_spin_remaining <= 0:
				return
			var index := int(layer.trim_prefix("planet_trail_")) + 1
			modulate = Color(1, 1, 1, 0.045 * (1.0 - progress))
			spin -= index * 0.18 * (1.0 - progress)
		Art.planet(self, g.CENTER, GAMEPLAY_PLANET_SCALE, g.flash > 0, g.health <= 2, time, spin)
		if layer == "planet" and g.planet_spin_remaining > 0:
			for i in range(3):
				draw_arc(g.CENTER, (52 + i * 4) * GAMEPLAY_PLANET_SCALE, spin + i * TAU / 3, spin + i * TAU / 3 + 1.3, 30, Color(MINT, 0.3 * (1.0 - progress)), 3, true)
		return
	if screen_state in ["play_menu", "level_select"]:
		if layer == "root":
			if screen_state == "play_menu":
				draw_play_menu()
			else:
				draw_level_select()
		return
	if screen_state == "intro":
		if layer == "root":
			draw_intro()
		return
	if screen_state == "menu":
		if layer == "root":
			draw_title_screen()
		return
	if layer == "root":
		draw_rect(Rect2(Vector2.ZERO, screen_size()), Color("19213e"))
	elif layer == "world":
		draw_background()
		draw_world()
	else:
		draw_rect(g.toolbar_rect, Color("0b1022"))
		var dock := Rect2(g.toolbar_rect.position + Vector2(6, 5), g.toolbar_rect.size + Vector2(-12, 8))
		rounded_box(dock, Color("141d37"), Color("364363"), 18, 2)
		draw_line(Vector2(20, g.toolbar_rect.position.y + 5), Vector2(screen_size().x - 20, g.toolbar_rect.position.y + 5), Color(LAVENDER, 0.55), 2, true)
		if screen_state in ["playing", "paused"]:
			draw_hud()
		if screen_state == "playing":
			draw_footer()
		elif screen_state == "paused":
			draw_rect(g.toolbar_rect, Color("071020", 0.58))
			draw_overlay()
		else:
			draw_overlay()
