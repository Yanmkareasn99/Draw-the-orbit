# BONK! / barrier prototype

## Gameplay

Players draw reflective barriers to redirect alien-controlled UFOs into other UFOs.
Barrier angle determines the rebound, so predicting trajectories is the main
interaction. The barrier replaces the earlier drone-and-route mechanic.
Survivors recover control and return to attack, making a deflection temporary
unless the player crashes UFOs into each other.

## Implemented rules

Play requires portrait. Native handheld orientation is portrait; the browser
shell and game show a non-dismissible rotate-device screen in landscape.
Landscape blocks input, physics, and presentation clocks, pauses active runs,
and cancels drafts. Returning to portrait requires an explicit Resume for an
active run. The desktop window defaults to 390 × 844.

The presentation fills the canvas above a separate 112 px bottom toolbar in
portrait, using uniform scale and expanding the arena bounds to
the playfield edges. A visible divider separates play from controls. The planet stays
centered and UFO spawn positions follow the new bounds. Portrait rotates the arena by 90 degrees and keeps the planet
and pilots upright. Drawing uses the inverse display transform, so ink costs,
collision widths, and travel speeds do not depend on screen size. The compact
HUD uses two rows in the bottom bar, with 48 px-high bomb and pause targets;
pause, resume, and restart all work by touch. Narrow screens use
labels above values, a heart count, and abbreviated large bonk counts. Toolbar taps
never start strokes, and dragging into the bar cancels the unfinished stroke.
Resizing cancels the unfinished stroke, while active barriers and UFOs persist.

- Multiple active freeform barriers; open strokes are accepted.
- Release to add a barrier with its own 5-second lifetime. Its color moves from
  blue through yellow to red as time runs out, then it disappears on expiry.
- Sketches use approximately 6 px sampling and a 24 px minimum.
- All active barriers and the current sketch share a 1550 px length budget.
  A stroke clamps to available ink. Release also validates the shared limit.
- Expiring barriers return exactly their own ink. With less than 24 px available,
  starting a new stroke is blocked until ink returns. There is no separate count cap.
- Cancelled or invalid sketches cost no ink and leave active barriers intact.
- Countdown labels and a final-second fade show barrier expiry. The ink card shows
  the remaining percentage and a fill bar including pending ink; a refill message appears when
  ink runs out. Pausing freezes all lifetimes.
- Reject self-crossings and segments within 58 px of the planet center.
- Reject crossings, touching, and overlaps between barriers using segment distance
  and the 4 px combined barrier half-widths. Collinear overlaps are included.
- No UFO-sized minimum clearance is required between ends or adjacent barriers.
  Narrow openings are allowed, provided separate barriers do not touch or overlap.
  Fully enclosing the planet remains prohibited; closed loops elsewhere are valid.
  Self-crossing and retraced strokes are also rejected. Validation uses resting
  collision geometry, unaffected by decorative elastic waves.
- Invalid sketches keep existing barriers and spend no ink; expired barriers stop
  contributing to the restriction. Preview and release use the same validation.
- A sketch never pauses the world or disables existing barriers. Ink returned
  during a sketch can be used immediately to extend it.
- UFOs reflect from either side and rounded endpoints, preserving speed.
- Impacts create damped elastic waves along a resampled visual stroke, with
  anchored endpoints and a 22 px maximum displacement. Up to eight impact waves
  overlap; each settles after 1.6 seconds. Original geometry determines collision
  angles, validation, and ink costs. Animation advances only with simulation.
- Contact separation prevents sticking; there is no cooldown preventing rebounds.
- A cyan UFO has a stunned pilot: its reflected heading is held for 10 seconds.
  Each new rebound restarts this window. A shrinking cyan ring shows recovery.
- Recovered pilots turn gold and steer toward the planet at up to 2.4 radians
  per second. The redirected flag persists, so collisions still destroy pairs.
- Collision between a previously bounced UFO and another active UFO destroys
  both. Each pair adds one bonk to the run total.
- Untouched UFOs pass through each other, keeping spawn clusters intact.
- Warning UFOs are inactive for 1.2 seconds. At the arena boundary, stunned UFOs
  bounce inward while retaining their stun timer; recovered pilots head toward
  the planet. UFOs never disappear for free.
- Both original and bounced UFOs can damage the planet.
- UFO visuals use procedural saucers, glass canopies, green alien pilots,
  engine trails, and lights for incoming, stunned, and returning states.
- Five planet health points and no automatic starting defense. Zero health loses
  the attempt; surviving 90 seconds opens a Level Complete card with bonks, saved
  highest bonks, and total UFOs destroyed in this attempt (including bombs).
  Play Again retries this level, Next Level advances, and Return to Title opens
  the title screen. Each attempt resets gameplay resources and counters while
  retaining the saved record. Completion freezes gameplay until an action.
- Title Play opens From Beginning, Continue, and Select Level. Continue begins
  the highest unlocked level; From Beginning replays level 1 without erasing
  unlocks. The selection grid pages six levels at a time and marks cleared,
  playable, and locked levels. Winning the highest unlocked level unlocks exactly
  the next level, saved locally. Losses and earlier-level replays grant no unlock.
- Regular levels last 90 seconds. Standard saucers appear in level 1, Scouts join in
  level 2 (1.55x speed, 7 px radius), Weavers in level 3 (1.1x speed,
  sinusoidal approach steering), and Brutes in level 4 (0.72x speed, 15 px
  radius, two damage). Level 6 adds the Dodger (standard Saucer stats), which
  passes through its first barrier encounter once per lifetime. It ignores that
  specific barrier until its whole hull clears, then reflects normally forever.
  A mint charge ring disappears when consumed. Level 7 adds the Phantom: 2.5
  seconds visible, then 1.5 seconds invisible. Collision rules never change and
  warning/stunned Phantoms stay visible. Level 7+ uses all six types.
- Every fifth level is a separate, untimed boss stage with a 12-health Mothership
  moving freely around the arena. It releases two unlocked UFOs every four seconds
  while regular edge waves continue independently. Redirected UFOs deal one damage
  and are consumed; in-range bombs deal two. Destroying the boss completes the level.
- After Skip and its reveal, the planet spins for 1.2 seconds with six rotated
  translucent afterimages. Gameplay and its timer wait for the spin to end;
  pause freezes the spin and resuming does not restart it.
  Weavers stop weaving when redirected and share normal stun/recovery behavior.
- Difficulty caps at five UFOs per wave, a 2.3-second spawn interval, 78 px/s
  base speed before type multipliers, and 28 simultaneous UFOs. Waves shrink
  after 12 active UFOs and spawn delays increase sharply at 16. Gameplay art
  renders the planet and UFOs at 1.5x size without changing collision balance.
- Adaptive physics substeps limit movement to 4 px to prevent fast UFOs from
  passing through barriers or each other. All UFOs move before pairs resolve.

## Scope and playtesting

Presentation uses a navy, mint, peach, and lavender palette with rounded cards.
Procedural cartoon artwork is isolated in `space_art.gd`; `game_view.gd` handles
the HUD and menus. UFO types have distinct hull colors, sizes, and silhouettes:
Scouts have swept fins, Weavers have side coils, and Brutes have plated hulls.
Pilots have determined or dizzy expressions; the planet blinks, smiles, and
reacts to damage. Barriers glow, stars twinkle, and collisions produce star
particles and floating `BONK!` effects. The HUD shows time, hearts, ink, and bonks with
minimal labels. Decorative captions, repeated instructions, and the enemy legend
are omitted. Only actionable warnings appear during play; menus use short titles
and buttons. Desktop states and impact animation frames can be captured with the visual
preview script for layout review.
Gameplay has no title header or sidebar. The playfield remains visible behind
the compact pause and results controls centered on the screen, with the status
above a horizontal row of buttons. Button widths
fit their text and icon, with a 44 px height for touch. Solid outlines and pastel
faces preserve the cartoon style. The separate title screen centers a large
two-line title above the main planet, with animated orbit trails and UFOs. A
larger Play button sits below the planet; the composition scales to the viewport.

The bottom toolbar includes a space-bomb control. Each UFO-to-UFO crash displays
`BONK!` and adds one to its 5-bonk meter, with at most two stored charges. Activating it creates an
expanding cartoon shockwave around the planet and removes UFOs inside the blast.
Barrier hits and blast kills do not add bonks.

After the planet has lost health and the repair timer is ready, a temporary
heart pickup appears at a random visible point away from the planet. Clicking or
tapping it restores one health, up to five. At 20 active UFOs, new-wave timing is
multiplied by 2.5 to ease arena crowding while preserving the endless run.

The HIGH HUD card tracks the highest bonk count and saves new records immediately to
`user://highest_bonks.cfg`. Restarting clears the current bonk count but keeps the
record. No audio, upgrades, cloud saves, or shape recognition.
Automated tests verify mechanics; difficulty and drawing feel need playtesting.

Check whether players can aim rebounds using the trajectory indicators, whether
five seconds allows enough tactical control, and whether the shared ink budget
encourages useful choices between short and long barriers. Check whether the
10-second stun gives enough time to cause collisions and whether players
understand that a returning gold UFO remains dangerous. Deflecting a UFO buys
time, but only crashing UFOs together removes that threat and adds bonks.
