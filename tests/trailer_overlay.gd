extends "res://scripts/game_view.gd"
const Timeline = preload("res://tests/trailer_timeline.gd")
var scene_index := 0
var local_time := 0.0
var scene_duration := 1.0
var intensity := 0.0

func _init(game: Node2D) -> void:
	super(game, "promo")

func _ready() -> void:
	set_process(false)

func _draw() -> void:
	var shot: Dictionary = Timeline.SHOTS[scene_index]
	if shot.kind == "cta":
		draw_rect(Rect2(0, 0, 360, 640), Color(INK, 0.38))
		var arrival := ease(clampf(local_time / 0.16, 0, 1), 0.3)
		centered(Vector2(180, 145 + (1 - arrival) * 25), "BONK!", 76, GOLD, true)
		centered(Vector2(180, 183), "DRAW. DEFLECT. BONK!", 15, MINT, true)
		rounded_box(Rect2(22, 439, 316, 89), GOLD, INK, 22, 3)
		centered(Vector2(180, 476), "DEFEND YOUR", 26, INK, true)
		centered(Vector2(180, 509), "PLANET NOW!", 26, INK, true)
		centered(Vector2(180, 571), "ENGLISH / 日本語 / TIẾNG VIỆT", 12, CREAM, true)
	else:
		for i in range(15):
			draw_rect(Rect2(0, i * 8, 360, 8), Color(INK, 0.92 * (1.0 - pow(i / 15.0, 3.0))))
		var title: Array = shot.title
		var arrival := ease(clampf(local_time / 0.1, 0, 1), 0.3)
		var offset := (1 - arrival) * 12
		if title[1].is_empty():
			centered(Vector2(180, 76 + offset), title[0], 36, GOLD if shot.kind in ["bomb", "chain", "finisher"] else MINT, true)
		else:
			centered(Vector2(180, 50 + offset), title[0], 28, CREAM, true)
			centered(Vector2(180, 88 + offset), title[1], 29, GOLD if shot.kind in ["bomb", "chain"] else MINT, true)
		var phase := fposmod(time - 0.25, Timeline.BEAT) / Timeline.BEAT
		draw_line(Vector2(144 - intensity * 50, 108), Vector2(216 + intensity * 50, 108), Color(MINT, 0.35 + (1 - phase) * 0.45), 2, true)
	if shot.kind == "bomb" and g.space_bombs > 0:
		tutorial_focus_rect(g.bomb_button, GOLD)
	if shot.kind == "heal":
		tutorial_focus_rect(g.hud_cards.health, MINT)
	if scene_index > 0 and local_time < 0.085:
		var progress := local_time / 0.085
		draw_rect(Rect2(360 * progress - 32, 0, 32, 640), Color(MINT, 0.34 * (1 - progress)))
		draw_rect(Rect2(0, 0, 360, 640), Color(GOLD, 0.1 * (1 - progress)))
	if shot.kind == "cta" and local_time > scene_duration - 0.25:
		draw_rect(Rect2(0, 0, 360, 640), Color(INK, (local_time - scene_duration + 0.25) / 0.25))
