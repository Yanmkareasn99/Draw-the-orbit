extends RefCounted
## Resolution-independent cartoon artwork, shared by gameplay and the UI.

const OUTLINE := Color("101a35")
const MINT := Color("8ff0ce")
const PEACH := Color("ff9fa9")
const SUN := Color("ffda88")

static func circle(canvas: Node2D, at: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(at, radius, color, true, -1.0, true)

static func polygon(canvas: Node2D, points: PackedVector2Array, color: Color) -> void:
	canvas.draw_colored_polygon(points, color)
	var edge := points.duplicate()
	edge.append(points[0])
	canvas.draw_polyline(edge, color, 1.0, true)

static func ellipse(canvas: Node2D, at: Vector2, radii: Vector2, color: Color, outline: Color = Color.TRANSPARENT, width: float = 2.0) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		points.append(at + Vector2(cos(TAU * i / 40.0), sin(TAU * i / 40.0)) * radii)
	canvas.draw_colored_polygon(points, color)
	if outline.a > 0.0:
		points.append(points[0])
		canvas.draw_polyline(points, outline, width, true)
	else:
		points.append(points[0])
		canvas.draw_polyline(points, color, 1.0, true)

static func star(canvas: Node2D, at: Vector2, radius: float, color: Color, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		points.append(at + Vector2.from_angle(angle + PI * i / 4.0) * radius * (1.0 if i % 2 == 0 else 0.28))
	canvas.draw_colored_polygon(points, color)

static func reward_star(canvas: Node2D, at: Vector2, radius: float, color: Color, angle: float = -PI * 0.5) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		points.append(at + Vector2.from_angle(angle + PI * i / 5.0) * radius * (1.0 if i % 2 == 0 else 0.5))
	var shadow := points.duplicate()
	for i in range(shadow.size()):
		shadow[i] += Vector2(0, maxf(1.0, radius * 0.17))
	canvas.draw_colored_polygon(shadow, Color(OUTLINE, 0.28))
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, OUTLINE, maxf(1.1, radius * 0.17), true)

static func heart(canvas: Node2D, at: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var t := TAU * i / 40.0
		points.append(at + Vector2(16.0 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t))) * size / 32.0)
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, OUTLINE, 2, true)
	if color.r > 0.5:
		canvas.draw_line(at + Vector2(-size * 0.24, -size * 0.13), at + Vector2(-size * 0.16, -size * 0.22), Color("ffe9e4"), 2, true)

static func planet(canvas: Node2D, at: Vector2, scale: float = 1.0, hurt: bool = false, worried: bool = false, time: float = 0.0, spin: float = 0.0) -> void:
	canvas.draw_set_transform(at, spin - canvas.global_rotation, Vector2.ONE * scale)
	circle(canvas, Vector2.ZERO, 54, Color("6bd9da", 0.045))
	circle(canvas, Vector2.ZERO, 48, Color("6bd9da", 0.07))
	ellipse(canvas, Vector2(0, 43), Vector2(30, 5), Color(0, 0, 0, 0.15))
	circle(canvas, Vector2.ZERO, 42, OUTLINE)
	circle(canvas, Vector2.ZERO, 39, Color("327aab"))
	circle(canvas, Vector2(-3, -4), 35, Color("59c4db"))
	canvas.draw_arc(Vector2.ZERO, 35, PI * 1.08, PI * 1.6, 32, Color("a2e9e5"), 3, true)
	polygon(canvas, PackedVector2Array([Vector2(-29,-22),Vector2(-15,-32),Vector2(-5,-30),Vector2(-3,-20),Vector2(-12,-14),Vector2(-8,-6),Vector2(-19,1),Vector2(-30,-8)]), Color("98dc9a"))
	polygon(canvas, PackedVector2Array([Vector2(12,-26),Vector2(25,-24),Vector2(32,-10),Vector2(23,-3),Vector2(29,8),Vector2(19,17),Vector2(8,9),Vector2(11,-1),Vector2(5,-12)]), Color("8bd293"))
	polygon(canvas, PackedVector2Array([Vector2(-23,23),Vector2(-13,19),Vector2(-6,27),Vector2(5,30),Vector2(3,35),Vector2(-13,33)]), Color("86ca99"))
	# Soft clouds stay inside the ocean silhouette.
	ellipse(canvas, Vector2(-18, -23), Vector2(9, 2.5), Color("e7fff1", 0.8))
	ellipse(canvas, Vector2(24, 18), Vector2(7, 2), Color("e7fff1", 0.65))
	ellipse(canvas, Vector2(-19, 12), Vector2(4, 2.5), Color("ffafbc", 0.8))
	ellipse(canvas, Vector2(19, 12), Vector2(4, 2.5), Color("ffafbc", 0.8))
	var blinking := fposmod(time, 5.0) > 4.8
	for x in [-11, 11]:
		if hurt or blinking:
			canvas.draw_line(Vector2(x - 3, 3), Vector2(x + 3, 5), OUTLINE, 2.5, true)
		else:
			ellipse(canvas, Vector2(x, 4), Vector2(3.5, 5), OUTLINE)
			circle(canvas, Vector2(x - 1, 2), 1.1, Color.WHITE)
	if hurt or worried:
		canvas.draw_arc(Vector2(0, 20), 6, PI * 1.15, PI * 1.85, 16, OUTLINE, 2.5, true)
	else:
		canvas.draw_arc(Vector2(0, 10), 7, 0.25, PI - 0.25, 16, OUTLINE, 2.5, true)
	if hurt:
		canvas.draw_arc(Vector2.ZERO, 44, 0, TAU, 64, PEACH, 3, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func ufo(canvas: Node2D, at: Vector2, scale: float, mode: String, time: float, variant: int = 0, kind: String = "saucer") -> void:
	var accent := MINT if mode == "stunned" else SUN if mode == "returning" or mode == "warning" else PEACH
	var shells := [Color("a59cef"), Color("ffda88"), Color("8ebde6"), Color("ee987d"), Color("76e3be"), Color("d6dcff")]
	var shell: Color = shells[posmod(variant, shells.size())]
	var tilt := sin(time * 3.0 + at.x) * 0.06 if mode != "stunned" else sin(time * 8.0) * 0.13
	canvas.draw_set_transform(at, tilt - canvas.global_rotation, Vector2.ONE * scale)
	if kind == "scout":
		# Swept fins and twin exhausts distinguish the fast, small scout.
		for side in [-1, 1]:
			polygon(canvas, PackedVector2Array([Vector2(side * 8, -2), Vector2(side * 22, 8), Vector2(side * 10, 6)]), shell)
			canvas.draw_line(Vector2(side * 9, 7), Vector2(side * 9, 15 + sin(time * 20) * 3), accent, 2, true)
	elif kind == "phantom":
		for side in [-1, 1]:
			canvas.draw_arc(Vector2(side * 12, -2), 9, -PI * 0.7, PI * 0.7, 24, shell, 2, true)
	elif kind == "dodger":
		for side in [-1, 1]:
			polygon(canvas, PackedVector2Array([Vector2(side * 13, -5), Vector2(side * 23, 0), Vector2(side * 13, 6)]), shell)
	elif kind == "weaver":
		# Side coils make the zigzag pilot identifiable even when stunned.
		for side in [-1, 1]:
			canvas.draw_arc(Vector2(side * 14, -1), 6, 0, TAU, 20, shell, 2, true)
			circle(canvas, Vector2(side * 14, -1), 2, accent)
	ellipse(canvas, Vector2(0, 9), Vector2(10, 3), Color(accent, 0.15))
	ellipse(canvas, Vector2(0, 8), Vector2(5, 2.5 + sin(time * 16.0) * 0.6), accent)
	# Oversized canopy and antenna make the tiny pilot readable in motion.
	ellipse(canvas, Vector2(0, -5), Vector2(9, 10), Color("91dfdc"), OUTLINE, 1.8)
	canvas.draw_arc(Vector2(0, -5), 7.3, PI * 1.1, PI * 1.55, 14, Color("eaffef"), 1.4, true)
	canvas.draw_line(Vector2(0, -12), Vector2(2, -16), OUTLINE, 1.5, true)
	circle(canvas, Vector2(2, -16), 2, SUN)
	ellipse(canvas, Vector2(0, -4), Vector2(5.8, 6.2), Color("9cdb82"), OUTLINE, 1.1)
	for x in [-2.5, 2.5]:
		if mode == "stunned":
			canvas.draw_line(Vector2(x - 1.2, -6), Vector2(x + 1.2, -3.5), OUTLINE, 1.1, true)
			canvas.draw_line(Vector2(x + 1.2, -6), Vector2(x - 1.2, -3.5), OUTLINE, 1.1, true)
		else:
			ellipse(canvas, Vector2(x, -5), Vector2(1.5, 2), OUTLINE)
			circle(canvas, Vector2(x - 0.4, -5.6), 0.5, Color.WHITE)
			canvas.draw_line(Vector2(x - 1.3, -8 + (1 if x < 0 else 0)), Vector2(x + 1.3, -8 + (0 if x < 0 else 1)), OUTLINE, 1.1, true)
	canvas.draw_arc(Vector2(0, -1), 1.6, 0.2, PI - 0.2, 8, OUTLINE, 1, true)
	ellipse(canvas, Vector2(0, 3), Vector2(13, 5), shell.darkened(0.25), OUTLINE, 1.8)
	ellipse(canvas, Vector2(0, 0.5), Vector2(15, 4), shell, OUTLINE, 1.8)
	if kind == "brute":
		# A broad plated hull signals the heavy UFO's two-heart impact.
		polygon(canvas, PackedVector2Array([Vector2(-14, 1), Vector2(-10, 8), Vector2(10, 8), Vector2(14, 1)]), shell.darkened(0.15))
		for x in [-6, 6]:
			canvas.draw_line(Vector2(x, 1), Vector2(x, 6), OUTLINE, 1.3, true)
	canvas.draw_line(Vector2(-9, -0.8), Vector2(-3, -1.8), Color("f1edff"), 1.3, true)
	for x in [-8, 0, 8]:
		circle(canvas, Vector2(x, 3), 2.1, OUTLINE)
		circle(canvas, Vector2(x, 3), 1.25, accent)
	if mode == "stunned":
		for i in range(2):
			star(canvas, Vector2.from_angle(time * 2.0 + i * PI) * Vector2(18, 10) + Vector2(0, -10), 2.5, SUN, time)
	canvas.draw_set_transform(Vector2.ZERO)

static func mothership(canvas: Node2D, at: Vector2, heading: float, time: float, damaged: bool = false, scale: float = 1.0) -> void:
	# A long, angular command ship with engines and a bridge, deliberately unlike
	# the small UFOs' round saucer/canopy silhouette.
	var hull := Color("5d4b91") if not damaged else Color("d96f82")
	var armor := Color("8875c7") if not damaged else Color("ff9fa9")
	canvas.draw_set_transform(at, heading, Vector2.ONE * scale)
	for side in [-1, 1]:
		polygon(canvas, PackedVector2Array([
			Vector2(-30, side * 10), Vector2(-47, side * 25), Vector2(2, side * 20),
			Vector2(29, side * 10), Vector2(18, side * 5)]), hull.darkened(0.12))
		canvas.draw_line(Vector2(-35, side * 19), Vector2(8, side * 14), SUN, 2.0, true)
	polygon(canvas, PackedVector2Array([
		Vector2(-40, -9), Vector2(-28, -18), Vector2(25, -15), Vector2(45, 0),
		Vector2(25, 15), Vector2(-28, 18), Vector2(-40, 9)]), hull)
	polygon(canvas, PackedVector2Array([
		Vector2(-12, -12), Vector2(20, -9), Vector2(32, 0), Vector2(20, 9), Vector2(-12, 12)]), armor)
	# Bridge and forward sensor array.
	ellipse(canvas, Vector2(8, 0), Vector2(13, 8), Color("91dfdc"), OUTLINE, 2.0)
	canvas.draw_line(Vector2(28, 0), Vector2(41, 0), OUTLINE, 3.0, true)
	circle(canvas, Vector2(43, 0), 4.0, SUN)
	# Three animated engine ports emphasize a directional spacecraft.
	for y in [-10, 0, 10]:
		circle(canvas, Vector2(-38, y), 4.5, OUTLINE)
		circle(canvas, Vector2(-39, y), 2.8 + sin(time * 13.0 + y) * 0.5, MINT)
		canvas.draw_line(Vector2(-43, y), Vector2(-52 - sin(time * 9.0 + y) * 3.0, y), Color(MINT, 0.65), 3.0, true)
	if damaged:
		for i in range(3):
			star(canvas, Vector2.from_angle(time * 4.0 + i * TAU / 3.0) * Vector2(33, 23), 3.5, SUN, time)
	canvas.draw_set_transform(Vector2.ZERO)
