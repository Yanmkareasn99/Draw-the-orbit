extends SceneTree

const Game = preload("res://scripts/game.gd")
const GameSound = preload("res://scripts/game_sound.gd")
const Flow = preload("res://tests/screen_flow.gd")
var failures := 0
var checks := 0

class CueSpy:
	extends Node
	var cues: Array[String] = []

	func play_cue(cue: String, _pitch: float = 1.0) -> void:
		cues.append(cue)

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var game := Game.new()
	var sound_bank := GameSound.new()
	sound_bank._build_sound_bank()
	check(sound_bank.streams.has("planet_spin") and sound_bank.streams["planet_spin"] is AudioStreamMP3,
		"planet spin MP3 is registered in the effects sound bank")
	sound_bank.free()
	game.bonk_save_path = ""
	game.progress_save_path = ""
	game.start_round(7)
	var ghost := game.make_ufo("phantom", Vector2(240, 200), 40)
	ghost.cloak_clock = 3.0
	check(game.phantom_visible(ghost), "warning phantom remains visible")
	ghost.warmup = 0
	ghost.cloak_clock = 2.675
	check(is_equal_approx(game.ufo_opacity(ghost), 0.5), "phantom fades out instead of disappearing instantly")
	ghost.cloak_clock = 3.0
	check(not game.phantom_visible(ghost), "phantom cloaks during its invisible phase")
	ghost.cloak_clock = 4.525
	check(is_equal_approx(game.ufo_opacity(ghost), 0.5), "phantom fades back in before its next visible phase")
	ghost.cloak_clock = 4.7
	check(game.phantom_visible(ghost), "phantom reappears on the next cycle")
	ghost.cloak_clock = 3.0
	ghost.vel = Vector2(40, 0)
	game.sketch = PackedVector2Array([Vector2(250, 120), Vector2(250, 320)])
	game.finish_sketch()
	game.reflect_hazard(ghost)
	check(ghost.redirected and ghost.vel.x < 0 and game.phantom_visible(ghost) and game.ufo_opacity(ghost) == 1.0, "invisible phantom hits barrier and becomes fully visible while stunned")
	var specter := game.make_ufo("specter", Vector2(180, 240), 40)
	specter.warmup = 0
	specter.teleport_clock = 0.0
	specter.recovery = 2.0
	check(not game.advance_specter_teleport(specter, 0.1) and specter.teleport_phase == "", "stunned specter cannot begin teleporting")
	specter.recovery = 0.0
	var old_position: Vector2 = specter.pos
	check(game.advance_specter_teleport(specter, 0.1) and specter.teleport_phase == "depart", "active specter starts its teleport animation")
	var target: Vector2 = specter.teleport_target
	var flight_area := game.ARENA.grow(-specter.radius - 3.0)
	check(flight_area.has_point(target) and target.distance_to(game.CENTER) >= game.PLANET_COLLISION_RADIUS + specter.radius + 6.0, "specter destination stays in the arena and clear of the planet")
	check(target.distance_to(old_position) >= 90.0 and game.portals.size() == 1, "specter opens linked departure and arrival portals")
	game.advance_specter_teleport(specter, game.SPECTER_DEPART_TIME * 0.5)
	check(game.ufo_opacity(specter) > 0.0 and game.ufo_opacity(specter) < 1.0, "specter fades into its departure portal")
	game.advance_specter_teleport(specter, game.SPECTER_DEPART_TIME)
	check(specter.pos == target and specter.teleport_phase == "arrive" and is_zero_approx(game.ufo_opacity(specter)), "specter moves only after vanishing and begins its arrival animation")
	game.advance_specter_teleport(specter, game.SPECTER_ARRIVE_TIME * 0.5)
	check(game.ufo_opacity(specter) > 0.0 and game.ufo_opacity(specter) < 1.0, "specter fades out of its arrival portal")
	specter.pos = Vector2(240, 240)
	specter.vel = Vector2(40, 0)
	game.reflect_hazard(specter)
	game.advance_specter_teleport(specter, 0.01)
	check(specter.redirected and specter.vel.x < 0 and specter.teleport_phase == "" and game.ufo_opacity(specter) == 1.0, "barrier stun cancels teleport and restores full visibility")
	game.start_round(5)
	game.highest_unlocked_level = 5
	check(game.boss_alive() and game.boss.health == 12, "fifth level starts with a living mothership")
	game.boss.clock = 0
	game.advance_boss(0.01)
	check(game.hazards.size() == 2 and game.hazards[0].warmup > 0, "boss releases UFOs with normal spawn warnings")
	game.hazards.clear()
	game.boss.clock = 10.0
	game.spawn_clock = 0.0
	game._physics_process(0.01)
	check(not game.hazards.is_empty(), "independent edge waves continue while the boss lives")
	game.hazards.clear()
	game.elapsed = 89.99
	game._physics_process(0.02)
	check(game.state == "playing" and game.level_time() == "BOSS" and game.highest_unlocked_level == 5, "boss level has no completion timer")
	var previous_position: Vector2 = game.boss.pos
	var previous_velocity: Vector2 = game.boss.velocity
	game._physics_process(0.1)
	check(game.boss.pos.distance_to(previous_position) > 0.0, "boss travels freely during the fight")
	check(game.boss.velocity.distance_to(previous_velocity) <= game.BOSS_STEERING_ACCELERATION * 0.1 + 0.001, "boss changes direction with bounded smooth steering")
	game.boss.pos = game.CENTER
	game.advance_boss(0.0)
	check(game.boss.pos.distance_to(game.CENTER) >= game.BOSS_RADIUS + game.PLANET_COLLISION_RADIUS + game.BOSS_PLANET_CLEARANCE, "boss cannot overlap the planet")
	var missile := game.make_ufo("saucer", game.boss.pos, 0)
	missile.warmup = 0
	missile.redirected = true
	missile.recovery = 10
	game.hazards.append(missile)
	game.step_world(0.01)
	check(game.boss.health == 11 and game.hazards.is_empty() and game.bonks == 1, "redirected UFO damages boss and is consumed once")
	game.space_bombs = 1
	game.use_space_bomb()
	check(game.boss.health == 9, "nearby bomb damages boss")
	game.damage_boss(99)
	game._physics_process(0.01)
	check(game.state == "complete" and game.highest_unlocked_level == 6 and game.boss.health == 0, "defeating the boss completes and unlocks the next level")
	game.start_round(5)
	game.damage_boss(12)
	game._physics_process(0.1)
	check(game.state == "complete", "boss defeat completes immediately without a survival gate")
	game.start_round(1)
	var cue_spy := CueSpy.new()
	game.game_sound = cue_spy
	game.state = "intro"
	game.update_layout(Vector2(390, 844))
	game.handle_primary_press(game.skip_button.get_center())
	Flow.settle(game)
	var post_reveal_spin := maxf(0.0, game.PLANET_SPIN_TIME - game.TRANSITION_TIME)
	check(is_equal_approx(game.planet_spin_remaining, post_reveal_spin), "planet spin advances alongside the gameplay reveal")
	check(cue_spy.cues.count("planet_spin") == 1, "opening planet spin triggers its sound exactly once")
	game._physics_process(1.0)
	check(game.elapsed == 0 and game.hazards.is_empty(), "spin freezes level timer and spawning")
	game.state = "paused"
	game.advance_presentation(1.0)
	check(is_equal_approx(game.planet_spin_remaining, post_reveal_spin), "pause freezes planet spin")
	game.state = "playing"
	game.advance_presentation(game.PLANET_SPIN_TIME)
	game._physics_process(0.1)
	check(game.elapsed > 0 and game.planet_spin_remaining == 0, "gameplay begins after spin finishes")
	cue_spy.free()
	game.free()
	print("Phantom/boss checks: ", checks, "; failures: ", failures)
	quit(failures)
