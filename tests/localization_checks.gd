extends SceneTree

const Game = preload("res://scripts/game.gd")
const Localization = preload("res://scripts/localization.gd")
const SAVE_PATH := "user://localization_checks.cfg"
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func placeholders(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	var pattern := RegEx.create_from_string("%([0-9.]*[dfs]|%)")
	for match_result in pattern.search_all(text):
		result.append(match_result.get_string())
	return result

func _initialize() -> void:
	var font := Localization.make_font()
	for source in Localization.TEXT:
		for language in ["ja", "vi"]:
			var translated := Localization.translate(source, language)
			check(not translated.is_empty() and translated != source, "translated UI string: %s (%s)" % [source, language])
			check(placeholders(source) == placeholders(translated), "format arguments preserved: %s (%s)" % [source, language])
			var supported := true
			for i in range(translated.length()):
				supported = supported and font.has_char(translated.unicode_at(i))
			check(supported, "bundled fonts cover: %s (%s)" % [source, language])
	var game := Game.new()
	game.settings_save_path = ""
	game.bgm_volume = 0.3
	game.effects_volume = 0.8
	game.game_muted = true
	game.highest_unlocked_level = 8
	game.highest_bonks = 25
	for size in [Vector2(320, 568), Vector2(390, 844), Vector2(768, 1024)]:
		for state in ["menu", "paused"]:
			game.state = state
			game.settings_open = true
			game.update_layout(size)
			var controls := [game.bgm_slider, game.effects_slider, game.mute_button, game.close_settings_button]
			controls.append_array(game.language_buttons.values())
			var fits := Rect2(Vector2.ZERO, size).encloses(game.settings_card)
			for i in range(controls.size()):
				fits = fits and game.settings_card.encloses(controls[i]) and controls[i].size.y >= 44
				for j in range(i + 1, controls.size()):
					fits = fits and not controls[i].intersects(controls[j])
			check(fits, "settings controls fit without overlap: %s, %s" % [size, state])
			for language in ["ja", "vi", "en"]:
				game.handle_touch_press(game.language_buttons[language].get_center(), 0)
				game.handle_touch_release(game.language_buttons[language].get_center(), 0)
				check(game.language == language and game.state == state and game.settings_open, "language applies immediately without leaving settings")
				check(is_equal_approx(game.bgm_volume, 0.3) and is_equal_approx(game.effects_volume, 0.8) and game.game_muted,
					"language changes preserve audio preferences")
				check(game.highest_unlocked_level == 8 and game.highest_bonks == 25, "language changes preserve progress")
				check(game.hud_value("ink") == "100%", "ink percentage never includes a translated label")
	game.settings_save_path = SAVE_PATH
	game.set_language("ja")
	var restored := Game.new()
	restored.settings_save_path = SAVE_PATH
	restored.load_audio_settings()
	check(restored.language == "ja" and is_equal_approx(restored.bgm_volume, 0.3) and restored.game_muted, "language and audio survive reload together")
	restored.set_language("vi")
	restored.set_audio_channel_volume("bgm", 0.6)
	game.load_audio_settings()
	check(game.language == "vi" and is_equal_approx(game.bgm_volume, 0.6), "audio changes preserve the saved language")
	game.set_language("invalid")
	check(game.language == "vi", "unsupported language selections are ignored")
	var legacy := ConfigFile.new()
	legacy.set_value("audio", "volume", 0.2)
	legacy.save(SAVE_PATH)
	game.load_audio_settings()
	check(game.language == "en" and is_equal_approx(game.effects_volume, 0.2), "old audio-only saves use English")
	legacy.set_value("preferences", "language", 123)
	legacy.save(SAVE_PATH)
	game.load_audio_settings()
	check(game.language == "en", "invalid saved language falls back to English")
	DirAccess.remove_absolute(SAVE_PATH)
	game.free()
	restored.free()
	print("Localization checks: ", checks, "; failures: ", failures)
	quit(failures)
