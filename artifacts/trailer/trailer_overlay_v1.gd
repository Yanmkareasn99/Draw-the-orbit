extends "res://scripts/game_view.gd"
## Promotional typography over game-rendered footage. No replacement mechanics.
var scene_index := 0
var local_time := 0.0
var scene_duration := 1.0
const BEAT := 60.0 / 104.0
const TITLES := [
	["ONE PLANET.", "TO PROTECT."], ["ONE LINE.", "TO FIGHT BACK."], ["MAKE THEM", "BONK!"],
	["A SMALL WORLD.", "A BIG PROBLEM."], ["SIX UFO TYPES.", "SIX NEW PROBLEMS."],
	["DRAW YOUR", "DEFENSE."], ["TURN ATTACKS", "INTO AMMO."], ["FIVE BONKS.", "ONE BIG BOOM."],
	["KEEP YOUR", "PLANET ALIVE."], ["MAKE EVERY", "LINE COUNT."], ["TAKE ON", "THE MOTHERSHIP."],
	["SURVIVE.", "CHASE THE STARS."], ["BONK!", ""], ["BONK!", ""]]

func _init(game: Node2D) -> void:
	super(game, "promo")

func _ready() -> void:
	set_process(false)

func backdrop() -> void:
	draw_rect(Rect2(0, 0, 360, 640), Color("111a32"))
	for i in range(90):
		var at := Vector2(fposmod(i * 113.7, 360), fposmod(i * 61.3 + time * (2 + i % 3), 640))
		draw_circle(at, 0.6 + (i % 3) * 0.3, Color(CREAM, 0.15 + 0.15 * sin(time + i)))

func hero() -> void:
	backdrop()
	var at := Vector2(180, 320)
	var radius := 122.0
	for i in range(48):
		var angle := i * TAU / 48 + time * 0.12
		draw_arc(at, radius, angle, angle + 0.05, 5, Color(MINT, 0.35), 1, true)
	Art.planet(self, at, 2.7 + sin(time * 1.1) * 0.04, false, false, time)
	for i in range(3):
		var angle := time * 0.28 + i * TAU / 3
		Art.ufo(self, at + Vector2(cos(angle) * 133, sin(angle) * 111), 0.9,
			"stunned" if i == 1 else "incoming", time, i, "scout" if i == 2 else "saucer")

func _draw() -> void:
	if scene_index in [3, 12, 13]:
		hero()
	elif scene_index == 4:
		backdrop()
		var types := ["saucer", "scout", "weaver", "brute", "dodger", "phantom"]
		for i in range(6):
			var at := Vector2(98 + (i % 2) * 164, 205 + (i / 2) * 133)
			rounded_box(Rect2(at - Vector2(69, 48), Vector2(138, 110)), Color("202c47"), Color(LAVENDER, 0.25), 18, 1)
			var mode := "stunned" if i == 2 else "incoming"
			Art.ufo(self, at + Vector2(sin(time * 1.3 + i) * 8, cos(time * 1.8 + i) * 5), 1.1 if i != 3 else 1.45, mode, time, i, types[i])
			centered(at + Vector2(0, 43), types[i].to_upper(), 12, MINT if i % 2 == 0 else GOLD, true)
	if scene_index >= 12:
		var ease_in := ease(clampf(local_time / 0.7, 0.0, 1.0), 0.3)
		centered(Vector2(180, 152 + (1 - ease_in) * 22), "BONK!", 68, GOLD, true)
		centered(Vector2(180, 190), "DRAW. DEFLECT. BONK!", 16, MINT, true)
		if scene_index == 13:
			rounded_box(Rect2(26, 476, 308, 88), GOLD, INK, 22, 3)
			centered(Vector2(180, 511), "DEFEND YOUR", 25, INK, true)
			centered(Vector2(180, 542), "PLANET NOW!", 25, INK, true)
			centered(Vector2(180, 600), "ENGLISH  /  日本語  /  TIẾNG VIỆT", 11, CREAM, true)
		else:
			centered(Vector2(180, 502), "YOUR LINE. THEIR COLLISION.", 17, CREAM, true)
	else:
		# A compact caption band keeps the planet and playable HUD unobstructed.
		for i in range(16):
			draw_rect(Rect2(0, i * 8, 360, 8), Color(INK, 0.94 * (1.0 - pow(i / 16.0, 3.0))))
		var chapter := "01 / THE HOOK" if scene_index < 3 else "02 / THE WORLD" if scene_index < 5 else "03 / HOW YOU FIGHT" if scene_index < 9 else "04 / KEEP GOING"
		centered(Vector2(180, 22), chapter, 9, Color(MINT, 0.85), true)
		var enter := clampf(local_time / 0.18, 0.0, 1.0)
		var offset := (1.0 - ease(enter, 0.25)) * 15
		centered(Vector2(180, 59 + offset), TITLES[scene_index][0], 28, CREAM, true)
		centered(Vector2(180, 94 + offset), TITLES[scene_index][1], 28, GOLD if scene_index in [2, 7, 11] else MINT, true)
		var beat_phase := fposmod(time - 0.25, BEAT) / BEAT
		draw_line(Vector2(144, 112), Vector2(216, 112), Color(MINT, 0.3 + 0.4 * (1 - beat_phase)), 2, true)
	if scene_index in [1, 5] and g.drawing and not g.sketch.is_empty():
		var at: Vector2 = g.world_transform * g.sketch[-1]
		draw_circle(at, 9, Color(CREAM, 0.2))
		draw_circle(at, 4, CREAM)
	if scene_index == 7 and g.space_bombs > 0:
		tutorial_focus_rect(g.bomb_button, GOLD)
	if scene_index == 8:
		tutorial_focus_rect(g.hud_cards.health, MINT)
		if not g.health_pickup.is_empty():
			tutorial_focus_ring(g.world_transform * Vector2(g.health_pickup.pos), 24, PEACH)
	# Short impact flash at beat-aligned cuts; no long fade interrupts gameplay.
	if scene_index > 0 and local_time < 0.14:
		draw_rect(Rect2(0, 0, 360, 640), Color(MINT if scene_index % 2 == 0 else GOLD, 0.28 * (1 - local_time / 0.14)))
	if scene_index == 13 and local_time > scene_duration - 0.65:
		draw_rect(Rect2(0, 0, 360, 640), Color(INK, (local_time - scene_duration + 0.65) / 0.65))
