# BONK! - Godot prototype

BONK! is a game about drawing barriers to crash alien-controlled UFOs into each
other while protecting the planet.
The prototype uses procedural 2D graphics and needs no external assets or plugins.

The cartoon presentation includes expressive alien pilots in four UFO types,
a smiling ocean planet with clouds and land, twinkling stars, glowing barriers,
and floating `BONK!` collision effects. Rounded HUD cards show survival time, heart health,
available ink, bonks, and your highest bonk count (HIGH). New records update immediately
and save locally between sessions, including browser sessions on the same site.
Labels are minimal; guidance appears only for invalid
drawings or unavailable ink. Artwork is drawn in code with antialiased outlines.
Buttons have chunky ink outlines, raised colored faces, shine marks, illustrated
play/pause/restart icons, and mouse hover/press feedback. Pastel sticker cards
fit their contents in a centered horizontal toolbar at the bottom of the screen.
Gameplay has no title header, sidebar, or arena frame. Paused and game-over screens
center their status above the Resume, Restart, or Retry buttons. The title screen has a large
centered title above an animated planet, orbital trails and UFOs, with Play below.

## Open

1. Open Godot 4.7.2, standard edition (the version used to validate this build).
2. Import `project.godot`.
3. Press F5 to run, then Enter or Play.

## Mobile

Mobile play is landscape-only. Portrait shows a rotate-device prompt and blocks
game input. Use landscape requests fullscreen and a landscape orientation lock;
browsers that reject or lack those APIs keep the prompt until the device rotates.
Starting in landscape also attempts the lock on the first tap. Turning upright
during a run cancels the current stroke and pauses; turn back and tap Resume.
The native handheld setting permits either landscape direction. Desktop windows
can still use portrait layouts.

Open the hosted game in a browser with WebGL 2 support. Tap Play, draw with one finger,
and lift to activate a barrier. A second finger cancels the current sketch.
The pause button opens touch controls for Resume and Restart.
Causing 5 UFO-to-UFO collisions earns a space bomb. Each crash shows a `BONK!`
effect and increases the bonk counter by one. Tap the gold button in the bottom
toolbar, or press **B**, to blast every UFO within its large radius around the
planet. The button shows progress toward the next bomb and stores up to two charges.
After the planet is damaged, a floating heart appears at a random safe point
after a delay. Tap or click it before it disappears to restore one health point.

The arena fills the space above a separate 60 px bottom toolbar, with a visible
divider and uniformly scaled artwork. Its world bounds
expand to fit wide, square, and tall windows; UFOs spawn at those visible edges.
Desktop portrait windows rotate the arena's presentation while keeping characters upright;
ink costs and timers stay the same. The HUD never covers the playfield.
Tapping anywhere in the toolbar does not draw; dragging into it cancels the stroke.
Cards stay in one horizontal row. On narrow screens they use small labels above
values, one heart with a health count, and K/M abbreviations for large bonk counts.
Rotating or resizing cancels only the unfinished sketch. Backgrounding pauses play.
The web shell fits browser toolbars and safe-area insets, prevents page scrolling
while drawing, and caps the drawing buffer at 2x density to limit GPU load.

Rebuild the browser files with `godot --headless --path . --export-release Web`.
The preset writes `index.html` and its companion files in the project root.
Vercel serves it at `/`; the previous named HTML URL also resolves to the game.
Deploy the HTML and all companion files together. Serve the exported files over
HTTP(S), rather than opening the HTML directly from disk.
This is a mobile browser build; no Android APK or iOS application is included.

The loading screen records anonymous browser `Script error.` events and Brave's
injected `window.ethereum.selectedAddress = undefined` wallet error without
covering the game. Engine startup rejections and other errors with a source still show
diagnostics, including recent engine output. Two minutes without download progress
or completed startup shows a timeout; browser warnings remain in that report.

## Play

Survive for as long as you can. There is no time limit: waves continue until the
planet loses its five health points. The clock counts up and the results show
your survival time and bonk count. Difficulty increases gradually, then levels off;
speed, wave size, and active UFO count are capped for long runs.
When 20 or more UFOs fill the arena, the delay before the next wave increases
to 2.5 times its normal length so the screen does not become crowded as quickly.

Four UFO types join the attack:

| Type | First available | Behavior |
| --- | --- | --- |
| Saucer | Start | Standard direct approach; purple hull. |
| Scout | 10 seconds | Small, fast gold craft with swept fins and twin exhausts. |
| Weaver | 25 seconds | Blue side coils; zigzags toward the planet, then flies straight while stunned. |
| Brute | 45 seconds | Large, slow orange plated craft; deals **two health points** of damage. |

All types can be reflected and destroyed in UFO collisions. Each pair adds one
bonk, and every type receives the same ten-second stun after a bounce.

- Hold **left mouse** in the arena to draw a barrier, then release to activate it.
- On touch devices, drag to draw and lift your finger to activate. A second finger cancels the current sketch.
- Open lines, curves, and closed loops work. You do not need to close the sketch.
- **Leave a gap around the planet.** Any gap between the drawn lines is allowed,
  with no minimum angle or UFO-width requirement. Only a fully closed enclosure,
  including one assembled from several touching or crossing barriers, is rejected.
  The warning is “Leave a gap”; rejected strokes cost no ink. Closed traps away
  from the planet and staggered barriers with gaps are allowed.
- Angle the barrier to redirect UFOs toward other UFOs. Both sides reflect.
- On impact the barrier stretches in the incoming direction, sends a ripple
  along the stroke, and springs back like a rubber band. Larger, faster hits
  flex it more. The endpoints stay anchored; the original line still defines
  the rebound angle and ink cost. Pausing freezes the animation.
- A UFO turns **cyan** after bouncing: its pilot is stunned for **10 seconds**,
  preserving the rebound direction so you can crash it into another UFO.
  Each pair destroyed adds **one bonk**.
- Every **5 UFO-to-UFO collision bonks** grants a space bomb, with a maximum of
  two stored charges. One crash counts as one bonk even though it destroys two UFOs.
  Barrier rebounds and bomb eliminations do not increase the bonk counter.
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
- On desktop, each barrier shows its remaining lifetime. Its glow changes smoothly
  from blue at 5 seconds, through yellow halfway, to red as it expires.
  The compact ink card shows the available percentage and a fill bar, including
  the current sketch's cost. When ink runs out, a brief message shows the next refill time.
- **Right-click** cancels a sketch. **P / Escape** pauses or resumes. Losing focus
  also pauses. **R** restarts. **Enter** starts or retries from the results screen.

Barriers must be at least 24 px long, share at most 1550 px, stay outside the planet's
58 px exclusion ring, and avoid self-crossing. A valid sketch turns cyan; amber
means it needs correction. There is no starting barrier or automatic drone.
If fewer than 24 px remain, wait for ink before starting another barrier.
Pausing freezes barrier lifetimes; restarting restores the full ink budget.

Each barrier rebound sets that UFO to **1.6x its original cruise speed**,
without multiplying its speed again on later rebounds. Every UFO-to-UFO
BONK now emits a **110-unit shockwave** that adds an outward velocity push
of up to **85 units/second**, decreasing toward the edge. Nearby active
UFOs become redirected, receive at least **2 seconds of stun**, and can
cause subsequent BONKs through physical contact. A shockwave never kills
on its own, does not affect warning UFOs, and caps repeated impulses to
prevent runaway acceleration. Existing longer stuns remain intact.

UFOs show a 1.2-second warning before activating. Untouched UFOs do not
destroy each other. Pausing also freezes pilot recovery timers.
Attack patterns change every 15 seconds between clusters, opposing groups, and
scattered approaches.

## Project contents

- `scripts/game.gd`: input, barrier reflection, alien steering, collisions, and bonk tracking.
- `scripts/game_view.gd`: HUD, menus, visual effects, and scene presentation.
- `scripts/space_art.gd`: reusable cartoon planets, UFOs, hearts, and stars.
- `scripts/route.gd`: shared polyline geometry and barrier validation.
- `scripts/barrier_motion.gd`: bounded, damped rubber-band impact animation.
- `tests/checks.gd`: 83 automated checks, including a seeded simulation.
- `tests/endless_checks.gd`: 38 endless-run, UFO-type, barrier-color, and elastic-impact checks.
- `tests/mobile_checks.gd`: 288 touch, rotation, layout, and pause checks across nine screen sizes.
- `tests/bomb_checks.gd`: 11 bonk-charge, collision text, blast, cap, and restart checks.
- `tests/health_pickup_checks.gd`: 11 repair pickup, input, timing, pause, and crowd-rate checks.
- `tests/shockwave_checks.gd`: speed boosts, bounded impacts, warning immunity, stun, chains, and visual lifetime checks.
- `tests/highest_bonk_checks.gd`: 8 record update, restart, persistence, and invalid-save checks.
- `tests/orientation_checks.gd`: 10 mobile orientation, input blocking, pause, and resume checks.
- `tests/visual_preview.gd`: reproducible desktop, phone, and tablet screenshots.
- `tests/web_mobile_check.cjs`: browser smoke checks with Playwright and pngjs.
- `web/mobile_shell.html`: responsive export shell with safe-area and browser toolbar support.
- `DESIGN.md`: mechanics and playtest questions.

## Validation

All 83 checks passed in Godot 4.7.2 headless mode. They cover barrier validation,
multiple barriers, independent expiry, shared ink limits, refunds, drawing and
cancellation, reflection angles, both sides and endpoints, repeated rebounds,
fast collisions, pair destruction, bonk counting, warmup, planet damage, restart,
pause, endless survival, defeat, recovery timing, steering, return attacks, and arena-edge
behavior, planet enclosures, combined strokes, narrow gaps, and a UFO entering
through an allowed opening. All 288 mobile checks, 38 endless checks, and 8 highest-bonk checks also pass.
Layout checks cover playfield bounds, uniform artwork scaling, horizontal toolbar
alignment, separation from gameplay, large bonk counts, and input isolation on nine screen sizes.
The endless checks include ten simulated minutes with replenished health,
wave generation beyond 24 hours, capped speed/population, new UFO behaviors,
and barrier flex, spring-back, settling, pause, and ink refunds. Desktop and mobile
screens were rendered with Godot's OpenGL renderer, including 320x568 and 568x320.
The exported game was checked in Chromium mobile emulation at DPR 3: touch strokes,
portrait input blocking, rejected orientation-lock fallback, rotation pause/resume,
browser viewport height changes, simulated safe-area insets,
and absence of scrolling, letterboxing, and runtime errors. Physical iOS/Android
devices still need hands-on playtesting.

Run the checks with your Godot executable:

```sh
godot --headless --path . --script res://tests/checks.gd
godot --headless --path . --script res://tests/mobile_checks.gd
godot --headless --path . --script res://tests/endless_checks.gd
godot --headless --path . --script res://tests/highest_bonk_checks.gd
godot --headless --path . --script res://tests/orientation_checks.gd
godot --headless --path . --script res://tests/bomb_checks.gd
godot --headless --path . --script res://tests/health_pickup_checks.gd
godot --headless --path . --script res://tests/shockwave_checks.gd
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

Run `node tests/web_startup_check.cjs` to check anonymous browser errors, real
engine failures, stalled startup, and the exported game opening through Play.
It checks both the export shell template and `index.html`. Set
`BROWSER_ENGINE=webkit` to run these checks in Playwright's installed WebKit browser.
Desktop WebKit testing does not replace testing Brave or Safari on a physical iPhone.

## Tuning

`BUDGET`, `BARRIER_LIFETIME`, `BARRIER_HALF_WIDTH`, `MAX_UFOS`, `MAX_BASE_SPEED`,
and `UFO_TYPES` are near the top of `scripts/game.gd`. `spawn_attack()` and its
timer control the attack patterns and type unlocks. Waves grow from two to five
UFOs, the interval bottoms out at 2.3 seconds, and at most 48 UFOs are active.
Base speed caps at 78 px/s before type multipliers.
`scripts/barrier_motion.gd` controls ripple damping and maximum displacement.
`REBOUND_SPEED_MULTIPLIER`, `SHOCKWAVE_RADIUS`, `SHOCKWAVE_PUSH_SPEED`,
`SHOCKWAVE_STUN_TIME`, and `SHOCKWAVE_VISUAL_TIME` tune BONK chains.
`UFO_RECOVERY_TIME` controls the straight-flight window after a bounce;
`UFO_TURN_RATE` controls how quickly pilots steer back, in radians per second.
Planet enclosure validation has no minimum gap size or angle.
The highest bonk count is stored in `user://highest_bonks.cfg`. The prototype has no
sound, upgrades, or cloud record syncing.
