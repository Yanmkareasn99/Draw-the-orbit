#!/usr/bin/env python3
"""Apply the BONK! rebound boost + chain-shockwave implementation.

Run from the root of Yanmkareasn99/Draw-the-orbit. Refuses unknown source layouts;
all source changes are prepared before any files are written.
"""
from pathlib import Path
import sys


def replace_once(data: str, old: str, new: str, label: str) -> str:
    n = data.count(old)
    if n != 1:
        raise ValueError(f"{label}: expected exactly one matching source block, found {n}")
    return data.replace(old, new, 1)


def prepare(root: Path):
    paths = ["scripts/game.gd", "scripts/game_view.gd", "tests/checks.gd", "README.md"]
    old_files = {p: (root / p).read_text(encoding="utf-8") for p in paths}
    modified = {}

    game = old_files["scripts/game.gd"]
    game = replace_once(game,
        'const UFO_RECOVERY_TIME := 10.0\n',
        'const UFO_RECOVERY_TIME := 10.0\n'
        'const REBOUND_SPEED_MULTIPLIER := 1.6\n'
        'const SHOCKWAVE_RADIUS := 110.0\n'
        'const SHOCKWAVE_PUSH_SPEED := 85.0\n'
        'const SHOCKWAVE_STUN_TIME := 2.0\n'
        'const SHOCKWAVE_VISUAL_TIME := 0.38\n', 'speed + shockwave settings')
    game = replace_once(game,
        'var popups: Array[Dictionary] = []\n',
        'var popups: Array[Dictionary] = []\nvar shockwaves: Array[Dictionary] = []\n', 'shockwave state')
    game = replace_once(game,
        '\tpopups.clear()\n\tsketch.clear()\n',
        '\tpopups.clear()\n\tshockwaves.clear()\n\tsketch.clear()\n', 'restart cleans up effects')
    game = replace_once(game,
        '\treturn {"type": kind, "pos": pos, "vel": (CENTER - pos).normalized() * base_speed * stats.speed,\n'
        '\t\t"warmup": 1.2, "radius": stats.radius, "damage": stats.damage, "look": stats.look,\n',
        '\treturn {"type": kind, "pos": pos, "vel": (CENTER - pos).normalized() * base_speed * stats.speed,\n'
        '\t\t"cruise_speed": base_speed * stats.speed,\n'
        '\t\t"warmup": 1.2, "radius": stats.radius, "damage": stats.damage, "look": stats.look,\n', 'preserve UFO base speed')
    game = replace_once(game,
        '\t\tfor i in range(popups.size() - 1, -1, -1):\n'
        '\t\t\tpopups[i].pos.y -= delta * 22.0\n'
        '\t\t\tpopups[i].life -= delta\n'
        '\t\t\tif popups[i].life <= 0.0:\n'
        '\t\t\t\tpopups.remove_at(i)\n',
        '\t\tfor i in range(popups.size() - 1, -1, -1):\n'
        '\t\t\tpopups[i].pos.y -= delta * 22.0\n'
        '\t\t\tpopups[i].life -= delta\n'
        '\t\t\tif popups[i].life <= 0.0:\n'
        '\t\t\t\tpopups.remove_at(i)\n'
        '\t\tfor i in range(shockwaves.size() - 1, -1, -1):\n'
        '\t\t\tshockwaves[i].life -= delta\n'
        '\t\t\tif shockwaves[i].life <= 0.0:\n'
        '\t\t\t\tshockwaves.remove_at(i)\n', 'advance visual shockwaves')
    game = replace_once(game,
        'func step_world(dt: float) -> void:\n'
        '\t# Limit travel to less than a hazard radius, including during slow frames.\n'
        '\tvar fastest := 0.0\n'
        '\tfor h in hazards:\n'
        '\t\tfastest = maxf(fastest, h.vel.length())\n'
        '\tvar steps := maxi(1, ceili(fastest * dt / MAX_TRAVEL_PER_STEP))\n'
        '\tfor step in range(steps):\n'
        '\t\tage_barriers(dt / steps)\n'
        '\t\tstep_hazards(dt / steps)\n'
        '\t\tif state != "playing":\n'
        '\t\t\tbreak\n',
        'func step_world(dt: float) -> void:\n'
        '\t# Recalculate after each slice: rebounds and shockwaves can accelerate UFOs.\n'
        '\t# Keep every physics movement at or below MAX_TRAVEL_PER_STEP.\n'
        '\tvar remaining := dt\n'
        '\twhile remaining > 0.0000001 and state == "playing":\n'
        '\t\tvar fastest := 0.0\n'
        '\t\tfor h in hazards:\n'
        '\t\t\tfastest = maxf(fastest, h.vel.length())\n'
        '\t\tvar slice := minf(remaining, MAX_TRAVEL_PER_STEP / maxf(fastest, 1.0))\n'
        '\t\tage_barriers(slice)\n'
        '\t\tstep_hazards(slice)\n'
        '\t\tremaining -= slice\n', 'adaptive movement substeps')
    game = replace_once(game,
        'func reflect_hazard(h: Dictionary) -> void:\n',
        'func redirected_speed_limit(h: Dictionary) -> float:\n'
        '\t# Store the original speed, not the speed after earlier ricochets/blasts.\n'
        '\t# Older scripted hazards that lack a cruise_speed are initialized here.\n'
        '\tif not h.has("cruise_speed"):\n'
        '\t\th.cruise_speed = h.vel.length()\n'
        '\treturn float(h.cruise_speed) * REBOUND_SPEED_MULTIPLIER\n'
        '\n'
        'func emit_shockwave(origin: Vector2) -> void:\n'
        '\t# Called only after a UFO-to-UFO bonk; never on a barrier impact.\n'
        '\tshockwaves.append({"pos": origin, "life": SHOCKWAVE_VISUAL_TIME})\n'
        '\tfor h in hazards:\n'
        '\t\tif h.warmup > 0.0:\n'
        '\t\t\tcontinue\n'
        '\t\tvar delta: Vector2 = h.pos - origin\n'
        '\t\tvar distance := delta.length()\n'
        '\t\tif distance >= SHOCKWAVE_RADIUS:\n'
        '\t\t\tcontinue\n'
        '\t\tvar direction := Vector2.RIGHT if distance < 0.001 else delta / distance\n'
        '\t\t# Outward velocity impulse: 85 px/s at the center, fading to 0 at 110 px.\n'
        '\t\tvar impulse := SHOCKWAVE_PUSH_SPEED * (1.0 - distance / SHOCKWAVE_RADIUS)\n'
        '\t\tvar speed_cap := maxf(redirected_speed_limit(h), SHOCKWAVE_PUSH_SPEED)\n'
        '\t\th.vel = (h.vel + direction * impulse).limit_length(speed_cap)\n'
        '\t\t# A shockwave-redirected UFO can now trigger another bonk on contact.\n'
        '\t\th.redirected = true\n'
        '\t\t# Preserve longer barrier stuns rather than cutting them to two seconds.\n'
        '\t\th.recovery = maxf(float(h.get("recovery", 0.0)), SHOCKWAVE_STUN_TIME)\n'
        '\n'
        'func reflect_hazard(h: Dictionary) -> void:\n', 'rebound and shockwave helpers')
    game = replace_once(game,
        '\t\t\th.vel = h.vel.bounce(normal)\n'
        '\t\t\th.redirected = true\n',
        '\t\t\t# Always target 1.6x original cruise speed; never multiply repeatedly.\n'
        '\t\th.vel = h.vel.bounce(normal).normalized() * redirected_speed_limit(h)\n'
        '\t\t\th.redirected = true\n', 'bounded rebound acceleration')
    game = replace_once(game,
        '\tvar destroyed := {}\n'
        '\tfor i in range(hazards.size()):\n',
        '\tvar destroyed := {}\n'
        '\tvar shockwave_origins: Array[Vector2] = []\n'
        '\tfor i in range(hazards.size()):\n', 'collect collision shockwaves')
    game = replace_once(game,
        '\t\t\tif a.pos.distance_to(b.pos) <= a.radius + b.radius:\n'
        '\t\t\t\tdestroyed[i] = true\n'
        '\t\t\t\tdestroyed[j] = true\n'
        '\t\t\t\tburst((a.pos + b.pos) * 0.5, GOLD)\n'
        '\t\t\t\tpopups.append({"pos": (a.pos + b.pos) * 0.5 + Vector2(0, -24), "text": "BONK!", "color": GOLD, "life": 1.1})\n'
        '\t\t\t\tregister_bonk()\n',
        '\t\t\tif a.pos.distance_to(b.pos) <= a.radius + b.radius:\n'
        '\t\t\t\tdestroyed[i] = true\n'
        '\t\t\t\tdestroyed[j] = true\n'
        '\t\t\t\tvar impact: Vector2 = (a.pos + b.pos) * 0.5\n'
        '\t\t\t\tburst(impact, GOLD)\n'
        '\t\t\t\tpopups.append({"pos": impact + Vector2(0, -24), "text": "BONK!", "color": GOLD, "life": 1.1})\n'
        '\t\t\t\tshockwave_origins.append(impact)\n'
        '\t\t\t\tregister_bonk()\n', 'queue actual UFO bonk effects')
    game = replace_once(game,
        '\t\t\t\tsketch.clear()\n'
        '\t\t\t\treturn\n',
        '\t\t\t\tsketch.clear()\n'
        '\t\t\t\treturn\n'
        '\t# Remove all collided UFOs before applying impulses to survivors.\n'
        '\t# Newly redirected ships are eligible for collisions on the next step.\n'
        '\tfor origin in shockwave_origins:\n'
        '\t\temit_shockwave(origin)\n', 'dispatch shockwaves after collision resolution')
    modified["scripts/game.gd"] = game

    view = old_files["scripts/game_view.gd"]
    view = replace_once(view,
        'func draw_world() -> void:\n\tdraw_barriers()\n\tif g.bomb_flash > 0.0:\n',
        'func draw_world() -> void:\n'
        '\tdraw_barriers()\n'
        '\t# Each UFO bonk emits a short expanding ring; this is visual only.\n'
        '\tfor wave in g.shockwaves:\n'
        '\t\tvar wave_progress: float = clampf(1.0 - wave.life / g.SHOCKWAVE_VISUAL_TIME, 0.0, 1.0)\n'
        '\t\tvar ring_radius: float = maxf(1.0, g.SHOCKWAVE_RADIUS * wave_progress)\n'
        '\t\tvar ring_alpha: float = 1.0 - wave_progress\n'
        '\t\tdraw_circle(wave.pos, ring_radius, Color(GOLD, 0.09 * ring_alpha))\n'
        '\t\tdraw_arc(wave.pos, ring_radius, 0.0, TAU, 72, Color(CREAM, ring_alpha), 3.0, true)\n'
        '\t\tdraw_arc(wave.pos, maxf(1.0, ring_radius * 0.78), 0.0, TAU, 72, Color(GOLD, ring_alpha * 0.8), 2.0, true)\n'
        '\tif g.bomb_flash > 0.0:\n', 'visual collision shockwaves')
    modified["scripts/game_view.gd"] = view

    checks = old_files["tests/checks.gd"]
    for old, new in [
        ('Vector2(-100,0)) and game.hazards[0].redirected', 'Vector2(-160,0)) and game.hazards[0].redirected'),
        ('game.hazards[0].vel.is_equal_approx(Vector2(100,0)), "barrier reflects from either side"',
         'game.hazards[0].vel.is_equal_approx(Vector2(160,0)), "barrier reflects from either side at boosted speed"'),
        ('game.hazards[0].vel.distance_to(Vector2(100,0)) < 0.01',
         'game.hazards[0].vel.distance_to(Vector2(160,0)) < 0.01'),
        ('overlap.vel.distance_to(Vector2(100,0)) < 0.01',
         'overlap.vel.distance_to(Vector2(160,0)) < 0.01'),
        ('game.hazards[0].vel.length(), 100)', 'game.hazards[0].vel.length(), 160)'),
    ]:
        checks = replace_once(checks, old, new, f"adjust existing speed expectation: {old[:30]}") if old != 'game.hazards[0].vel.length(), 100)' else replace_exact_count(checks, old, new, 2)
    modified["tests/checks.gd"] = checks

    readme = old_files["README.md"]
    readme = replace_once(readme,
        'UFOs show a 1.2-second warning before activating. Untouched UFOs do not\n',
        'Each barrier rebound sets that UFO to **1.6x its original cruise speed**,\n'
        'without multiplying its speed again on later rebounds. Every UFO-to-UFO\n'
        'BONK now emits a **110-unit shockwave** that adds an outward velocity push\n'
        'of up to **85 units/second**, decreasing toward the edge. Nearby active\n'
        'UFOs become redirected, receive at least **2 seconds of stun**, and can\n'
        'cause subsequent BONKs through physical contact. A shockwave never kills\n'
        'on its own, does not affect warning UFOs, and caps repeated impulses to\n'
        'prevent runaway acceleration. Existing longer stuns remain intact.\n\n'
        'UFOs show a 1.2-second warning before activating. Untouched UFOs do not\n', 'document new mechanics')
    readme = replace_once(readme,
        '- `tests/health_pickup_checks.gd`: 11 repair pickup, input, timing, pause, and crowd-rate checks.\n',
        '- `tests/health_pickup_checks.gd`: 11 repair pickup, input, timing, pause, and crowd-rate checks.\n'
        '- `tests/shockwave_checks.gd`: speed boosts, bounded impacts, warning immunity, stun, chains, and visual lifetime checks.\n', 'document new tests')
    readme = replace_once(readme,
        'godot --headless --path . --script res://tests/health_pickup_checks.gd\n',
        'godot --headless --path . --script res://tests/health_pickup_checks.gd\n'
        'godot --headless --path . --script res://tests/shockwave_checks.gd\n', 'document test command')
    readme = replace_once(readme,
        '`UFO_RECOVERY_TIME` controls the straight-flight window after a bounce;\n',
        '`REBOUND_SPEED_MULTIPLIER`, `SHOCKWAVE_RADIUS`, `SHOCKWAVE_PUSH_SPEED`,\n'
        '`SHOCKWAVE_STUN_TIME`, and `SHOCKWAVE_VISUAL_TIME` tune BONK chains.\n'
        '`UFO_RECOVERY_TIME` controls the straight-flight window after a bounce;\n', 'document tuning')
    modified["README.md"] = readme
    modified["tests/shockwave_checks.gd"] = SHOCKWAVE_TESTS
    path = root / "tests/shockwave_checks.gd"
    if path.exists() and path.read_text(encoding="utf-8") != SHOCKWAVE_TESTS:
        raise ValueError("tests/shockwave_checks.gd already exists with different content")
    return modified


def replace_exact_count(data: str, old: str, new: str, count: int) -> str:
    n = data.count(old)
    if n != count:
        raise ValueError(f"Expected {count} matching speed assertions, found {n}: {old}")
    return data.replace(old, new)


SHOCKWAVE_TESTS = '''extends SceneTree

const Game = preload("res://scripts/game.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
\tchecks += 1
\tif value:
\t\tprint("PASS: ", label)
\telse:
\t\tfailures += 1
\t\tpush_error(label)

func inert_ufo(game: Node, pos: Vector2, bounced: bool = false) -> Dictionary:
\tvar h: Dictionary = game.make_ufo("saucer", pos, 40.0)
\th.warmup = 0.0
\th.vel = Vector2.ZERO
\th.redirected = bounced
\th.recovery = game.UFO_RECOVERY_TIME if bounced else 0.0
\treturn h

func _initialize() -> void:
\tcall_deferred("run")

func run() -> void:
\tvar game := Game.new()
\tgame.bonk_save_path = ""
\troot.add_child(game)
\tgame.set_physics_process(false)
\tgame.get_child(0).set_process(false)
\tgame.start_round()
\tcheck(is_equal_approx(game.REBOUND_SPEED_MULTIPLIER, 1.6), "rebound multiplier is 1.6")
\tcheck(is_equal_approx(game.SHOCKWAVE_RADIUS, 110.0), "shockwave radius is 110")
\tcheck(is_equal_approx(game.SHOCKWAVE_PUSH_SPEED, 85.0), "shockwave peak push is 85")
\tcheck(is_equal_approx(game.SHOCKWAVE_STUN_TIME, 2.0), "shockwave stun is two seconds")

\tgame.sketch = PackedVector2Array([Vector2(250, 120), Vector2(250, 350)])
\tgame.finish_sketch()
\tvar h := game.make_ufo("saucer", Vector2(245, 200), 40.0)
\th.warmup = 0.0
\th.vel = Vector2(40, 0)
\tgame.reflect_hazard(h)
\tcheck(h.redirected and h.vel.is_equal_approx(Vector2(-64, 0)), "first rebound multiplies cruise speed by 1.6")
\th.pos = Vector2(257, 200)
\th.vel = Vector2(-64, 0)
\tgame.reflect_hazard(h)
\tcheck(h.vel.is_equal_approx(Vector2(64, 0)), "second rebound cannot stack another 1.6 boost")
\tcheck(is_equal_approx(h.recovery, game.UFO_RECOVERY_TIME), "barrier rebound retains full ten-second stun")

\tgame.start_round()
\tvar center := Vector2(180, 180)
\tvar at_center := inert_ufo(game, center)
\tvar near := inert_ufo(game, center + Vector2(20, 0))
\tvar far := inert_ufo(game, center + Vector2(111, 0))
\tvar warning := inert_ufo(game, center + Vector2(0, 20))
\twarning.warmup = 1.2
\tgame.hazards.append_array([at_center, near, far, warning])
\tgame.emit_shockwave(center)
\tcheck(is_equal_approx(at_center.vel.length(), 85.0), "shockwave peak outward velocity push is 85")
\tcheck(near.redirected and near.vel.x > 0.0 and near.vel.length() < 85.0, "nearby UFO receives radial push with falloff")
\tcheck(not far.redirected and far.vel.is_zero_approx(), "outside-radius UFO stays untouched")
\tcheck(not warning.redirected and warning.vel.is_zero_approx(), "warming UFO is immune to shockwave")
\tcheck(is_equal_approx(near.recovery, 2.0), "shockwave gives an unredirected UFO two seconds of stun")
\tcheck(game.hazards.size() == 4 and game.bonks == 0, "shockwave alone does not destroy or score")
\tfor i in range(20):
\t\tgame.emit_shockwave(center)
\tcheck(at_center.vel.length() <= 85.001, "repeated shockwaves cannot stack speed without limit")
\tnear.recovery = 7.0
\tgame.emit_shockwave(center)
\tcheck(is_equal_approx(near.recovery, 7.0), "short shockwave stun does not overwrite longer stun")

\tgame.start_round()
\t# First pair collides; its wave arms an overlapping second pair.
\t# That second pair must collide on the next physics step, not explode for free.
\tgame.hazards.append(inert_ufo(game, Vector2(180, 200), true))
\tgame.hazards.append(inert_ufo(game, Vector2(188, 200)))
\tgame.hazards.append(inert_ufo(game, Vector2(250, 200)))
\tgame.hazards.append(inert_ufo(game, Vector2(258, 200)))
\tgame.step_world(0.01)
\tcheck(game.bonks == 1 and game.hazards.size() == 2, "initial BONK destroys only its colliding pair")
\tcheck(game.hazards[0].redirected and game.hazards[1].redirected, "BONK wave primes nearby survivors for a chain")
\tcheck(game.shockwaves.size() == 1, "actual BONK produces exactly one visible shockwave")
\tgame.step_world(0.01)
\tcheck(game.bonks == 2 and game.hits == 4 and game.hazards.is_empty(), "wave-primed UFOs trigger a second physical collision")
\tcheck(game.shockwaves.size() == 2, "chain's second BONK also emits a wave")
\tgame.step_world(0.01)
\tcheck(game.bonks == 2, "already-destroyed pairs cannot score again")

\tgame.state = "paused"
\tvar remaining_life: float = game.shockwaves[0].life
\tgame._physics_process(0.2)
\tcheck(is_equal_approx(game.shockwaves[0].life, remaining_life), "pausing freezes shockwave visuals")
\tgame.state = "playing"
\tgame._physics_process(0.5)
\tcheck(game.shockwaves.is_empty(), "shockwave visuals expire after their lifetime")
\tgame.emit_shockwave(Vector2(100, 100))
\tgame.start_round()
\tcheck(game.shockwaves.is_empty(), "restart clears shockwave visuals")
\tgame.free()
\tprint("Shockwave checks: ", checks, "; failures: ", failures)
\tquit(failures)
'''


def main() -> None:
    root = Path.cwd()
    if not (root / "project.godot").exists():
        raise SystemExit("Run this script inside the Draw-the-orbit Godot project root")
    try:
        updates = prepare(root)
    except (OSError, ValueError) as exc:
        raise SystemExit(f"No files changed. Could not apply: {exc}") from exc
    for path, content in updates.items():
        (root / path).write_text(content, encoding="utf-8")
        print(f"Updated {path}")
    print("\nImplementation applied locally. Run the Godot test commands in README.md.")


if __name__ == "__main__":
    main()
