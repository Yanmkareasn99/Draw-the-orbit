# BONK! — promotional trailer

**Format:** portrait 9:16, 1080 × 1920, 30 fps. **Length:** approximately 60 seconds.
**Music:** the game's `audio/bgm.ogg`, approximately 104 BPM. English captions; no voiceover.
**CTA:** “Defend your planet now!”

## Part 1 — Hook · 00:00–00:09.48

| Scene | Time | Picture and action | On-screen copy | Edit / sound |
|---|---|---|---|---|
| 1 | 00:00–00:02.56 | The smiling planet is surrounded by incoming UFOs. The threat is immediately readable. | ONE PLANET. / TO PROTECT. | Music starts immediately; opening holds for one short phrase. |
| 2 | 00:02.56–00:04.87 | A visible drawing gesture creates a barrier while two UFOs are in frame. | ONE LINE. / TO FIGHT BACK. | Cut on the beat, quick mint/gold flash; actual drawing sound. |
| 3 | 00:04.87–00:09.48 | Continue the same encounter: a UFO rebounds and crashes into its target. | MAKE THEM / BONK! | Let the real rebound and collision sounds land over the BGM. |

## Part 2 — World, mechanics, gameplay · 00:09.48–00:51.02

| Scene | Time | Picture and action | On-screen copy | Edit / sound |
|---|---|---|---|---|
| 4 | 00:09.48–00:14.10 | A clean hero shot of the planet, orbit trails, stars, and circling UFOs. | A SMALL WORLD. / A BIG PROBLEM. | Eight-beat breath after the hook; gentle orbital motion. |
| 5 | 00:14.10–00:18.71 | Animated lineup of Saucer, Scout, Weaver, Brute, Dodger, and Phantom. | SIX UFO TYPES. / SIX NEW PROBLEMS. | Beat-aligned reveal; keep individual silhouettes and names readable. |
| 6 | 00:18.71–00:23.33 | Return to the actual playfield and draw a barrier with a moving gesture cue. | DRAW YOUR / DEFENSE. | Real drawing animation and sound; readable HUD. |
| 7 | 00:23.33–00:27.94 | Follow the rebound into the target; cyan marks the stunned UFO. | TURN ATTACKS / INTO AMMO. | Continue the encounter rather than replacing the UFOs at impact. |
| 8 | 00:27.94–00:32.56 | A fifth BONK charges the bomb; the bomb clears surrounding UFOs. | FIVE BONKS. / ONE BIG BOOM. | Highlight the actual bomb control; real blast effect and sound. |
| 9 | 00:32.56–00:37.17 | Show four health, tap the floating heart, and visibly restore five health. | KEEP YOUR / PLANET ALIVE. | Damage-to-heal contrast; pickup chime and readable +1 HP. |
| 10 | 00:37.17–00:41.79 | Busier gameplay: two barriers, varied UFOs, rebounds, and live HUD feedback. | MAKE EVERY / LINE COUNT. | Faster action within a steady eight-beat shot. |
| 11 | 00:41.79–00:46.40 | Show the moving mothership with redirected UFOs attacking it. | TAKE ON / THE MOTHERSHIP. | Boss hits punctuate the music; maintain gameplay movement. |
| 12 | 00:46.40–00:51.02 | Finish a level and reveal its stars and results. | SURVIVE. / CHASE THE STARS. | Reward sound and a brief hold to read the achievement. |

## Part 3 — Title and call to action · 00:51.02–01:00.25

| Scene | Time | Picture and action | On-screen copy | Edit / sound |
|---|---|---|---|---|
| 13 | 00:51.02–00:55.63 | Large BONK! title over the animated planet and orbital UFOs. | BONK! / DRAW. DEFLECT. BONK! / YOUR LINE. THEIR COLLISION. | Land the brand reveal on the beat. |
| 14 | 00:55.63–01:00.25 | Hold the title; reveal a large gold CTA below the planet. | DEFEND YOUR / PLANET NOW! | Loop the BGM opening to extend the track; fade out over the final second. |

The final card also lists **English / 日本語 / Tiếng Việt**. No store badge or game URL is added because none was supplied.

## Production notes

- Footage is staged and captured with the actual game renderer, physics, collisions, HUD, and sound effects. Hero and lineup shots use the game's existing character artwork.
- Primary edits follow a 104 BPM grid, with a detected beat offset of about 0.25 seconds. Scene cuts are rounded to the nearest 30 fps frame. Live collision sounds follow the actual contact frame.
- The source BGM lasts about 55.38 seconds. Its short loop extension preserves the game's musical theme while the CTA finishes.
- Deliverable: `BONK_Trailer_60s.mp4`. Source capture, capture scripts, and this storyboard make the trailer reproducible.

## Files and rebuilding

- `BONK_Trailer_60s.mp4`: H.264/AAC video, ready to share.
- `BONK_Trailer_60s.srt`: optional caption track matching the on-screen copy.
- `BONK_Trailer_Poster.jpg`: title-card thumbnail.
- `BONK_Trailer_CTA.jpg`: closing CTA still.
- `capture1080.avi`: intermediate capture with isolated gameplay sound effects.

With Godot and the Python `imageio-ffmpeg` package available, run from the repository:

```sh
python tests/build_trailer.py --godot /path/to/godot
```

The build prepares an isolated render project under this directory, records the
scenes, and mixes the original BGM. Edit `tests/trailer_capture.gd` for action and
timing, `tests/trailer_overlay.gd` for copy and motion graphics, and
`tests/trailer_edit.py` for final encoding and audio levels.
