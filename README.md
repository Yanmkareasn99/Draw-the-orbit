# Draw the Orbit - Godot prototype

Draw barriers to crash alien-controlled UFOs into each other while protecting the planet.
The prototype uses procedural 2D graphics and needs no external assets or plugins.

The cartoon presentation includes expressive alien pilots in three saucer colors,
a smiling ocean planet with clouds and land, twinkling stars, glowing barriers,
and floating collision scores. Rounded HUD cards show rescue time, heart health,
available ink, and score. Labels are minimal; guidance appears only for invalid
drawings or unavailable ink. Menu, pause, victory, and defeat screens
use matching illustrations. Artwork is drawn in code with antialiased outlines.
The title screen has a full-screen starfield, a large animated planet and UFOs,
glowing orbital trails, and a pulsing Play button. Text stays minimal.

## Open

1. Open Godot 4.7.2, standard edition (the version used to validate this build).
2. Import `project.godot`.
3. Press F5 to run, then Enter or Play.

## Mobile

The Web build adapts to phones and tablets in portrait and landscape. Open the
hosted game in a browser with WebGL 2 support. Tap Play, draw with one finger,
and lift to activate a barrier. A second finger cancels the current sketch.
The pause button opens touch controls for Resume and Restart.

The HUD stays outside the arena. Portrait rotates the arena's presentation while
keeping characters upright; physics, ink costs, and timers stay the same.
Rotating or resizing cancels only the unfinished sketch. Backgrounding pauses play.
The web shell fits browser toolbars and safe-area insets, prevents page scrolling
while drawing, and caps the drawing buffer at 2x density to limit GPU load.

Rebuild the browser files with `godot --headless --path . --export-release Web`.
The existing root HTML and Vercel entry path are preserved. Serve the exported
files over HTTP(S), rather than opening the HTML directly from disk.
This is a mobile browser build; no Android APK or iOS application is included.

## Play

Survive for 90 seconds. The planet can take five hits.

- Hold **left mouse** in the arena to draw a barrier, then release to activate it.
- On touch devices, drag to draw and lift your finger to activate. A second finger cancels the current sketch.
- Open lines, curves, and closed loops work. You do not need to close the sketch.
- **Leave a clear 60-degree approach to the planet.** All active barriers and
  your new stroke are checked together, including the UFO's collision width.
  Complete shields, nearly closed rings, and enclosures assembled from multiple
  strokes cannot activate. The sketch shows a warning and costs no ink.
  Closed traps away from the planet are allowed if they leave that approach open.
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
- On desktop, each barrier shows its remaining lifetime. Barriers turn amber in their final second.
  The sidebar shows available ink as a percentage and the next refill timer;
  amber in the meter represents the current sketch.
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

- `scripts/game.gd`: input, barrier reflection, alien steering, collisions, and scoring.
- `scripts/game_view.gd`: HUD, menus, visual effects, and scene presentation.
- `scripts/space_art.gd`: reusable cartoon planets, UFOs, hearts, and stars.
- `scripts/route.gd`: shared polyline geometry and barrier validation.
- `tests/checks.gd`: 79 automated checks, including a seeded simulation.
- `tests/mobile_checks.gd`: 104 touch, rotation, layout, and pause checks across seven screen sizes.
- `tests/visual_preview.gd`: reproducible desktop, phone, and tablet screenshots.
- `tests/web_mobile_check.cjs`: browser smoke checks with Playwright and pngjs.
- `web/mobile_shell.html`: responsive export shell with safe-area and browser toolbar support.
- `DESIGN.md`: mechanics and playtest questions.

## Validation

All 79 checks passed in Godot 4.7.2 headless mode. They cover barrier validation,
multiple barriers, independent expiry, shared ink limits, refunds, drawing and
cancellation, reflection angles, both sides and endpoints, repeated rebounds,
fast collisions, pair destruction, scoring, warmup, planet damage, restart,
pause, victory, defeat, recovery timing, steering, return attacks, and arena-edge
behavior, planet enclosures, combined strokes, narrow gaps, and a UFO entering
through an allowed opening. All 104 mobile checks also pass. Desktop and mobile
screens were rendered with Godot's OpenGL renderer, including 320x568 and 568x320.
The exported game was checked in Chromium mobile emulation at DPR 3: touch strokes,
pause/resume, rotation, browser viewport height changes, simulated safe-area insets,
and absence of scrolling, letterboxing, and runtime errors. Physical iOS/Android
devices still need hands-on playtesting.

Run the checks with your Godot executable:

```sh
godot --headless --path . --script res://tests/checks.gd
godot --headless --path . --script res://tests/mobile_checks.gd
```

Capture desktop and mobile visual previews (requires a graphics renderer):

```sh
godot --path . --rendering-method gl_compatibility --script res://tests/visual_preview.gd
```

Screenshots are saved in `artifacts/`, including `gameplay.png` and `menu.png`.

For the exported browser smoke check, install `playwright` and `pngjs` in your
test environment, then run `node tests/web_mobile_check.cjs`. It uses installed
Microsoft Edge by default; set `BROWSER_CHANNEL=chrome` to use Chrome instead.
The script starts and stops its own local HTTP server.

## Tuning

`BUDGET`, `BARRIER_LIFETIME`, `BARRIER_HALF_WIDTH`, and `ROUND_TIME` are near the top of
`scripts/game.gd`. `spawn_attack()` and its timer control the attack patterns.
`UFO_RECOVERY_TIME` controls the straight-flight window after a bounce;
`UFO_TURN_RATE` controls how quickly pilots steer back, in radians per second.
`MIN_PLANET_OPENING` sets the minimum clear approach angle, currently 60 degrees.
The prototype has no sound, upgrades, or persistent scores.
