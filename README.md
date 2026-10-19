# Draw the Orbit - Godot prototype

Draw barriers to crash alien-controlled UFOs into each other while protecting the planet.
The prototype uses procedural 2D graphics and needs no external assets or plugins.

## Open

1. Open Godot 4.4 or newer, standard edition.
2. Import `project.godot`.
3. Press F5 to run, then Enter or Start Round.

## Play

Survive for 90 seconds. The planet can take five hits.

- Hold **left mouse** in the arena to draw a barrier, then release to activate it.
- Open lines, curves, and closed loops work. You do not need to close the sketch.
- Angle the barrier to redirect UFOs toward other UFOs. Both sides reflect.
- A UFO turns **cyan** after bouncing: its pilot is stunned for **10 seconds**,
  preserving the rebound direction so you can crash it into another UFO.
  Each pair destroyed earns **200 points** (100 per UFO).
- Survivors turn **gold**, regain control, and steer back toward the planet.
  Rebounds preserve speed, and another bounce restarts the stun timer.
  Previously bounced UFOs can still destroy another UFO after recovery.
- Stunned UFOs bounce inward at the arena edge without shortening their stun;
  recovered pilots turn toward the planet. UFOs never disappear at the edge. Deflecting them
  away only buys time; surviving aliens will attack again. Both incoming and
  bounced UFOs damage the planet on impact.
- Saucers have visible alien pilots, running lights, trajectory indicators,
  and a cyan ring showing the remaining stun time. Red lights mean a new attacker.
- Draw as many barriers as fit within the shared **1550 px ink budget**.
  Each barrier lasts **5 seconds from release**, then disappears and returns
  its ink. Existing barriers keep working while you draw additional ones.
- When ink runs out, wait for a barrier to disappear. Strokes stop at the
  available limit; ink returned while drawing lets you extend the same stroke.
  Invalid or cancelled sketches do not consume ink or remove active barriers.
- Each barrier shows its remaining lifetime and turns amber in its final second.
  The sidebar shows active and pending ink, free ink, and the next refill timer.
- **Right-click** cancels a sketch. **P / Escape** pauses or resumes. Losing focus
  also pauses. **R** restarts. **Enter** starts or retries from the results screen.

Barriers must be at least 24 px long, share at most 1550 px, stay outside the planet's
58 px exclusion ring, and avoid self-crossing. A valid sketch turns cyan; amber
means it needs correction. There is no starting barrier or automatic drone.
If fewer than 24 px remain, wait for ink before starting another barrier.
Pausing freezes barrier lifetimes; restarting restores the full ink budget.

UFOs show a 1.2-second warning before activating. Untouched UFOs do not
destroy each other. Pausing also freezes pilot recovery timers.
Attack patterns change every 15 seconds between clusters, opposing groups, and
scattered approaches.

## Project contents

- `scripts/game.gd`: input, barrier reflection, alien steering, UFO drawing, collisions, scoring, and UI.
- `scripts/route.gd`: shared polyline geometry and barrier validation.
- `tests/checks.gd`: 63 automated checks, including a seeded simulation.
- `DESIGN.md`: mechanics and playtest questions.

## Validation

All 63 checks passed in Godot 4.7.2 headless mode. They cover barrier validation,
multiple barriers, independent expiry, shared ink limits, refunds, drawing and
cancellation, reflection angles, both sides and endpoints, repeated rebounds,
fast collisions, pair destruction, scoring, warmup, planet damage, restart,
pause, victory, defeat, recovery timing, steering, return attacks, and arena-edge
behavior. Visual feel and balance still need human playtesting.

Run the checks with your Godot executable:

```sh
godot --headless --path . --script res://tests/checks.gd
```

## Tuning

`BUDGET`, `BARRIER_LIFETIME`, `BARRIER_HALF_WIDTH`, and `ROUND_TIME` are near the top of
`scripts/game.gd`. `spawn_attack()` and its timer control the attack patterns.
`UFO_RECOVERY_TIME` controls the straight-flight window after a bounce;
`UFO_TURN_RATE` controls how quickly pilots steer back, in radians per second.
The prototype has no sound, upgrades, or persistent scores.
