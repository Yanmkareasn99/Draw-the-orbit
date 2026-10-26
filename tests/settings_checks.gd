extends SceneTree

const Game = preload("res://scripts/game.gd")
const GameSound = preload("res://scripts/game_sound.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var sound := GameSound.new()
	root.add_child(sound)
	sound.set_process(false)
	var normal_db: float = sound.music_player.volume_db
	sound.set_result_card_visible(true)
	sound.advance_audio_fades(sound.BGM_FADE_OUT_TIME * 0.5)
	check(sound.music_player.volume_db < normal_db and sound.bgm_mix_factor > sound.RESULT_BGM_FACTOR,
		"result card smoothly fades BGM toward its low level")
	sound.advance_audio_fades(sound.BGM_FADE_OUT_TIME)
	check(is_equal_approx(sound.bgm_mix_factor, sound.RESULT_BGM_FACTOR),
		"result card holds BGM at very low volume")
	sound.set_result_card_visible(false)
	sound.advance_audio_fades(sound.BGM_FADE_IN_TIME * 0.5)
	check(sound.music_player.volume_db > linear_to_db(sound.bgm_volume * sound.RESULT_BGM_FACTOR) + sound.MUSIC_HEADROOM_DB,
		"leaving the result card smoothly fades BGM back in")
	sound.advance_audio_fades(sound.BGM_FADE_IN_TIME)
	check(is_equal_approx(sound.bgm_mix_factor, 1.0) and is_equal_approx(sound.music_player.volume_db, normal_db),
		"BGM returns to the configured volume after the card disappears")
	sound.free()
	var game := Game.new()
	game.settings_save_path = ""
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(768, 1024)]:
		game.state = "menu"
		game.update_layout(size)
		var screen := Rect2(Vector2.ZERO, size)
		check(screen.encloses(game.settings_button), "settings button fits title screen %s" % size)
		game.handle_primary_press(game.settings_button.get_center())
		check(game.settings_open and screen.encloses(game.settings_card), "settings panel opens on screen %s" % size)
		var bgm_target := game.bgm_slider.position + Vector2(game.bgm_slider.size.x * 0.35, game.bgm_slider.size.y * 0.5)
		game.handle_primary_press(bgm_target)
		game.handle_touch_release(bgm_target, 0)
		check(is_equal_approx(game.bgm_volume, 0.35), "BGM slider adjusts music continuously")
		var effects_target := game.effects_slider.position + Vector2(game.effects_slider.size.x * 0.8, game.effects_slider.size.y * 0.5)
		game.handle_primary_press(effects_target)
		game.handle_touch_release(effects_target, 0)
		check(is_equal_approx(game.effects_volume, 0.8), "effects slider adjusts cues independently")
		game.handle_primary_press(game.mute_button.get_center())
		check(game.game_muted, "mute control disables sound")
		game.handle_primary_press(game.close_settings_button.get_center())
		check(not game.settings_open, "settings panel closes")
		game.state = "paused"
		game.update_layout(size)
		check(game.overlay_card.encloses(game.settings_button), "settings action fits pause card %s" % size)
		game.handle_primary_press(game.settings_button.get_center())
		check(game.settings_open and game.state == "paused" and screen.encloses(game.settings_card), "pause settings opens without resuming %s" % size)
		game.handle_primary_press(game.close_settings_button.get_center())
		check(not game.settings_open and game.state == "paused", "closing pause settings preserves the paused attempt %s" % size)
	game.free()
	print("Settings checks: ", checks, "; failures: ", failures)
	quit(failures)
