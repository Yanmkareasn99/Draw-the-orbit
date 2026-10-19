# Draw the Orbit / prototype 0.1

## Hypothesis
Drawing a route is interesting when players can predict interception timing and
trade coverage against lap time. This build isolates that hypothesis using one
route and one fixed-speed drone.

## Decisions implemented
- Freeform closed polygonal routes, sampled at approximately 6 px spacing.
- One active route; a sketch does not suspend the previous route.
- 30 px closure tolerance; no shape classification.
- 1550 px maximum including the closing edge.
- Reject self-crossing paths and any segment within 58 px of the planet center.
- Preserve the player's chosen drawing direction.
- Transfer to the nearest route point at normal speed, with collisions disabled.
- Fixed-speed drone and straight-moving hazards with short spawn warnings.
- Five planet hits, a 90-second survival objective, 100 points per interception.
- Four simulation substeps per physics tick to reduce collision tunnelling.

## Intentional scope limits
No gesture recognition, route auto-smoothing, upgrades, audio, touch-specific UI,
orbital physics, persistent saves, or online features. Six-pixel sampling suppresses
small input noise but does not beautify a route. Routes may sit on one side of the
planet; enclosing the planet is not required.

## Risks to test
1. Is a tight circle always the best route? If so, experiment with directed waves
   and interception rewards before adding arbitrary anti-circle penalties.
2. Can players predict misses from the path indicators and lap-time display?
3. Does relocation feel like a fair cost, or an annoying interruption?
4. How often does an intentional loop fail validation? Adjust tolerance first.
5. Are players redrawing for a purpose or randomly hoping for better outcomes?
6. Is 90-second survival achievable without a degenerate route?

Watch several short runs before changing multiple tuning values. Record survival,
interceptions, and whether the player can explain a route change. This version
has automated correctness checks but has not been balanced with human playtests.
