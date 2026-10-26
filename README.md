# BONK! - Godot prototype

BONK! is a game about drawing barriers to crash alien-controlled UFOs into each
other while protecting the planet.
The prototype uses procedural 2D graphics and needs no external assets or plugins.

The cartoon presentation includes expressive alien pilots in six UFO types,
a smiling ocean planet with clouds and land, twinkling stars, glowing barriers,
and floating `BONK!` collision effects. Rounded HUD cards show the current level and its countdown, heart health,
available ink, bonks, and your highest bonk count (HIGH). New records update immediately
and save locally between sessions, including browser sessions on the same site.
Labels are minimal; guidance appears only for invalid
drawings or unavailable ink. Artwork is drawn in code with antialiased outlines.
Buttons have chunky ink outlines, raised colored faces, shine marks, illustrated
play/pause/restart icons, and mouse hover/press feedback. Pastel sticker cards
fit their contents in a two-row toolbar at the bottom of the screen.
Gameplay has no title header, sidebar, or arena frame. Paused and game-over screens
center their status above the Resume, Restart, or Retry buttons. The title screen has a large
centered title above an animated planet, orbital trails and UFOs, with Play below.

## Open

1. Open Godot 4.7.2, standard edition (the version used to validate this build).
2. Import `project.godot`.
3. Press F5 to run, then Enter or Play.

## Mobile

The game is portrait-only, with a 390 × 844 default window and native handheld
portrait orientation. Landscape windows show a non-dismissible rotate-device
screen and freeze gameplay, demos, and transitions. Rotating cancels an unfinished
stroke and pauses an active run; return to portrait and tap Resume to continue.
The viewport follows the available portrait width and height while world artwork
retains uniform scaling. UFO demonstrations run vertically, and level selection
uses two columns of large touch cards.

Open the hosted game in a browser with WebGL 2 support. Tap Play, draw with one finger,
and lift to activate a barrier. A second finger cancels the current sketch.
The pause button opens a centered card with Resume, Restart, Level Select, and
Return to Title. Resume preserves the current attempt; leaving for level
selection or the title ends it without changing saved unlocks or records.
Causing 5 UFO-to-UFO collisions earns a space bomb. Each crash shows a `BONK!`
effect and increases the bonk counter by one. Tap the gold button in the bottom
toolbar, or press **B**, to blast every UFO within its large radius around the
planet. The button shows progress toward the next bomb and stores up to two charges.
After the planet is damaged, a floating heart appears at a random safe point
after a delay. Tap or click it before it disappears to restore one health point.

The arena fills the space above a separate 112 px bottom toolbar, with a visible
divider and uniformly scaled artwork. Its world bounds expand to fit portrait
windows; UFOs spawn at those visible edges. The arena's presentation rotates while
keeping characters upright; ink costs and timers stay the same. The HUD never covers the playfield.
Tapping anywhere in the toolbar does not draw; dragging into it cancels the stroke.
The first row shows time, bonks, and the record; the second shows health, ink,
and 48 px-high bomb/pause controls. Large counts use K/M abbreviations.
Resizing cancels the unfinished sketch. Backgrounding pauses play.
The web shell fits browser toolbars and safe-area insets, prevents page scrolling
while drawing, and caps the drawing buffer at 2x density to limit GPU load.

Rebuild the browser files with `godot --headless --path . --export-release Web`,
then run `python web/patch_web_export.py` before deployment. This applies the
iPhone download compatibility fix to the generated JavaScript, including after
exports from the Godot editor. The patch script safely skips an already patched
build and stops for review if the engine loader has changed.
The preset writes `index.html` and its companion files in the project root.
Vercel serves it at `/`; the previous named HTML URL also resolves to the game.
Deploy the HTML and all companion files together. Serve the exported files over
HTTP(S), rather than opening the HTML directly from disk.
The shell removes caches from older PWA exports before loading the game, and the
export patch makes pack downloads bypass the browser cache. Keep the retirement
service worker in deployments so previously installed phone shortcuts can remove
their old cache and reload from the network.
This is a mobile browser build; no Android APK or iOS application is included.

The loading screen records anonymous browser `Script error.` events and Brave's
injected `window.ethereum.selectedAddress = undefined` wallet error without
covering the game. Engine startup rejections and other errors with a source still show
diagnostics, including recent engine output. Two minutes without download progress
or completed startup shows a timeout; browser warnings remain in that report.
The loader reads downloaded bytes directly and passes the WASM buffer to
`WebAssembly.instantiate`. It never constructs a `Response`, including during
WASM initialization. Download progress and network failures remain visible.
Buffering uses additional temporary memory and compilation starts after download completes.

## Play

Developer shortcut: type **BONKDEV** on the title screen, play menu, or level
selection screen (no text field needed). It opens level selection with every
level unlocked, including boss levels, and unlimited forward pages. Type the
same code again in a menu to disable it, or restart the app. This session-only
mode does not save unlock progress or high scores, keeping normal saves intact.

Title-screen **Play** opens three choices: **From Beginning** replays level 1,
**Continue** starts the highest unlocked level, and **Select Level** opens a
paged level grid. Only level 1 is initially unlocked. Winning a level unlocks
the next one; losing or replaying an earlier cleared level does not unlock more.
Cleared levels remain replayable, locked cards cannot be selected, and unlocks
save locally between sessions. From Beginning preserves your unlocked levels.

Before each regular level, a looping introduction demonstrates its new UFO: the Saucer's
direct approach, the Scout's speed compared with a Saucer, the Weaver's weaving
and straight flight after a barrier bounce, the Brute's two-heart impact, or the
Dodger passing through its first barrier and bouncing off the next. Boss levels
have a dedicated Mothership briefing and do not introduce a new UFO. Level 6
introduces the **Dodger** and level 7 introduces the **Phantom**, which periodically
cloaks and reappears.
Press **Skip** (or Enter, Space, or Escape) when ready. The 1.2-second planet spin
starts together with the gameplay reveal, and the 90-second timer waits for both
to finish. The spin uses layered rotated afterimages for motion blur. Level 7 onward cycles through
the six existing types as a fleet refresher. Replays also show the introduction.
Player-triggered navigation closes to black around the outgoing planet, then
reveals outward from the new planet. Startup, level completion, defeat, and
automatic focus-loss pause appear immediately without a transition. Drawing and
gameplay freeze during both transition halves.

Survive each **90-second level** to reach the Level Complete screen. Its card shows
the level's bonk count, your saved highest bonk count, and total UFOs destroyed in
that attempt (including bomb kills). **Play Again** retries the same level,
**Next Level** advances one level, and **Return to Title** opens the title screen.
Each attempt starts with fresh health, ink, bombs, and counters; the highest bonk
record persists. Levels wait for your choice rather than advancing automatically.
Losing all five health points ends the attempt. The HUD counts down the current
level. Difficulty increases gradually, then levels off;
speed, wave size, and active UFO count are capped for long runs.
Gameplay renders the planet and UFOs at 1.5x size for readability without changing
their collision balance. Once 12 UFOs are active, incoming waves progressively
shrink; at 16 UFOs, spawn delays increase sharply, and the arena caps at 28 UFOs.

Every fifth level is a **Mothership boss level**. The angular command ship has 12
health, flies freely throughout the arena, and releases two unlocked UFOs every
four seconds within the normal population cap. Independent UFO waves continue to
arrive from the arena edges. Deflect UFOs into the boss for one damage per hit, or
use a nearby space bomb for two damage. A boss hit also earns a bonk; bombs do not.
Boss levels have no timer and finish as soon as the Mothership is destroyed. They
are marked in level selection, and boss kills count toward total UFOs destroyed.
The ship steers smoothly between wide-ranging targets and curves around the planet;
its collision shape always remains separated from the planet.

Six UFO types join the attack:

| Type | First available | Behavior |
| --- | --- | --- |
| Saucer | Level 1 | Standard direct approach; purple hull. |
| Scout | Level 2 | Small, fast gold craft with swept fins and twin exhausts. |
| Weaver | Level 3 | Blue side coils; zigzags toward the planet, then flies straight while stunned. |
| Brute | Level 4 | Large, slow orange plated craft; deals **two health points** of damage. |
| Dodger | Level 6 | Mint hull with pointed fins; passes through one barrier, once in its lifetime. Its glowing ring disappears when used. |
| Phantom | Level 7 | Pale hull and crescent fins; visible for 2.5 seconds, invisible for 1.5 seconds, repeating. |

Unlocked UFOs stay in the roster: level 2 has Saucers and Scouts, level 3 adds
Weavers, level 4 adds Brutes, level 5 adds Dodgers, and level 6+ includes all six.
Phantoms still collide while invisible; spawn warnings and stunned Phantoms stay
visible. Cloaking pauses along with gameplay.

The Dodger has standard Saucer speed, size, and damage. Its first barrier contact
spends its dodge and lets its whole hull pass through without a rebound or stun.
Every later barrier encounter reflects it normally, including another encounter
with that same barrier. Dodge never recharges and does not protect against bombs,
UFO collisions, or planet impacts.

All types can be reflected and destroyed in UFO collisions. Each pair adds one
bonk, and every type receives the same ten-second stun after a bounce.

- Hold **left mouse** in the arena to draw a barrier, then release to activate it.
- On touch devices, drag to draw and lift your finger to activate. A second finger cancels the current sketch.
- Draw lines or curves. Barriers cannot cross, touch, or overlap each other.
- Gaps no longer need to fit a UFO. Narrow openings are allowed; only a fully
  closed enclosure around the planet is rejected. Closed loops away from the
  planet remain allowed.
  Invalid strokes show a warning and spend no ink. Expired barriers no longer
  restrict placement.
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

Each barrier rebound sets that UFO to **2x its original cruise speed**,
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

Arcade sound effects accompany navigation, barrier drawing, rebounds, BONKs,
planet damage, boss hits, bombs, repairs, victory, and defeat. They are synthesized
at startup, so the game does not depend on external audio assets or licenses. Open
the gear in the title screen's top-right corner to adjust BGM and effects with
separate sliders or mute both; the choices are saved locally.

## Project contents

- `scripts/game.gd`: input, barrier reflection, alien steering, collisions, and bonk tracking.
- `scripts/game_view.gd`: HUD, menus, visual effects, and scene presentation.
- `scripts/game_sound.gd`: procedural arcade sound bank and overlapping playback voices.
- `scripts/space_art.gd`: reusable cartoon planets, UFOs, hearts, and stars.
- `scripts/route.gd`: shared polyline geometry and barrier validation.
- `scripts/barrier_motion.gd`: bounded, damped rubber-band impact animation.
- `tests/checks.gd`: 83 automated checks, including a seeded simulation.
- `tests/endless_checks.gd`: multi-level simulation, UFO-type, barrier-color, and elastic-impact checks.
- `tests/level_checks.gd`: level completion, results, buttons, mobile layout, and retry/next/title transitions.
- `tests/barrier_spacing_checks.gd`: crossing, overlap, endpoint clearance, expiry, and physical UFO passage checks.
- `tests/intro_checks.gd`: introductory loops, Skip, transition phases, and frozen gameplay checks.
- `tests/progress_checks.gd`: menu navigation, locked levels, sequential unlocks, saved progress, replay, Continue, and grid layout.
- `tests/phantom_boss_checks.gd`: cloak collisions, boss spawning/damage/overtime, unlock gating, and opening-spin timing.
- `tests/dodger_checks.gd`: one-use dodge, full-hull passage, fast movement, later collisions, expiry, and damage checks.
- `tests/intro_preview.gd`: UFO introduction, menus, and planet-iris screenshots on portrait screens.
- `tests/mobile_checks.gd`: 192 touch, layout, and pause checks across six portrait screen sizes.
- `tests/bomb_checks.gd`: 11 bonk-charge, collision text, blast, cap, and restart checks.
- `tests/health_pickup_checks.gd`: 11 repair pickup, input, timing, pause, and crowd-rate checks.
- `tests/settings_checks.gd`: title-screen audio settings, responsive layout, slider, and mute checks.
- `tests/shockwave_checks.gd`: speed boosts, bounded impacts, warning immunity, stun, chains, and visual lifetime checks.
- `tests/highest_bonk_checks.gd`: 8 record update, restart, persistence, and invalid-save checks.
- `tests/orientation_checks.gd`: 21 portrait-only, landscape blocking, rotation, pause, and resume checks.
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
through an allowed opening. The portrait update passes 192 mobile checks and 21 orientation checks.
Layout checks cover playfield bounds, uniform artwork scaling, two-row toolbar
containment, separation from gameplay, large bonk counts, and input isolation on six portrait screen sizes.
The endless checks include ten simulated minutes with replenished health,
wave generation beyond 24 hours, capped speed/population, new UFO behaviors,
and barrier flex, spring-back, settling, pause, and ink refunds. Desktop and mobile
screens were rendered with Godot's OpenGL renderer, including 320x568 and 390x844.
The previous browser smoke script predates portrait-only navigation and needs
updating before reuse. Browser emulation was not rerun for this update because
Playwright is unavailable locally. Physical iOS/Android devices still need
hands-on playtesting.

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
Set `REJECT_ALL_RESPONSES=1` when running the startup checks to disable every
Response constructor, reproducing the iPhone failure in both previous loader paths.
The actual WASM and PCK must
still load, and tapping Play must render gameplay. Run
`node tests/web_loader_check.cjs` for byte integrity and download-failure checks.

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
