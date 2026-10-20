# Draw the Orbit / barrier prototype

## Gameplay

Players draw reflective barriers to redirect alien-controlled UFOs into other UFOs.
Barrier angle determines the rebound, so predicting trajectories is the main
interaction. The barrier replaces the earlier drone-and-route mechanic.
Survivors recover control and return to attack, making a deflection temporary
unless the player crashes UFOs into each other.

## Implemented rules

Mobile play requires landscape. The browser shell requests fullscreen and a
landscape lock on a user gesture, and supplies a portrait rotate-device screen
when locking is unavailable or denied. The game also blocks input and physics
in mobile portrait, pauses active runs, and cancels drafts. Returning to landscape
requires an explicit Resume. Native handheld orientation uses sensor landscape;
desktop portrait windows remain supported.

The presentation fills the canvas above a separate 60 px bottom toolbar in
portrait and landscape, using uniform scale and expanding the arena bounds to
the playfield edges. A visible divider separates play from controls. The planet stays
centered and UFO spawn positions follow the new bounds. Portrait rotates the arena by 90 degrees and keeps the planet
and pilots upright. Drawing uses the inverse display transform, so ink costs,
collision widths, and travel speeds do not depend on screen size. The compact
HUD sits in one centered horizontal row in the bottom bar; pause, resume, and
restart all work by touch. Text determines card widths. Narrow screens use
labels above values, a heart count, and abbreviated large scores. Toolbar taps
never start strokes, and dragging into the bar cancels the unfinished stroke.
Resizing cancels the unfinished stroke, while active barriers and UFOs persist.

- Multiple active freeform barriers; open strokes and closed loops are accepted.
- Release to add a barrier with its own 5-second lifetime. It disappears on expiry.
- Sketches use approximately 6 px sampling and a 24 px minimum.
- All active barriers and the current sketch share a 1550 px length budget.
  A stroke clamps to available ink. Release also validates the shared limit.
- Expiring barriers return exactly their own ink. With less than 24 px available,
  starting a new stroke is blocked until ink returns. There is no separate count cap.
- Cancelled or invalid sketches cost no ink and leave active barriers intact.
- Countdown labels and a final-second fade show barrier expiry. The ink card shows
  the remaining percentage including pending ink; a refill message appears when
  ink runs out. Pausing freezes all lifetimes.
- Reject self-crossings and segments within 58 px of the planet center.
- Reject only fully closed enclosures around the planet across all active barriers
  plus the candidate sketch. Any gap between the drawn lines is allowed, with no
  minimum angle and no expansion for UFO radius or barrier width. Segment contacts
  form a graph; a cycle with nonzero winding around the planet closes it in.
  Endpoint contacts, intersections, and collinear overlaps all connect barriers.
  Staggered open walls remain allowed even when they block every straight approach.
- Closed traps away from the planet remain valid.
  Rejected enclosure sketches keep existing barriers and spend no ink; expired
  barriers stop contributing to the restriction. Preview and release use the same
  validation so players see the reason before committing a stroke.
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
  both. Each destroyed UFO awards 100 points; a pair awards 200.
- Untouched UFOs pass through each other, keeping spawn clusters intact.
- Warning UFOs are inactive for 1.2 seconds. At the arena boundary, stunned UFOs
  bounce inward while retaining their stun timer; recovered pilots head toward
  the planet. UFOs never disappear for free.
- Both original and bounced UFOs can damage the planet.
- UFO visuals use procedural saucers, glass canopies, green alien pilots,
  engine trails, and lights for incoming, stunned, and returning states.
- Five planet health points, endless survival, no automatic starting defense.
  Only zero health ends a run; the clock counts up and results include survival time.
- Standard saucers are joined by Scouts after 10 seconds (1.55x speed, 7 px
  radius), Weavers after 25 seconds (1.1x speed, sinusoidal approach steering),
  and Brutes after 45 seconds (0.72x speed, 15 px radius, two damage).
  Weavers stop weaving when redirected and share normal stun/recovery behavior.
- Difficulty caps at five UFOs per wave, a 2.3-second spawn interval, 78 px/s
  base speed before type multipliers, and 48 simultaneous UFOs. A full arena
  skips new spawns until space opens; existing enemies remain active.
- Adaptive physics substeps limit movement to 4 px to prevent fast UFOs from
  passing through barriers or each other. All UFOs move before pairs resolve.

## Scope and playtesting

Presentation uses a navy, mint, peach, and lavender palette with rounded cards.
Procedural cartoon artwork is isolated in `space_art.gd`; `game_view.gd` handles
the HUD and menus. UFO types have distinct hull colors, sizes, and silhouettes:
Scouts have swept fins, Weavers have side coils, and Brutes have plated hulls.
Pilots have determined or dizzy expressions; the planet blinks, smiles, and
reacts to damage. Barriers glow, stars twinkle, and collisions produce star
particles and floating scores. The HUD shows time, hearts, ink, and score with
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

The BEST HUD card tracks the highest score and saves new records immediately to
`user://highest_score.cfg`. Restarting clears the current score but keeps the
record. No audio, upgrades, cloud saves, or shape recognition.
Automated tests verify mechanics; difficulty and drawing feel need playtesting.

Check whether players can aim rebounds using the trajectory indicators, whether
five seconds allows enough tactical control, and whether the shared ink budget
encourages useful choices between short and long barriers. Check whether the
10-second stun gives enough time to cause collisions and whether players
understand that a returning gold UFO remains dangerous. Deflecting a UFO buys
time, but only crashing UFOs together removes that threat and earns points.
