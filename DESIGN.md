# Draw the Orbit / barrier prototype

## Gameplay

Players draw reflective barriers to redirect alien-controlled UFOs into other UFOs.
Barrier angle determines the rebound, so predicting trajectories is the main
interaction. The barrier replaces the earlier drone-and-route mechanic.
Survivors recover control and return to attack, making a deflection temporary
unless the player crashes UFOs into each other.

## Implemented rules

The presentation adapts to portrait and landscape while keeping simulation
coordinates fixed. Portrait rotates the arena by 90 degrees and keeps the planet
and pilots upright. Drawing uses the inverse display transform, so ink costs,
collision widths, and travel speeds do not depend on screen size. The compact
HUD occupies its own space; pause, resume, and restart all work by touch.
Resizing cancels the unfinished stroke, while active barriers and UFOs persist.

- Multiple active freeform barriers; open strokes and closed loops are accepted.
- Release to add a barrier with its own 5-second lifetime. It disappears on expiry.
- Sketches use approximately 6 px sampling and a 24 px minimum.
- All active barriers and the current sketch share a 1550 px length budget.
  A stroke clamps to available ink. Release also validates the shared limit.
- Expiring barriers return exactly their own ink. With less than 24 px available,
  starting a new stroke is blocked until ink returns. There is no separate count cap.
- Cancelled or invalid sketches cost no ink and leave active barriers intact.
- Countdown labels and a final-second fade show barrier expiry. The sidebar shows
  committed and pending ink plus the next refill. Pausing freezes all lifetimes.
- Reject self-crossings and segments within 58 px of the planet center.
- Require a continuous 60-degree clear approach toward the planet across all
  active barriers plus the candidate sketch. Project barrier segments onto
  angular intervals from the planet and expand for UFO radius plus barrier width.
  Merge these intervals and reject the sketch if the largest gap is too narrow.
  This blocks closed shields, tiny gaps, overlapping strokes, and layered barriers
  that collectively cover every approach, even if no single stroke is a loop.
- Closed traps away from the planet remain valid if they leave a wide approach.
  Rejected enclosure sketches keep existing barriers and spend no ink; expired
  barriers stop contributing to the restriction. Preview and release use the same
  validation so players see the reason before committing a stroke.
- A sketch never pauses the world or disables existing barriers. Ink returned
  during a sketch can be used immediately to extend it.
- UFOs reflect from either side and rounded endpoints, preserving speed.
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
- Five planet hits, 90-second survival, no automatic starting defense.
- Adaptive physics substeps limit movement to 4 px to prevent fast UFOs from
  passing through barriers or each other. All UFOs move before pairs resolve.

## Scope and playtesting

Presentation uses a navy, mint, peach, and lavender palette with rounded cards.
Procedural cartoon artwork is isolated in `space_art.gd`; `game_view.gd` handles
the HUD and menus. Saucer color variants share the same collision behavior.
Pilots have determined or dizzy expressions; the planet blinks, smiles, and
reacts to damage. Barriers glow, stars twinkle, and collisions produce star
particles and floating scores. The HUD shows time, hearts, ink, and score with
minimal labels. Decorative captions, repeated instructions, and the enemy legend
are omitted. Only actionable warnings appear during play; menus use short titles
and buttons. Six desktop states can be captured with the visual
preview script for layout review.
The title uses its own full-screen composition, with no gameplay HUD behind it:
large stacked lettering, a floating planet and UFOs, slow orbital trails, and a
warm Play button with a subtle pulse and hover feedback. Compact screens stack
the title above the illustration and keep Play near the bottom.

No audio, upgrades, persistent saves, or shape recognition.
Automated tests verify mechanics; difficulty and drawing feel need playtesting.

Check whether players can aim rebounds using the trajectory indicators, whether
five seconds allows enough tactical control, and whether the shared ink budget
encourages useful choices between short and long barriers. Check whether the
10-second stun gives enough time to cause collisions and whether players
understand that a returning gold UFO remains dangerous. Deflecting a UFO buys
time, but only crashing UFOs together removes that threat and earns points.
