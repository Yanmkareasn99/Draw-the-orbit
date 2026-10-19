# Draw the Orbit / barrier prototype

## Gameplay

Players draw reflective barriers to redirect moving hazards into other hazards.
Barrier angle determines the rebound, so predicting trajectories is the main
interaction. The barrier replaces the earlier drone-and-route mechanic.

## Implemented rules

- One active freeform barrier; open strokes and closed loops are accepted.
- Release to activate. A new valid stroke replaces the previous barrier.
- Sketches use approximately 6 px sampling, a 24 px minimum, and a 1550 px budget.
- Reject self-crossings and segments within 58 px of the planet center.
- A sketch never pauses the world or disables the existing barrier.
- Hazards reflect from either side and rounded endpoints, preserving speed.
- Contact separation prevents sticking; there is no cooldown preventing rebounds.
- A cyan hazard has bounced. Collision with another active hazard destroys both.
- Each destroyed hazard awards 100 points; a pair awards 200.
- Untouched hazards pass through each other, keeping spawn clusters intact.
- Warning hazards are inactive for 1.2 seconds. Off-arena hazards are discarded.
- Both original and bounced hazards can damage the planet.
- Five planet hits, 90-second survival, no automatic starting defense.
- Adaptive physics substeps limit movement to 4 px to prevent fast hazards from
  passing through barriers or each other. All hazards move before pairs resolve.

## Scope and playtesting

No audio, upgrades, persistent saves, touch-specific UI, or shape recognition.
Automated tests verify mechanics; difficulty and drawing feel need playtesting.

Check whether players can aim rebounds using the trajectory indicators, whether
replacing one barrier allows enough tactical control, and whether closed loops
make survival too easy. Survival and destruction score offer different goals:
a barrier that sends everything out of the arena protects the planet but earns
no destruction points.
