extends Node2D

const Route = preload("res://scripts/route.gd")
const GameView = preload("res://scripts/game_view.gd")
const GameSound = preload("res://scripts/game_sound.gd")
const CENTER := Vector2(465, 410)
const BASE_ARENA := Rect2(28, 104, 874, 628)
var ARENA := BASE_ARENA
const BUDGET := 1550.0
const BARRIER_LIFETIME := 5.0
const BARRIER_HALF_WIDTH := 2.0
const MAX_TRAVEL_PER_STEP := 4.0
const UFO_RECOVERY_TIME := 10.0
const REBOUND_SPEED_MULTIPLIER := 3.0
const SHOCKWAVE_RADIUS := 110.0
const SHOCKWAVE_PUSH_SPEED := 85.0
const SHOCKWAVE_STUN_TIME := 2.0
const SHOCKWAVE_VISUAL_TIME := 0.38
const UFO_TURN_RATE := 2.4
const UFO_RADIUS := 9.0
const MAX_UFOS := 28
const MAX_BASE_SPEED := 78.0
const LEVEL_DURATION := 90.0
const MAX_LEVEL_STARS := 5
const UFO_UNLOCK_ORDER := ["saucer", "scout", "weaver", "brute", "dodger", "phantom"]
const PLANET_SPIN_TIME := 1.2
const BOSS_RADIUS := 42.0
const BOSS_VISUAL_SCALE := 0.88
const BOSS_EDGE_PADDING := 12.0
const BOSS_PLANET_CLEARANCE := 10.0
const PLANET_COLLISION_RADIUS := 38.0
const BOSS_MIN_SPEED := 68.0
const BOSS_MAX_SPEED := 94.0
const BOSS_STEERING_ACCELERATION := 72.0
var planet_spin_remaining := 0.0
var boss: Dictionary = {}
const CROWD_WAVE_SHRINK_AT := 12
const CROWD_SLOWDOWN_AT := 16
const CROWD_SPAWN_MULTIPLIER := 3.0
const MAX_HEALTH := 5
const HEALTH_PICKUP_RADIUS := 22.0
const HEALTH_PICKUP_LIFETIME := 9.0
const HEALTH_PICKUP_FIRST_MIN := 18.0
const HEALTH_PICKUP_FIRST_MAX := 28.0
const HEALTH_PICKUP_REPEAT_MIN := 20.0
const HEALTH_PICKUP_REPEAT_MAX := 34.0
const BOMB_BONKS_REQUIRED := 5
const MAX_SPACE_BOMBS := 2
const BOMB_RADIUS := 270.0
const BOMB_FLASH_TIME := 0.7
const UFO_TYPES := {
	"saucer": {"speed": 1.0, "radius": 9.0, "damage": 1, "look": 0},
	"scout": {"speed": 1.55, "radius": 7.0, "damage": 1, "look": 1},
	"weaver": {"speed": 1.1, "radius": 9.0, "damage": 1, "look": 2},
	"brute": {"speed": 0.72, "radius": 15.0, "damage": 2, "look": 3},
	"dodger": {"speed": 1.0, "radius": 9.0, "damage": 1, "look": 4},
	"phantom": {"speed": 1.0, "radius": 9.0, "damage": 1, "look": 5},
}
const BarrierMotion = preload("res://scripts/barrier_motion.gd")
const CYAN := Color("64eadb")
const GOLD := Color("ffce79")
const RED := Color("ff748c")
const WHITE := Color("e5edf8")
const MUTED := Color("879ab8")
var barriers: Array[Dictionary] = []
var sketch := PackedVector2Array()
var drawing := false
var hazards: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var shockwaves: Array[Dictionary] = []
var stars := PackedVector2Array()
var rng := RandomNumberGenerator.new()
var state := "menu"
var elapsed := 0.0
var level := 1
var next_level_button := Rect2()
var title_button := Rect2()
var highest_unlocked_level := 1
var level_stars: Dictionary = {}
var earned_stars := 0
const DEV_UNLOCK_CODE := "BONKDEV"
var developer_unlocked := false
var developer_code_buffer := ""
var progress_save_path := "user://level_progress.cfg"
var beginning_button := Rect2()
var continue_button := Rect2()
var select_level_button := Rect2()
var back_button := Rect2()
var previous_page_button := Rect2()
var next_page_button := Rect2()
var level_buttons: Dictionary = {}
var level_page := 0
const LEVELS_PER_PAGE := 6
const TRANSITION_TIME := 0.65
var transition_phase := ""
var transition_clock := 0.0
var transition_from := "menu"
var transition_target := "menu"
var transition_level := 1
var intro_clock := 0.0
var skip_button := Rect2()
var spawn_clock := 1.5
var wave := 0
var health := MAX_HEALTH
var health_pickup: Dictionary = {}
var health_pickup_clock := HEALTH_PICKUP_FIRST_MIN
var bonks := 0
var highest_bonks := 0
var bonk_save_path := "user://highest_bonks.cfg"
var hits := 0
var total_ufos_spawned := 0
var space_bombs := 0
var bomb_bonk_progress := 0
var bomb_flash := 0.0
var redraws := 0
var message := ""
var message_time := 0.0
var flash := 0.0
var start_button := Rect2(414, 506, 372, 58)
var pause_button := Rect2(1050, 28, 118, 44)
var bomb_button := Rect2()
var active_touch_index := -1
var world_transform := Transform2D.IDENTITY
var screen_arena := ARENA
var layout_size := Vector2.ZERO
var compact_layout := false
var portrait_layout := false
var orientation_blocked := false
var hud_rect := Rect2()
var restart_button := Rect2()
var hud_cards: Dictionary = {}
var overlay_card := Rect2()
var overlay_text := ""
var ui_font := SystemFont.new()
var toolbar_rect := Rect2()
var hud_slim := false
var hud_tiny := false
var hud_font_size := 14
const TOOLBAR_HEIGHT := 112.0
var game_sound: Node
var bgm_volume := 0.45
var effects_volume := 0.7
var game_muted := false
var settings_open := false
var settings_save_path := "user://settings.cfg"
var settings_button := Rect2()
var settings_card := Rect2()
var bgm_slider := Rect2()
var effects_slider := Rect2()
var active_volume_slider := ""
var mute_button := Rect2()
var close_settings_button := Rect2()
var tutorial_active := false
var tutorial_stage := 0
var tutorial_card := Rect2()
var tutorial_button := Rect2()
var tutorial_setup_pending := false
var tutorial_stage_delay := 0.0

func _init() -> void:
	ui_font.font_names = PackedStringArray(["Trebuchet MS", "Verdana"])
	ui_font.font_weight = 700

func _ready() -> void:
	load_highest_bonks()
	load_level_progress()
	load_audio_settings()
	# Let the window finish updating its physical viewport before changing scale.
	get_window().size_changed.connect(configure_viewport, CONNECT_DEFERRED)
	configure_viewport()
	rng.seed = 13829
	for i in range(150):
		stars.append(Vector2(rng.randf_range(30, 900), rng.randf_range(110, 730)))
	rng.randomize()
	game_sound = GameSound.new()
	add_child(GameView.new(self))
	add_child(game_sound)
	game_sound.set_mix_volumes(bgm_volume, effects_volume, game_muted)
	update_layout(get_viewport_rect().size)

func play_sound(cue: String, pitch: float = 1.0) -> void:
	if is_instance_valid(game_sound):
		game_sound.play_cue(cue, pitch)

func set_result_bgm(active: bool) -> void:
	if is_instance_valid(game_sound) and game_sound.has_method("set_result_card_visible"):
		game_sound.set_result_card_visible(active)

func set_audio_channel_volume(channel: String, value: float, persist: bool = true) -> void:
	if channel == "bgm":
		bgm_volume = clampf(value, 0.0, 1.0)
	else:
		effects_volume = clampf(value, 0.0, 1.0)
	game_muted = false
	apply_audio_settings(persist)

func set_volume_from_slider(channel: String, point: Vector2, persist: bool = false) -> void:
	var slider := bgm_slider if channel == "bgm" else effects_slider
	set_audio_channel_volume(channel, (point.x - slider.position.x) / slider.size.x, persist)

func toggle_game_mute() -> void:
	game_muted = not game_muted
	apply_audio_settings()

func apply_audio_settings(persist: bool = true) -> void:
	if is_instance_valid(game_sound):
		game_sound.set_mix_volumes(bgm_volume, effects_volume, game_muted)
	if persist:
		save_audio_settings()

func load_audio_settings() -> void:
	if settings_save_path.is_empty():
		return
	var save := ConfigFile.new()
	if save.load(settings_save_path) != OK:
		return
	var legacy_volume = save.get_value("audio", "volume", effects_volume)
	var saved_effects = save.get_value("audio", "effects_volume", legacy_volume)
	if saved_effects is float or saved_effects is int:
		effects_volume = clampf(float(saved_effects), 0.0, 1.0)
	var saved_bgm = save.get_value("audio", "bgm_volume", bgm_volume)
	if saved_bgm is float or saved_bgm is int:
		bgm_volume = clampf(float(saved_bgm), 0.0, 1.0)
	var saved_muted = save.get_value("audio", "muted", game_muted)
	if saved_muted is bool:
		game_muted = saved_muted

func save_audio_settings() -> void:
	if settings_save_path.is_empty():
		return
	var save := ConfigFile.new()
	save.set_value("audio", "bgm_volume", bgm_volume)
	save.set_value("audio", "effects_volume", effects_volume)
	save.set_value("audio", "muted", game_muted)
	var error := save.save(settings_save_path)
	if error != OK:
		push_warning("Could not save audio settings: %s" % error_string(error))

func visible_state() -> String:
	return transition_from if transition_phase == "close" else state

func change_screen(target: String, target_level: int = -1) -> void:
	if not transition_phase.is_empty():
		return
	var requested_level := level if target_level < 0 else target_level
	if target == "intro" and not is_level_unlocked(requested_level):
		return
	play_sound("ui")
	cancel_sketch()
	# Gameplay cards are overlays, not destinations. Show and dismiss them
	# immediately so the planet iris is reserved for full-screen navigation.
	if target == "paused" or (state == "paused" and target == "playing"):
		state = target
		transition_phase = ""
		if layout_size != Vector2.ZERO:
			update_layout(layout_size)
		return
	transition_from = state
	transition_target = target
	transition_level = level if target_level < 0 else target_level
	transition_clock = 0.0
	transition_phase = "close"

func load_level_progress() -> void:
	if progress_save_path.is_empty():
		return
	var save := ConfigFile.new()
	if save.load(progress_save_path) == OK:
		var value = save.get_value("levels", "highest_unlocked", 1)
		if value is int and value >= 1:
			highest_unlocked_level = value
		level_stars.clear()
		if save.has_section("stars"):
			for key in save.get_section_keys("stars"):
				var saved_stars = save.get_value("stars", key, 0)
				if key.is_valid_int() and saved_stars is int and saved_stars >= 1 and saved_stars <= MAX_LEVEL_STARS:
					level_stars[int(key)] = saved_stars

func save_level_progress() -> void:
	if developer_unlocked or progress_save_path.is_empty():
		return
	var save := ConfigFile.new()
	save.set_value("levels", "highest_unlocked", highest_unlocked_level)
	for completed_level in level_stars:
		save.set_value("stars", str(completed_level), level_stars[completed_level])
	var error := save.save(progress_save_path)
	if error != OK:
		push_warning("Could not save level progress: %s" % error_string(error))

func unlock_next_level() -> void:
	if developer_unlocked:
		return
	if level != highest_unlocked_level:
		return
	highest_unlocked_level += 1

func calculate_level_stars(planet_health: int, destroyed: int, spawned: int) -> int:
	var health_rating := clampi(planet_health, 1, MAX_LEVEL_STARS)
	var destruction_ratio := clampf(float(destroyed) / float(spawned), 0.0, 1.0) if spawned > 0 else 0.0
	var destruction_rating := clampi(ceili(destruction_ratio * MAX_LEVEL_STARS), 1, MAX_LEVEL_STARS)
	return mini(health_rating, destruction_rating)

func award_level_stars() -> void:
	earned_stars = calculate_level_stars(health, hits, total_ufos_spawned)
	if developer_unlocked:
		return
	level_stars[level] = maxi(int(level_stars.get(level, 0)), earned_stars)

func stars_for_level(level_number: int) -> int:
	return int(level_stars.get(level_number, 0))

func level_page_count() -> int:
	if developer_unlocked:
		# Levels continue indefinitely; always expose another page for testing.
		return maxi(level_page + 2, 2)
	return ceili(maxi(LEVELS_PER_PAGE, highest_unlocked_level + 1) / float(LEVELS_PER_PAGE))

func is_level_unlocked(number: int) -> bool:
	return number >= 1 and (developer_unlocked or number <= highest_unlocked_level)

func enter_developer_code(event: InputEventKey) -> void:
	if not state in ["menu", "play_menu", "level_select"]:
		developer_code_buffer = ""
		return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		developer_code_buffer = ""
		return
	var codepoint := event.unicode if event.unicode > 0 else int(event.keycode)
	if codepoint < 32 or codepoint > 126:
		developer_code_buffer = ""
		return
	developer_code_buffer = (developer_code_buffer + String.chr(codepoint).to_upper()).right(DEV_UNLOCK_CODE.length())
	if developer_code_buffer == DEV_UNLOCK_CODE:
		developer_code_buffer = ""
		developer_unlocked = not developer_unlocked
		level_page = 0
		if state != "level_select":
			change_screen("level_select")

func advance_presentation(delta: float) -> void:
	if orientation_blocked:
		return
	# Let the opening spin run with the reveal instead of waiting behind it.
	if state == "playing" and (transition_phase.is_empty() or transition_phase == "reveal"):
		planet_spin_remaining = maxf(0.0, planet_spin_remaining - delta)
	if transition_phase.is_empty():
		if state == "intro":
			intro_clock = fmod(intro_clock + delta, 6.0 * UFO_UNLOCK_ORDER.size() if level > UFO_UNLOCK_ORDER.size() else 6.0)
		return
	transition_clock += delta
	if transition_clock >= TRANSITION_TIME:
		transition_clock = 0.0
		if transition_phase == "close":
			if transition_target == "playing" and state == "intro":
				planet_spin_remaining = PLANET_SPIN_TIME
				play_sound("planet_spin")
			if transition_target == "tutorial":
				start_tutorial()
			elif transition_target == "intro":
				start_round(transition_level)
				intro_clock = 0.0
			elif transition_target == "menu" or (transition_target == "level_select" and state == "paused"):
				start_round()
			state = "playing" if transition_target == "tutorial" else transition_target
			set_result_bgm(state in ["lost", "complete"])
			transition_phase = "reveal"
		else:
			transition_phase = ""
	if layout_size != Vector2.ZERO:
		update_layout(layout_size)

func intro_kind() -> String:
	var regular_number := regular_level_number(level)
	return UFO_UNLOCK_ORDER[posmod(regular_number - 1, UFO_UNLOCK_ORDER.size())]

func regular_level_number(number: int) -> int:
	# Boss stages occupy their own progression slot and never introduce a UFO.
	return maxi(1, number - number / 5)

func introduced_ufo_kind() -> String:
	return "" if is_boss_level() else intro_kind()

func screen_planet_center() -> Vector2:
	if visible_state() == "menu":
		return title_center()
	if visible_state() == "intro":
		return Vector2(layout_size.x * 0.5, layout_size.y * 0.68)
	if visible_state() in ["play_menu", "level_select"]:
		return Vector2(layout_size.x * 0.5, 40)
	return world_transform * CENTER

func configure_viewport() -> void:
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	# Layout in CSS pixels on the web, independent of the phone's pixel density.
	var logical_size := Vector2(get_window().size)
	if OS.has_feature("web"):
		var css_size = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify([document.getElementById('canvas').clientWidth, document.getElementById('canvas').clientHeight])")))
		if css_size != null and css_size[0] > 0 and css_size[1] > 0:
			logical_size = Vector2(css_size[0], css_size[1])
	elif OS.has_feature("android") or OS.has_feature("ios"):
		logical_size /= maxf(1.0, DisplayServer.screen_get_dpi() / 160.0)
	logical_size /= maxf(1.0, minf(logical_size.x / 1200.0, logical_size.y / 800.0))
	if get_window().content_scale_size != Vector2i(logical_size):
		get_window().content_scale_size = Vector2i(logical_size)
	update_layout(logical_size)

func update_layout(viewport_size: Vector2) -> void:
	orientation_blocked = viewport_size.x >= viewport_size.y
	if orientation_blocked:
		cancel_sketch()
		if state == "playing":
			state = "paused"
			transition_phase = ""
		return
	if layout_size != Vector2.ZERO and not layout_size.is_equal_approx(viewport_size):
		cancel_sketch()
	layout_size = viewport_size
	compact_layout = viewport_size.x < 1100.0 or viewport_size.y < 740.0
	portrait_layout = true
	var w := viewport_size.x
	var h := viewport_size.y
	var screen_state := visible_state()
	toolbar_rect = Rect2(0, h - TOOLBAR_HEIGHT, w, TOOLBAR_HEIGHT)
	var play_size := Vector2(w, maxf(1, h - TOOLBAR_HEIGHT))
	var angle := PI / 2.0
	var oriented_size := Vector2(BASE_ARENA.size.y, BASE_ARENA.size.x)
	var factor := minf(play_size.x / oriented_size.x, play_size.y / oriented_size.y)
	world_transform = Transform2D(angle, Vector2.ONE * factor, 0.0, Vector2.ZERO)
	world_transform.origin = play_size * 0.5 - world_transform * CENTER
	screen_arena = Rect2(Vector2.ZERO, play_size)
	# Expand the world to the window edges, preserving uniform art/physics scale.
	var a := screen_to_world(Vector2.ZERO)
	var b := screen_to_world(play_size)
	ARENA = Rect2(a.min(b), (a - b).abs())
	if boss_alive():
		var boss_area := ARENA.grow(-BOSS_RADIUS - BOSS_EDGE_PADDING)
		boss.pos = boss.pos.clamp(boss_area.position, boss_area.end)
	update_hud_layout(w)
	overlay_text = "PAUSED" if screen_state == "paused" else "GAME OVER  /  %s  /  %d BONKS" % [survival_time(), bonks] if screen_state == "lost" else "Draw barriers. Crash UFOs."
	var action := "RESUME" if state == "paused" else "RETRY" if state == "lost" else "PLAY"
	var button_width := ui_width(action, 16) + 48
	var restart_width := ui_width("RESTART", 14) + 44
	var extra_width := restart_width + 6 if state == "paused" else 0.0
	var panel_width := minf(w - 32, ui_width(overlay_text) + 32)
	var center := viewport_size * 0.5
	var left := (w - button_width - extra_width) * 0.5
	overlay_card = Rect2(Vector2((w - panel_width) * 0.5, center.y - 52), Vector2(panel_width, 44))
	restart_button = Rect2(left, center.y + 8, restart_width, 44)
	start_button = Rect2(left + extra_width, center.y + 8, button_width, 44)
	var settings_size := Vector2(minf(w - 24, 330), minf(h - 24, 360))
	settings_card = Rect2((viewport_size - settings_size) * 0.5, settings_size)
	bgm_slider = Rect2(settings_card.position.x + 28, settings_card.position.y + 70, settings_card.size.x - 56, 52)
	effects_slider = Rect2(settings_card.position.x + 28, settings_card.position.y + 148, settings_card.size.x - 56, 52)
	mute_button = Rect2(settings_card.position.x + 20, settings_card.position.y + 224, settings_card.size.x - 40, 44)
	close_settings_button = Rect2(settings_card.position.x + 20, settings_card.position.y + 282, settings_card.size.x - 40, 44)
	if screen_state == "menu":
		var unit := title_scale()
		var button_size := Vector2(clampf(220 * unit, 160, 300), clampf(56 * unit, 44, 68))
		start_button = Rect2(Vector2(w * 0.5 - button_size.x * 0.5, title_center().y + 178 * unit), button_size)
		settings_button = Rect2(Vector2(w - 60, 16), Vector2(44, 44))
	elif screen_state == "paused":
		var card_size := Vector2(minf(w - 24, 360), minf(h - 16, 350))
		overlay_card = Rect2((viewport_size - card_size) * 0.5, card_size)
		var button_size := Vector2(card_size.x - 32, 44)
		start_button = Rect2(overlay_card.position + Vector2(16, card_size.y - 266), button_size)
		restart_button = Rect2(start_button.position + Vector2(0, 50), button_size)
		select_level_button = Rect2(start_button.position + Vector2(0, 100), button_size)
		settings_button = Rect2(start_button.position + Vector2(0, 150), button_size)
		title_button = Rect2(start_button.position + Vector2(0, 200), button_size)
	elif screen_state == "lost":
		var card_size := Vector2(minf(w - 24, 400), minf(h - 16, 330))
		overlay_card = Rect2((viewport_size - card_size) * 0.5, card_size)
		var button_size := Vector2(card_size.x - 32, 44)
		title_button = Rect2(overlay_card.position + Vector2(16, card_size.y - 56), button_size)
		start_button = Rect2(title_button.position - Vector2(0, 50), button_size)
	elif screen_state == "complete":
		var card_size := Vector2(minf(w - 24, 400), minf(h - 16, 370))
		overlay_card = Rect2((viewport_size - card_size) * 0.5, card_size)
		var button_size := Vector2(card_size.x - 32, 44)
		title_button = Rect2(overlay_card.position + Vector2(16, card_size.y - 56), button_size)
		next_level_button = Rect2(title_button.position - Vector2(0, 50), button_size)
		start_button = Rect2(next_level_button.position - Vector2(0, 50), button_size)
	skip_button = Rect2(Vector2(w * 0.5 - 90, h - 66), Vector2(180, 48))
	if screen_state == "play_menu":
		var menu_width := minf(w - 32, 320)
		var menu_left := (w - menu_width) * 0.5
		var menu_top := maxf(76, h * 0.5 - 65)
		beginning_button = Rect2(menu_left, menu_top, menu_width, 46)
		continue_button = Rect2(menu_left, menu_top + 54, menu_width, 46)
		select_level_button = Rect2(menu_left, menu_top + 108, menu_width, 46)
		back_button = Rect2(w * 0.5 - 80, h - 54, 160, 44)
	elif screen_state == "level_select":
		level_buttons.clear()
		var grid_width := minf(w - 32, 600)
		var tile_width := (grid_width - 12) / 2.0
		var tile_height := minf(96, (h - 190) / 3.0)
		var grid_top := 136.0
		for i in range(LEVELS_PER_PAGE):
			var number := level_page * LEVELS_PER_PAGE + i + 1
			level_buttons[number] = Rect2((w - grid_width) * 0.5 + (i % 2) * (tile_width + 12), grid_top + (i / 2) * (tile_height + 10), tile_width, tile_height)
		back_button = Rect2(w * 0.5 - 60, h - 54, 120, 44)
		previous_page_button = Rect2(12, h - 54, 64, 44)
		next_page_button = Rect2(w - 76, h - 54, 64, 44)
	if tutorial_active:
		if tutorial_stage in [1, 2, 3, 4, 5, 6]:
			tutorial_card = Rect2(12, 12, w - 24, 94)
			tutorial_button = Rect2()
		else:
			var tutorial_size := Vector2(minf(w - 24, 410), minf(h - 24, 430))
			tutorial_card = Rect2((viewport_size - tutorial_size) * 0.5, tutorial_size)
			tutorial_button = Rect2(tutorial_card.position + Vector2(18, tutorial_card.size.y - 62), Vector2(tutorial_card.size.x - 36, 46))

func title_scale() -> float:
	return minf(layout_size.x / 440.0, layout_size.y / 680.0)

func title_center() -> Vector2:
	return layout_size * 0.5 + Vector2(0, 20 * title_scale())

func ui_width(value: String, size: int = 14) -> float:
	return ceilf(ui_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)

func hud_text(key: String) -> String:
	match key:
		"time": return "LVL %d  %s" % [current_level(), level_time()]
		"bonks": return "BONKS %d" % bonks
		"record": return "HIGH %d" % highest_bonks
		"ink": return "INK %.0f%%" % (remaining_ink_ratio() * 100.0)
	return ""

func remaining_ink_ratio() -> float:
	var pending := Route.length_of(sketch) if drawing else 0.0
	return clampf((available_ink() - pending) / BUDGET, 0.0, 1.0)

func update_hud_layout(width: float) -> void:
	hud_cards.clear()
	hud_slim = true
	hud_tiny = false
	hud_font_size = 16
	var top := toolbar_rect.position.y + 10
	var side_margin := 12.0
	var gap := 8.0
	var card_width := (width - side_margin * 2.0 - gap * 2.0) / 3.0
	var keys := ["time", "bonks", "record"]
	for i in range(3):
		hud_cards[keys[i]] = Rect2(side_margin + i * (card_width + gap), top, card_width, 38)
	var second_top := top + 46.0
	var health_width := 80.0 if width >= 360.0 else 68.0
	var bomb_width := 84.0
	var pause_width := 48.0
	var ink_width := width - side_margin * 2.0 - gap * 3.0 - health_width - bomb_width - pause_width
	hud_cards["health"] = Rect2(side_margin, second_top, health_width, 48)
	hud_cards["ink"] = Rect2(side_margin + health_width + gap, second_top, ink_width, 48)
	bomb_button = Rect2(hud_cards.ink.end.x + gap, second_top, bomb_width, 48)
	pause_button = Rect2(bomb_button.end.x + gap, second_top, pause_width, 48)
	hud_rect = Rect2(side_margin, top, width - side_margin * 2.0, 94)

func hud_value(key: String) -> String:
	if key == "time":
		return level_time()
	if key == "ink":
		return hud_text(key).trim_prefix("INK ")
	var value := highest_bonks if key == "record" else bonks
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (value / 1000.0)
	return str(value)

func hud_has_point(point: Vector2) -> bool:
	if toolbar_rect.has_point(point):
		return true
	for rect: Rect2 in hud_cards.values():
		if rect.grow(2).has_point(point):
			return true
	return bomb_button.has_point(point) or pause_button.has_point(point)

func screen_to_world(point: Vector2) -> Vector2:
	return world_transform.affine_inverse() * point

func load_highest_bonks() -> void:
	if bonk_save_path.is_empty():
		return
	var save := ConfigFile.new()
	if save.load(bonk_save_path) == OK:
		var value = save.get_value("bonks", "highest", 0)
		if value is int and value >= 0:
			highest_bonks = maxi(highest_bonks, value)

func save_highest_bonks() -> void:
	if developer_unlocked:
		return
	if bonks <= highest_bonks:
		return
	highest_bonks = bonks
	if bonk_save_path.is_empty():
		return
	var save := ConfigFile.new()
	save.set_value("bonks", "highest", highest_bonks)
	var error := save.save(bonk_save_path)
	if error != OK:
		push_warning("Could not save highest bonk count: %s" % error_string(error))

func register_ufo_destructions(count: int) -> void:
	hits += count

func register_bonk() -> void:
	bonks += 1
	save_highest_bonks()
	if space_bombs >= MAX_SPACE_BOMBS:
		return
	bomb_bonk_progress += 1
	if bomb_bonk_progress >= BOMB_BONKS_REQUIRED:
		bomb_bonk_progress = 0
		space_bombs += 1
		play_sound("ready")
		notify("SPACE BOMB READY!")
	if tutorial_active and tutorial_stage == 3:
		tutorial_stage = 4
		tutorial_setup_pending = true

func bomb_progress_text() -> String:
	if space_bombs >= MAX_SPACE_BOMBS:
		return "x%d MAX" % space_bombs
	if space_bombs > 0:
		return "x%d %d/%d" % [space_bombs, bomb_bonk_progress, BOMB_BONKS_REQUIRED]
	return "%d/%d" % [bomb_bonk_progress, BOMB_BONKS_REQUIRED]

func use_space_bomb() -> bool:
	if planet_spin_remaining > 0:
		return false
	if state != "playing" or space_bombs <= 0:
		if state == "playing":
			notify("Cause %d more UFO bonks" % (BOMB_BONKS_REQUIRED - bomb_bonk_progress))
		return false
	cancel_sketch()
	space_bombs -= 1
	bomb_flash = BOMB_FLASH_TIME
	play_sound("bomb")
	if boss_alive() and CENTER.distance_to(boss.pos) <= BOMB_RADIUS + BOSS_RADIUS:
		damage_boss(2)
	var destroyed := 0
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if CENTER.distance_to(h.pos) <= BOMB_RADIUS + h.radius:
			burst(h.pos, GOLD)
			hazards.remove_at(i)
			destroyed += 1
	if destroyed > 0:
		register_ufo_destructions(destroyed)
		popups.append({"pos": CENTER + Vector2(0, -72), "text": "BLAST x%d" % destroyed, "color": GOLD, "life": 1.0})
	else:
		notify("SPACE BOMB DEPLOYED")
	if tutorial_active and tutorial_stage == 4:
		tutorial_stage = 5
		setup_tutorial_stage()
	return true

func start_round(level_number: int = 1) -> void:
	transition_phase = ""
	tutorial_active = false
	tutorial_stage = 0
	tutorial_setup_pending = false
	tutorial_stage_delay = 0.0
	level = maxi(1, level_number)
	planet_spin_remaining = 0.0
	boss = {}
	if is_boss_level():
		boss = {"pos": boss_position(), "health": 12, "max_health": 12, "clock": 2.0,
			"velocity": Vector2(72, 46), "move_clock": 0.0, "flash": 0.0,
			"target": boss_position(), "speed": 84.0}
	barriers.clear()
	hazards.clear()
	sparks.clear()
	popups.clear()
	shockwaves.clear()
	sketch.clear()
	drawing = false
	active_touch_index = -1
	elapsed = 0.0
	spawn_clock = 2.0
	wave = 0
	health = MAX_HEALTH
	health_pickup.clear()
	health_pickup_clock = rng.randf_range(HEALTH_PICKUP_FIRST_MIN, HEALTH_PICKUP_FIRST_MAX)
	bonks = 0
	hits = 0
	total_ufos_spawned = 0
	earned_stars = 0
	space_bombs = 0
	bomb_bonk_progress = 0
	bomb_flash = 0.0
	redraws = 0
	flash = 0.0
	state = "playing"
	set_result_bgm(false)
	message = ""
	message_time = 0.0
	if boss_alive():
		boss.pos = boss_position()

func start_tutorial() -> void:
	start_round(1)
	tutorial_active = true
	tutorial_stage = 0
	if layout_size != Vector2.ZERO:
		update_layout(layout_size)

func finish_tutorial() -> void:
	tutorial_active = false
	tutorial_setup_pending = false
	tutorial_stage_delay = 0.0
	change_screen("intro", 1)

func spawn_tutorial_rebound(barrier: Dictionary) -> void:
	hazards.clear()
	var points: PackedVector2Array = barrier.points
	var segment_start := points[0]
	var segment_end := points[1]
	var longest := segment_start.distance_squared_to(segment_end)
	for i in range(1, points.size()):
		var length_squared := points[i - 1].distance_squared_to(points[i])
		if length_squared > longest:
			longest = length_squared
			segment_start = points[i - 1]
			segment_end = points[i]
	var midpoint := (segment_start + segment_end) * 0.5
	var normal := (segment_end - segment_start).orthogonal().normalized()
	var flight_area := ARENA.grow(-36.0)
	var first := midpoint + normal * 74.0
	var second := midpoint - normal * 74.0
	var spawn_at := first if flight_area.has_point(first) and first.distance_to(CENTER) >= second.distance_to(CENTER) else second
	spawn_at = spawn_at.clamp(flight_area.position, flight_area.end)
	var ufo := make_ufo("saucer", spawn_at, 58.0)
	ufo.vel = (midpoint - spawn_at).normalized() * 58.0
	ufo.warmup = 0.0
	hazards.append(ufo)
	total_ufos_spawned += 1

func setup_tutorial_stage() -> void:
	tutorial_setup_pending = false
	cancel_sketch()
	match tutorial_stage:
		3:
			barriers.clear()
			hazards.clear()
			var stunned := make_ufo("saucer", CENTER + Vector2(-130, -145), 40.0)
			stunned.vel = Vector2.RIGHT * 120.0
			stunned.warmup = 0.0
			stunned.redirected = true
			stunned.recovery = UFO_RECOVERY_TIME
			var target := make_ufo("scout", CENTER + Vector2(80, -145), 0.0)
			target.vel = Vector2.ZERO
			target.warmup = 0.0
			hazards = [stunned, target]
			bomb_bonk_progress = BOMB_BONKS_REQUIRED - 1
			tutorial_stage_delay = 2.5
		4:
			barriers.clear()
			hazards.clear()
			for offset in [Vector2(-120, -80), Vector2(120, -70), Vector2(0, 155)]:
				var target := make_ufo("saucer", CENTER + offset, 0.0)
				target.vel = Vector2.ZERO
				target.warmup = 0.0
				hazards.append(target)
		5:
			barriers.clear()
			hazards.clear()
			var attacker := make_ufo("saucer", CENTER + Vector2(0, -96), 62.0)
			attacker.vel = Vector2.DOWN * 62.0
			attacker.warmup = 0.0
			hazards.append(attacker)
			tutorial_stage_delay = 2.5
		6:
			hazards.clear()
			health_pickup = {"pos": CENTER + Vector2(0, -130), "life": HEALTH_PICKUP_LIFETIME}
	if layout_size != Vector2.ZERO:
		update_layout(layout_size)

func notify(value: String) -> void:
	message = value
	message_time = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		transition_phase = ""
		cancel_sketch()
		state = "paused"

func cancel_sketch() -> void:
	drawing = false
	active_touch_index = -1
	sketch.clear()

func handle_primary_press(point: Vector2) -> void:
	if orientation_blocked:
		return
	if not transition_phase.is_empty():
		return
	if layout_size != Vector2.ZERO:
		update_layout(layout_size)
	if state in ["menu", "paused"] and settings_open:
		if bgm_slider.has_point(point):
			active_volume_slider = "bgm"
			set_volume_from_slider(active_volume_slider, point)
		elif effects_slider.has_point(point):
			active_volume_slider = "effects"
			set_volume_from_slider(active_volume_slider, point)
		elif mute_button.has_point(point):
			toggle_game_mute()
			play_sound("ui")
		elif close_settings_button.has_point(point):
			active_volume_slider = ""
			settings_open = false
			play_sound("ui")
		return
	if state == "menu":
		if settings_button.has_point(point):
			settings_open = true
			play_sound("ui")
			return
	if state == "play_menu":
		if beginning_button.has_point(point):
			change_screen("tutorial", 1)
		elif continue_button.has_point(point):
			change_screen("intro", highest_unlocked_level)
		elif select_level_button.has_point(point):
			level_page = (highest_unlocked_level - 1) / LEVELS_PER_PAGE
			change_screen("level_select")
		elif back_button.has_point(point):
			change_screen("menu")
		return
	if tutorial_active:
		if tutorial_stage == 0 and tutorial_button.has_point(point):
			tutorial_stage = 1
			play_sound("ui")
			update_layout(layout_size)
			return
		if tutorial_stage == 7 and tutorial_button.has_point(point):
			finish_tutorial()
			return
		if tutorial_stage == 4 and bomb_button.has_point(point):
			use_space_bomb()
			return
		if tutorial_stage == 6 and not health_pickup.is_empty() and collect_health_pickup(point):
			return
		if tutorial_stage != 1 or tutorial_card.has_point(point) or hud_has_point(point):
			return
	if state == "level_select":
		if back_button.has_point(point):
			change_screen("play_menu")
		elif previous_page_button.has_point(point) and level_page > 0:
			level_page -= 1
		elif next_page_button.has_point(point) and level_page + 1 < level_page_count():
			level_page += 1
		else:
			for number in level_buttons:
				if level_buttons[number].has_point(point) and is_level_unlocked(number):
					change_screen("intro", number)
					break
		return
	if state == "complete":
		if start_button.has_point(point):
			change_screen("intro", level)
		elif next_level_button.has_point(point):
			change_screen("intro", level + 1)
		elif title_button.has_point(point):
			change_screen("menu")
		return
	if state == "intro":
		if skip_button.has_point(point):
			change_screen("playing")
		return
	if state == "paused":
		if settings_button.has_point(point):
			settings_open = true
			play_sound("ui")
			return
		if select_level_button.has_point(point):
			level_page = (level - 1) / LEVELS_PER_PAGE
			change_screen("level_select")
			return
		if title_button.has_point(point):
			change_screen("menu")
			return
		if restart_button.has_point(point):
			change_screen("intro", level)
			return
		if start_button.has_point(point):
			change_screen("playing")
			return
		# The pause card owns all input. Consume taps on the persistent HUD
		# (and anywhere else behind the card) until the player resumes.
		return
	if state == "lost":
		if start_button.has_point(point):
			change_screen("intro", level)
		elif title_button.has_point(point):
			change_screen("menu")
		return
	if state == "menu":
		if start_button.has_point(point):
			change_screen("play_menu", level)
			return
	if pause_button.has_point(point) and state == "playing":
		change_screen("paused")
		return
	if planet_spin_remaining > 0:
		return
	if bomb_button.has_point(point) and state == "playing":
		use_space_bomb()
		return
	if state == "playing" and collect_health_pickup(point):
		return
	if state == "playing" and screen_arena.has_point(point) and not hud_has_point(point):
		begin_sketch(screen_to_world(point))

func handle_touch_press(point: Vector2, index: int) -> void:
	if active_touch_index != -1 and active_touch_index != index:
		if state == "playing" and drawing:
			cancel_sketch()
			message_time = 0.0
		return
	handle_primary_press(point)
	if state == "playing" and drawing and active_touch_index == -1:
		active_touch_index = index

func handle_touch_release(point: Vector2, index: int) -> void:
	if state in ["menu", "paused"] and settings_open and not active_volume_slider.is_empty():
		set_volume_from_slider(active_volume_slider, point, true)
		active_volume_slider = ""
		play_sound("ui")
		return
	if index != active_touch_index:
		return
	if state == "playing" and drawing:
		append_sketch_point(screen_to_world(point))
		if drawing:
			finish_sketch()
	active_touch_index = -1

func _input(event: InputEvent) -> void:
	if orientation_blocked:
		return
	if not transition_phase.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if state in ["menu", "paused"] and settings_open:
			if event.keycode == KEY_LEFT:
				set_audio_channel_volume("effects", effects_volume - 0.1)
				play_sound("ui", 0.85)
			elif event.keycode == KEY_RIGHT:
				set_audio_channel_volume("effects", effects_volume + 0.1)
				play_sound("ui", 1.15)
			elif event.keycode == KEY_M:
				toggle_game_mute()
				play_sound("ui")
			elif event.keycode in [KEY_ENTER, KEY_ESCAPE]:
				settings_open = false
				play_sound("ui")
			return
		if tutorial_active:
			if tutorial_stage in [0, 7] and event.keycode in [KEY_ENTER, KEY_SPACE]:
				handle_primary_press(tutorial_button.get_center())
			return
		enter_developer_code(event)
		if not transition_phase.is_empty():
			return
		if event.keycode == KEY_ENTER and state == "menu":
			change_screen("play_menu")
		elif event.keycode == KEY_ENTER and state == "play_menu":
			change_screen("intro", highest_unlocked_level)
		elif event.keycode == KEY_ESCAPE and state in ["play_menu", "level_select"]:
			change_screen("menu" if state == "play_menu" else "play_menu")
		elif event.keycode == KEY_ENTER and state == "lost":
			change_screen("intro", level)
		elif event.keycode == KEY_ENTER and state == "complete":
			change_screen("intro", level + 1)
		elif event.keycode in [KEY_ENTER, KEY_ESCAPE, KEY_SPACE] and state == "intro":
			change_screen("playing")
		elif event.keycode == KEY_R and state in ["playing", "paused", "lost", "complete", "intro"]:
			change_screen("intro", level)
		elif event.keycode in [KEY_P, KEY_ESCAPE] and state in ["playing", "paused"]:
			change_screen("paused" if state == "playing" else "playing")
		elif event.keycode == KEY_B and state == "playing":
			use_space_bomb()
	if event is InputEventScreenTouch:
		var touch_point: Vector2 = event.position
		if event.canceled:
			if state in ["menu", "paused"] and settings_open and not active_volume_slider.is_empty():
				active_volume_slider = ""
				save_audio_settings()
			elif event.index == active_touch_index:
				cancel_sketch()
		elif event.pressed:
			handle_touch_press(touch_point, event.index)
		else:
			handle_touch_release(touch_point, event.index)
	if event is InputEventScreenDrag:
		if state in ["menu", "paused"] and settings_open and not active_volume_slider.is_empty():
			set_volume_from_slider(active_volume_slider, event.position)
		elif state == "playing" and drawing and event.index == active_touch_index:
			append_sketch_point(screen_to_world(event.position))
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and active_touch_index == -1:
		var point: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_sketch()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				handle_primary_press(point)
			elif state in ["menu", "paused"] and settings_open and not active_volume_slider.is_empty():
				set_volume_from_slider(active_volume_slider, point, true)
				active_volume_slider = ""
				play_sound("ui")
			elif drawing and active_touch_index == -1:
				append_sketch_point(screen_to_world(point))
				if drawing:
					finish_sketch()
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and active_touch_index == -1:
		if state in ["menu", "paused"] and settings_open and not active_volume_slider.is_empty():
			set_volume_from_slider(active_volume_slider, event.position)
		elif drawing and state == "playing":
			append_sketch_point(screen_to_world(event.position))

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
		notify("Ink refills in %.1fs" % next_barrier_expiry())
		return
	drawing = true
	sketch = PackedVector2Array([point])
	play_sound("barrier")

func append_sketch_point(point: Vector2) -> void:
	if hud_has_point(world_transform * point):
		cancel_sketch()
		return
	point = point.clamp(ARENA.position, ARENA.end)
	if sketch[-1].distance_to(point) >= 6.0:
		var remaining := available_ink() - Route.length_of(sketch)
		if remaining > 0.5:
			sketch.append(sketch[-1].move_toward(point, remaining))

func sketch_error() -> String:
	if Route.length_of(sketch) > available_ink() + 0.001:
		return "Not enough ink"
	var error := Route.validate_barrier(sketch, CENTER, 58.0, available_ink() + 0.001)
	if error != "":
		return error
	var paths: Array[PackedVector2Array] = []
	for barrier in barriers:
		paths.append(barrier.points)
	error = Route.validate_spacing(sketch, paths, BARRIER_HALF_WIDTH * 2.0)
	if error != "":
		return error
	paths.append(sketch)
	if Route.planet_is_enclosed(paths, CENTER):
		return "Leave a gap"
	return ""

func finish_sketch() -> void:
	drawing = false
	var error := sketch_error()
	if error != "":
		play_sound("error")
		notify(error)
	else:
		var barrier := {"points": sketch.duplicate(), "length": Route.length_of(sketch), "life": BARRIER_LIFETIME}
		BarrierMotion.prepare(barrier)
		barriers.append(barrier)
		redraws += 1
		message_time = 0.0
		if tutorial_active and tutorial_stage == 1:
			tutorial_stage = 2
			tutorial_stage_delay = 2.0
			spawn_tutorial_rebound(barrier)
			play_sound("ready")
			if layout_size != Vector2.ZERO:
				update_layout(layout_size)
	sketch.clear()

func survival_time() -> String:
	var seconds := int(elapsed)
	if seconds >= 3600:
		return "%d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func current_level() -> int:
	return level

func level_time_remaining() -> float:
	return maxf(0.0, LEVEL_DURATION - elapsed)

func level_time() -> String:
	if tutorial_active:
		return "GUIDE"
	if is_boss_level():
		return "BOSS"
	var seconds := ceili(level_time_remaining())
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func unlocked_ufo_types() -> Array[String]:
	var types: Array[String] = []
	var unlocked_count := mini(regular_level_number(current_level()), UFO_UNLOCK_ORDER.size())
	for i in range(unlocked_count):
		types.append(UFO_UNLOCK_ORDER[i])
	return types

func make_ufo(kind: String, pos: Vector2, base_speed: float) -> Dictionary:
	var stats: Dictionary = UFO_TYPES[kind]
	return {"type": kind, "pos": pos, "vel": (CENTER - pos).normalized() * base_speed * stats.speed,
		"cruise_speed": base_speed * stats.speed,
		"warmup": 1.2, "radius": stats.radius, "damage": stats.damage, "look": stats.look,
		"dodge_available": kind == "dodger", "phase_barrier": {},
		"cloak_clock": 0.0,
		"redirected": false, "recovery": 0.0, "flight_time": 0.0, "weave_phase": rng.randf_range(0, TAU)}

func spawn_attack() -> void:
	if hazards.size() >= MAX_UFOS:
		return
	wave += 1
	var phase := int(elapsed / 15.0) % 3
	var angle := rng.randf_range(0, TAU)
	var difficulty_time := (level - 1) * LEVEL_DURATION + elapsed
	var count := mini(2 + int(minf(difficulty_time, 180.0) / 60.0), MAX_UFOS - hazards.size())
	# Late-game waves taper from five ships down to one as the arena fills.
	# This preserves pressure without covering the playfield in overlapping art.
	if hazards.size() >= CROWD_WAVE_SHRINK_AT:
		var crowd_wave_cap := maxi(1, 4 - (hazards.size() - CROWD_WAVE_SHRINK_AT) / 4)
		count = mini(count, crowd_wave_cap)
	var types := unlocked_ufo_types()
	for i in range(count):
		var direction := angle + (i * 0.15 if phase == 0 else (i % 2) * PI + (i / 2) * 0.18 if phase == 1 else i * TAU / count)
		var unit := Vector2.from_angle(direction)
		var extent := ARENA.size * 0.5 - Vector2(24, 24)
		var edge := minf(extent.x / maxf(absf(unit.x), 0.001), extent.y / maxf(absf(unit.y), 0.001))
		var pos := CENTER + unit * edge
		var speed := minf(MAX_BASE_SPEED, rng.randf_range(32, 43) + difficulty_time * 0.16)
		hazards.append(make_ufo(types[(wave + i - 1) % types.size()], pos, speed))
	total_ufos_spawned += count

func next_spawn_delay() -> float:
	var delay := maxf(2.3, 4.5 - ((level - 1) * LEVEL_DURATION + elapsed) * 0.02)
	if hazards.size() >= CROWD_SLOWDOWN_AT:
		var crowd_extra := (hazards.size() - CROWD_SLOWDOWN_AT) * 0.12
		delay *= CROWD_SPAWN_MULTIPLIER + crowd_extra
	return delay

func is_boss_level() -> bool:
	return level % 5 == 0

func boss_alive() -> bool:
	return not boss.is_empty() and boss.health > 0

func damage_boss(amount: int) -> void:
	if not boss_alive():
		return
	boss.health = maxi(0, boss.health - amount)
	boss.flash = 0.3
	burst(boss.pos, GOLD)
	if boss.health == 0:
		play_sound("boss_defeat")
		notify("MOTHERSHIP DESTROYED!")
	else:
		play_sound("boss_hit")

func advance_boss(delta: float) -> void:
	if not boss_alive():
		return
	boss.flash = maxf(0.0, boss.flash - delta)
	boss.move_clock -= delta
	if boss.move_clock <= 0.0 or boss.pos.distance_to(boss.target) < 30.0:
		boss.move_clock = rng.randf_range(2.2, 4.0)
		boss.target = random_boss_destination()
		boss.speed = rng.randf_range(BOSS_MIN_SPEED, BOSS_MAX_SPEED)
	var desired_direction: Vector2 = (boss.target - boss.pos).normalized()
	var from_planet: Vector2 = boss.pos - CENTER
	var exclusion_radius := BOSS_RADIUS + PLANET_COLLISION_RADIUS + BOSS_PLANET_CLEARANCE
	# Start bending around the planet before contact instead of snapping away from it.
	var avoidance_range := exclusion_radius + 95.0
	if from_planet.length() < avoidance_range:
		var outward := from_planet.normalized() if not from_planet.is_zero_approx() else Vector2.UP
		var approach := maxf(0.0, -desired_direction.dot(outward))
		var avoidance_weight := (1.0 - from_planet.length() / avoidance_range) * (1.25 + approach)
		var tangent := outward.orthogonal()
		if tangent.dot(desired_direction) < 0.0:
			tangent = -tangent
		desired_direction = (desired_direction + (outward + tangent * 0.85) * avoidance_weight).normalized()
	var desired_velocity := desired_direction * float(boss.speed)
	boss.velocity = boss.velocity.move_toward(desired_velocity, BOSS_STEERING_ACCELERATION * delta)
	boss.pos += boss.velocity * delta
	var flight_area := ARENA.grow(-BOSS_RADIUS - BOSS_EDGE_PADDING)
	var bounded: Vector2 = boss.pos.clamp(flight_area.position, flight_area.end)
	if not boss.pos.is_equal_approx(bounded):
		if not is_equal_approx(boss.pos.x, bounded.x):
			boss.velocity.x = 0.0
		if not is_equal_approx(boss.pos.y, bounded.y):
			boss.velocity.y = 0.0
		boss.pos = bounded
		boss.move_clock = 0.0
	# This final constraint makes overlap impossible even after a large physics step.
	from_planet = boss.pos - CENTER
	if from_planet.length() < exclusion_radius:
		var outward := from_planet.normalized() if not from_planet.is_zero_approx() else Vector2.UP
		boss.pos = CENTER + outward * exclusion_radius
		var current_velocity: Vector2 = boss.velocity
		var inward_speed: float = current_velocity.dot(outward)
		if inward_speed < 0.0:
			boss.velocity = current_velocity - outward * inward_speed
		boss.move_clock = 0.0
	boss.clock -= delta
	if boss.clock <= 0.0:
		boss.clock = 4.0
		var roster := unlocked_ufo_types()
		var release_count := mini(2, MAX_UFOS - hazards.size())
		for i in range(release_count):
			var towards: Vector2 = (CENTER - boss.pos).normalized()
			var at: Vector2 = boss.pos + towards * 48 + towards.orthogonal() * (i * 28 - 14)
			hazards.append(make_ufo(roster[rng.randi_range(0, roster.size() - 1)], at, 40.0))
		total_ufos_spawned += release_count

func boss_position() -> Vector2:
	return Vector2(CENTER.x, ARENA.position.y + BOSS_RADIUS + BOSS_EDGE_PADDING)

func random_boss_destination() -> Vector2:
	var flight_area := ARENA.grow(-BOSS_RADIUS - BOSS_EDGE_PADDING)
	var exclusion_radius := BOSS_RADIUS + PLANET_COLLISION_RADIUS + BOSS_PLANET_CLEARANCE + 45.0
	for attempt in range(16):
		var destination := Vector2(
			rng.randf_range(flight_area.position.x, flight_area.end.x),
			rng.randf_range(flight_area.position.y, flight_area.end.y))
		if destination.distance_to(CENTER) >= exclusion_radius:
			return destination
	# Every supported arena has room above the planet; this is a deterministic fallback.
	return Vector2(flight_area.position.x, flight_area.position.y)

func phantom_visible(h: Dictionary) -> bool:
	# Warnings and stunned pilots stay visible; invisibility never changes collisions.
	return h.get("type", "saucer") != "phantom" or h.warmup > 0 or h.get("recovery", 0.0) > 0 or fmod(h.get("cloak_clock", 0.0), 4.0) < 2.5

func reset_health_pickup_clock() -> void:
	health_pickup_clock = rng.randf_range(HEALTH_PICKUP_REPEAT_MIN, HEALTH_PICKUP_REPEAT_MAX)

func spawn_health_pickup() -> void:
	var area := ARENA.grow(-HEALTH_PICKUP_RADIUS - 12.0)
	var at := area.get_center()
	for attempt in range(16):
		at = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var clear_of_ufos := true
		for h in hazards:
			if at.distance_to(h.pos) < HEALTH_PICKUP_RADIUS + h.radius + 28.0:
				clear_of_ufos = false
				break
		if at.distance_to(CENTER) > 105.0 and clear_of_ufos:
			break
	health_pickup = {"pos": at, "life": HEALTH_PICKUP_LIFETIME}

func advance_health_pickup(delta: float) -> void:
	if not health_pickup.is_empty():
		health_pickup.life -= delta
		if health_pickup.life <= 0.0:
			health_pickup.clear()
			reset_health_pickup_clock()
		return
	health_pickup_clock = maxf(0.0, health_pickup_clock - delta)
	if health_pickup_clock <= 0.0 and health < MAX_HEALTH:
		spawn_health_pickup()

func collect_health_pickup(screen_point: Vector2) -> bool:
	if health_pickup.is_empty():
		return false
	var at: Vector2 = health_pickup.pos
	if screen_to_world(screen_point).distance_to(at) > HEALTH_PICKUP_RADIUS * 1.35:
		return false
	if health >= MAX_HEALTH:
		notify("Health is full")
		return true
	health = mini(MAX_HEALTH, health + 1)
	health_pickup.clear()
	reset_health_pickup_clock()
	burst(at, RED)
	play_sound("heal")
	popups.append({"pos": at + Vector2(0, -28), "text": "+1 HP", "color": RED, "life": 1.2})
	notify("PLANET REPAIRED!")
	if tutorial_active and tutorial_stage == 6:
		tutorial_stage = 7
		if layout_size != Vector2.ZERO:
			update_layout(layout_size)
	return true

func burst(pos: Vector2, color: Color) -> void:
	for i in range(10):
		sparks.append({"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(25, 130), "life": 0.5, "color": color})

func _physics_process(delta: float) -> void:
	if orientation_blocked or not transition_phase.is_empty() or planet_spin_remaining > 0:
		return
	if tutorial_active:
		if tutorial_setup_pending:
			setup_tutorial_stage()
		if tutorial_stage in [2, 3, 5]:
			if tutorial_stage_delay > 0.0:
				tutorial_stage_delay = maxf(0.0, tutorial_stage_delay - delta)
				return
			step_world(minf(delta, 0.1))
			if tutorial_setup_pending:
				setup_tutorial_stage()
		return
	if state == "playing":
		if not is_boss_level():
			delta = minf(delta, level_time_remaining())
		elapsed = elapsed + delta if is_boss_level() else minf(LEVEL_DURATION, elapsed + delta)
		message_time = maxf(0, message_time - delta)
		flash = maxf(0, flash - delta)
		bomb_flash = maxf(0, bomb_flash - delta)
		advance_boss(delta)
		step_world(delta)
		var level_won := (is_boss_level() and not boss_alive()) or (not is_boss_level() and elapsed >= LEVEL_DURATION)
		if state == "playing" and level_won:
			state = "complete"
			award_level_stars()
			set_result_bgm(true)
			play_sound("victory")
			unlock_next_level()
			save_level_progress()
			cancel_sketch()
			save_highest_bonks()
		if state == "playing":
			advance_health_pickup(delta)
		spawn_clock -= delta
		if state == "playing" and spawn_clock <= 0:
			spawn_attack()
			spawn_clock = next_spawn_delay()
		for i in range(sparks.size() - 1, -1, -1):
			sparks[i].pos += sparks[i].vel * delta
			sparks[i].life -= delta
			if sparks[i].life <= 0:
				sparks.remove_at(i)
		for i in range(popups.size() - 1, -1, -1):
			popups[i].pos.y -= delta * 22.0
			popups[i].life -= delta
			if popups[i].life <= 0.0:
				popups.remove_at(i)
		for i in range(shockwaves.size() - 1, -1, -1):
			shockwaves[i].life -= delta
			if shockwaves[i].life <= 0.0:
				shockwaves.remove_at(i)

func step_world(dt: float) -> void:
	# Recalculate after each slice: rebounds and shockwaves can accelerate UFOs.
	# Keep every physics movement at or below MAX_TRAVEL_PER_STEP.
	var remaining := dt
	while remaining > 0.0000001 and state == "playing":
		var fastest := 0.0
		for h in hazards:
			fastest = maxf(fastest, h.vel.length())
		var slice := minf(remaining, MAX_TRAVEL_PER_STEP / maxf(fastest, 1.0))
		age_barriers(slice)
		step_hazards(slice)
		remaining -= slice

func age_barriers(dt: float) -> void:
	for i in range(barriers.size() - 1, -1, -1):
		BarrierMotion.advance(barriers[i], dt)
		barriers[i].life -= dt
		if barriers[i].life <= 0.00001:
			barriers.remove_at(i)

func redirected_speed_limit(h: Dictionary) -> float:
	# Store the original speed, not the speed after earlier ricochets/blasts.
	# Older scripted hazards that lack a cruise_speed are initialized here.
	if not h.has("cruise_speed"):
		h.cruise_speed = h.vel.length()
	return float(h.cruise_speed) * REBOUND_SPEED_MULTIPLIER

func emit_shockwave(origin: Vector2) -> void:
	# Called only after a UFO-to-UFO bonk; never on a barrier impact.
	shockwaves.append({"pos": origin, "life": SHOCKWAVE_VISUAL_TIME})
	for h in hazards:
		if h.warmup > 0.0:
			continue
		var delta: Vector2 = h.pos - origin
		var distance := delta.length()
		if distance >= SHOCKWAVE_RADIUS:
			continue
		var direction := Vector2.RIGHT if distance < 0.001 else delta / distance
		# Outward velocity impulse: 85 px/s at the center, fading to 0 at 110 px.
		var impulse := SHOCKWAVE_PUSH_SPEED * (1.0 - distance / SHOCKWAVE_RADIUS)
		var speed_cap := maxf(redirected_speed_limit(h), SHOCKWAVE_PUSH_SPEED)
		h.vel = (h.vel + direction * impulse).limit_length(speed_cap)
		# A shockwave-redirected UFO can now trigger another bonk on contact.
		h.redirected = true
		# Preserve longer barrier stuns rather than cutting them to two seconds.
		h.recovery = maxf(float(h.get("recovery", 0.0)), SHOCKWAVE_STUN_TIME)

func reflect_hazard(h: Dictionary) -> void:
	if h.warmup > 0.0:
		return
	var phasing: Dictionary = h.get("phase_barrier", {})
	# Ignore only the spent charge's barrier until the entire hull clears it.
	# Other barriers still collide, and leaving never restores the charge.
	if not phasing.is_empty():
		var gap: float = h.pos.distance_to(Route.nearest(phasing.points, h.pos).point)
		if not barriers.has(phasing) or gap >= h.radius + BARRIER_HALF_WIDTH + 0.05:
			h.phase_barrier = {}
			phasing = {}
	if barriers.is_empty():
		return
	# Nearest contact handles both segment faces and rounded endpoints.
	# Repeat to separate a hazard from tight corners without a bounce cooldown.
	for contact in range(4):
		var nearest := {}
		var hit_barrier := {}
		var best := INF
		for barrier in barriers:
			if not phasing.is_empty() and barrier == phasing:
				continue
			var candidate := Route.nearest(barrier.points, h.pos)
			var distance: float = h.pos.distance_squared_to(candidate.point)
			if distance < best:
				best = distance
				nearest = candidate
				hit_barrier = barrier
		if nearest.is_empty():
			break
		var closest: Vector2 = nearest.point
		var offset: Vector2 = h.pos - closest
		var clearance: float = h.radius + BARRIER_HALF_WIDTH
		if offset.length_squared() >= clearance * clearance:
			break
		if h.get("dodge_available", false):
			h.dodge_available = false
			h.phase_barrier = hit_barrier
			phasing = hit_barrier
			popups.append({"pos": h.pos + Vector2(0, -26), "text": "DODGE!", "color": CYAN, "life": 0.8})
			continue
		var normal := offset.normalized()
		if normal.is_zero_approx():
			# A newly drawn barrier may pass exactly through a hazard center.
			normal = nearest.normal
			if h.vel.dot(normal) > 0.0:
				normal = -normal
		h.pos = closest + normal * (clearance + 0.05)
		if h.vel.dot(normal) < 0.0:
			BarrierMotion.impact(hit_barrier, nearest.distance, -normal, absf(h.vel.dot(normal)), h.radius / UFO_RADIUS)
			# Always target 3x original cruise speed; never multiply repeatedly.
			h.vel = h.vel.bounce(normal).normalized() * redirected_speed_limit(h)
			h.redirected = true
			h.recovery = UFO_RECOVERY_TIME
			burst(closest, CYAN)
			play_sound("bounce")
			if tutorial_active and tutorial_stage == 2:
				tutorial_stage = 3
				tutorial_setup_pending = true

func steer_ufo(h: Dictionary, dt: float) -> void:
	if not h.get("redirected", false):
		if h.get("type", "saucer") == "weaver":
			h.flight_time += dt
			var target: Vector2 = CENTER - h.pos
			var heading := target.angle() + sin(h.flight_time * 3.4 + h.weave_phase) * 0.65
			var turn := clampf(angle_difference(h.vel.angle(), heading), -2.8 * dt, 2.8 * dt)
			h.vel = h.vel.rotated(turn)
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
		h.cloak_clock = float(h.get("cloak_clock", 0.0)) + dt
		reflect_hazard(h)
		keep_ufo_in_arena(h)
	# Resolve pairs after all hazards move so array order cannot change motion.
	var destroyed := {}
	var shockwave_origins: Array[Vector2] = []
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
				var impact: Vector2 = (a.pos + b.pos) * 0.5
				burst(impact, GOLD)
				popups.append({"pos": impact + Vector2(0, -24), "text": "BONK!", "color": GOLD, "life": 1.1})
				shockwave_origins.append(impact)
				play_sound("bonk")
				register_bonk()
				register_ufo_destructions(2)
				break
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if destroyed.has(i):
			hazards.remove_at(i)
			continue
		if h.warmup > 0.0:
			continue
		if boss_alive() and h.get("redirected", false) and h.pos.distance_to(boss.pos) < BOSS_RADIUS + h.radius:
			hazards.remove_at(i)
			register_ufo_destructions(1)
			register_bonk()
			damage_boss(1)
			continue
		if CENTER.distance_to(h.pos) < 38.0 + h.radius:
			burst(h.pos, RED)
			hazards.remove_at(i)
			var damage: int = h.get("damage", 1)
			health = maxi(0, health - damage)
			popups.append({"pos": CENTER + Vector2(0, -54), "text": "-%d" % damage, "color": RED, "life": 1.0})
			flash = 0.4
			if tutorial_active and tutorial_stage == 5:
				tutorial_stage = 6
				tutorial_setup_pending = true
			if health <= 0:
				play_sound("defeat")
				state = "lost"
				set_result_bgm(true)
				drawing = false
				sketch.clear()
				return
			play_sound("hurt")
	# Remove all collided UFOs before applying impulses to survivors.
	# Newly redirected ships are eligible for collisions on the next step.
	for origin in shockwave_origins:
		emit_shockwave(origin)
