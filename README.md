# Draw the Orbit - Godot prototype

Draw barriers to bounce hazards into each other while protecting the planet.
The prototype uses procedural 2D graphics and needs no external assets or plugins.

## Open

1. Open Godot 4.4 or newer, standard edition.
2. Import `project.godot`.
3. Press F5 to run, then Enter or Start Round.

## Play

Survive for 90 seconds. The planet can take five hits.

- Hold **left mouse** in the arena to draw a barrier, then release to activate it.
- Open lines, curves, and closed loops work. You do not need to close the sketch.
- Angle the barrier to redirect hazards toward other hazards. Both sides reflect.
- A hazard turns **cyan** after bouncing. When it hits another active hazard,
  both are destroyed for **200 points** (100 per hazard).
- Bounced hazards keep their speed and can bounce repeatedly. Their trajectory
  lines show the new direction. They still damage the planet if aimed into it.
- Only one barrier is active. A valid new sketch replaces it; the existing barrier
  keeps working while you draw. Invalid sketches preserve the existing barrier.
- **Right-click** cancels a sketch. **P / Escape** pauses or resumes. Losing focus
  also pauses. **R** restarts. **Enter** starts or retries from the results screen.

Barriers must be at least 24 px long, use at most 1550 px, stay outside the planet's
58 px exclusion ring, and avoid self-crossing. A valid sketch turns cyan; amber
means it needs correction. There is no starting barrier or automatic drone.

Hazards show a 1.2-second warning before activating. Untouched hazards do not
destroy each other. Hazards that leave the arena disappear without scoring.
Attack patterns change every 15 seconds between clusters, opposing groups, and
scattered approaches.

## Project contents

- `scripts/game.gd`: input, barrier reflection, hazard collisions, scoring, and UI.
- `scripts/route.gd`: shared polyline geometry and barrier validation.
- `tests/checks.gd`: 34 automated checks, including a seeded simulation.
- `DESIGN.md`: mechanics and playtest questions.

## Validation

All 34 checks passed in Godot 4.7.2 headless mode. They cover barrier validation,
replacement, reflection angles, both sides and endpoints, repeated rebounds,
fast collisions, pair destruction, scoring, warmup, planet damage, restart,
pause, victory, and defeat. Visual feel and balance still need human playtesting.

Run the checks with your Godot executable:

```sh
godot --headless --path . --script res://tests/checks.gd
```

## Tuning

`BUDGET`, `BARRIER_HALF_WIDTH`, and `ROUND_TIME` are near the top of
`scripts/game.gd`. `spawn_attack()` and its timer control the attack patterns.
The prototype has no sound, upgrades, or persistent scores.
