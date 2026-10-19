# Draw the Orbit — Godot prototype

A standalone experiment based on the Draw the Orbit concept. No external assets,
plugins, .NET runtime, or existing Greedy Orbit project are needed.

## Open

1. Extract the ZIP completely.
2. Open Godot **4.4 or newer, standard edition**.
3. In the Project Manager choose **Import**, select `project.godot`, and open it.
4. Press **F5** (Run Project), then Enter or Start Round.

Godot 3 is not supported. Compatibility rendering is configured for broad hardware support.

## Play

Protect the planet for 90 seconds. It can take five hits. Each interception earns
100 points. A default circular route is active at the beginning.

- Hold **left mouse** in the arena to draw a replacement route.
- Finish within the visible **30 px start circle**, then release to activate.
- The sketch turns cyan when it can be activated. An amber sketch needs correction.
- **Right-click** cancels a sketch.
- **P / Escape** pauses or resumes. Losing window focus also pauses.
- **R** restarts the round. **Enter** starts/retries from the opening/results screen.

Only the drone destroys hazards. The route line is not a shield. The drone moves
at 430 px/second: longer routes take longer to patrol. The route budget is 1550 px.
Routes cannot cross themselves or the planet's exclusion ring. Invalid sketches
preserve the previous route. Draw clockwise or counterclockwise to choose direction.

When you activate a route, the drone moves to the nearest point at its normal
speed and cannot intercept while transferring. A gold dashed line previews the
transfer once your sketch is valid. Enemies and the previous drone keep moving
while you draw. Targets show a 1.2-second spawn warning and a short trajectory line.

Every 15 seconds the attack pattern shifts between clusters, opposing groups,
and scattered approaches. This is an initial balance experiment, not a finished
or difficulty-calibrated game. Doing nothing on the default route is intentionally
unsafe. Try a short loop close to the planet or concentrate an oval on a cluster.

## Project contents

- `project.godot`: project configuration; import this file.
- `main.tscn`: main scene.
- `scripts/game.gd`: input, gameplay, drawing, and tunable constants.
- `scripts/route.gd`: path sampling, nearest-point transfer, and validation.
- `tests/checks.gd`: 15 automated checks plus a seeded simulation.
- `DESIGN.md`: design scope, tradeoffs, and playtest questions.

## Validation

Imported and tested with Godot 4.4.1 using headless mode. All 15 automated checks
passed, including route length, wrapping, nearest point, invalid-route rejection,
no teleport on replacement, scoring, planet damage, transfer restrictions,
90-second victory, defeat, and pausing. A seeded unattended simulation also ran.
A graphical playtest was not possible in the build environment; feel, balance,
and visual layout still need checking on your computer.

To repeat checks (substitute your Godot executable path):

```sh
godot --headless --path . --script res://tests/checks.gd
```

## Tuning

Constants near the start of `scripts/game.gd` control `DRONE_SPEED`, `BUDGET`,
and `ROUND_TIME`. `spawn_attack()` and the spawn timer control difficulty.
The prototype uses procedural 2D graphics and has no sound or persistent scores.
There is no shop or direct-click destruction in this experiment.
