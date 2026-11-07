# HYPERDASH art direction

## Subject
A cheap, overworked space courier company. The player is a delivery driver
on a guarantee clock. The look comes from **parcel logistics**, not from
generic cyberpunk: shipping labels, rubber stamps, kraft tape, hazard
stripes, waybills and receipts, laid over the deep space you fly through.

Rejected as the default look: cyan + magenta neon glow on black, scanlines,
glowing outlines on every panel, tracked-out all-caps labels, `A · B` meta
strings, and a big number with a small label.

## Pixel art
The whole frame is snapped to a 2 px grid and posterised in the camera pass
(`fx/PostShader.hx`), sprites draw without smoothing, and body text uses the
Nokia pixel font at 16/24/32 px. Portraits are hand-made pixel art drawn at an
exact 128 px so each source pixel lands on the grid.

## Palette roles
| Name    | Hex       | Role |
|---------|-----------|------|
| Void    | `#120E22` | Space backdrop (indigo, never flat black) |
| Ink     | `#211C2B` | Text on paper, outlines, stamp frames |
| Kraft   | `#D9B98A` | Buttons and labels (parcel tape / cardboard) |
| Paper   | `#EEEAE0` | Receipts, dialogue cards, overlays |
| Dash    | `#FF5B1F` | Brand safety orange: primary actions, the hero ship stripe |
| Hazard  | `#FFC21A` | Warnings, boss stripes, hints |
| Teal    | `#3FD6C2` | Engine glow and things you can interact with in-world |
| Stamp red / green | `#E5343F` / `#2FA866` | Fail / success ink |

## Type
- **Stencil**: the in-house stroke font (`VecFont`) drawn heavy, slanted and
  without glow, so it reads as a rubber stamp. Reserved for verbs, stamps and
  buttons.
- **Body**: Montserrat in sentence case, at least 16 px, never letter-spaced.

## The one bold thing
The **rubber-stamp prompt**. Every mini game is introduced by a distressed
ink stamp slammed onto the screen at a slight angle. Everything around it
stays quiet: flat paper, ink and kraft, with no glow on the UI.

## Glow budget
Glow (bloom) is only for light sources in the world: engines, lasers,
sparks, energy cells and warp streaks. UI never glows.

## Feedback tiers (game-feel)
| Tier   | Used for | Channels |
|--------|----------|----------|
| small  | taps, pickups, UI presses | sound, squash, 4–8 particles, trauma 0.12 |
| medium | clearing a game, a correct step | + shock ring, trauma 0.3, hit-stop 50 ms |
| large  | crashes, losing cargo, boss clear | + hit-stop 110 ms, trauma 0.7, flash, aberration |

Shake uses smooth decaying trauma (trauma², sine-sampled) on the camera only.
Players can turn shake and flashes off in Options.

## Assets
Everything is procedural (`core/Art.hx`), so there are no files to license.
Families share: ink outline weight (3 px at 1×), a light source from the top
left, and flat fills with one highlight.
