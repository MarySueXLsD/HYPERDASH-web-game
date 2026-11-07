# Dialogue portraits

The game reads these pixel-art portraits by file name. Who plays whom is set
in `Art.CAST` (source/core/Art.hx):

| Character | File | Role |
|-----------|------|------|
| NOVA      | `181.png` | Pilot 1, HyperDash courier |
| VEX       | `495.png` | Pilot 2, corsair first mate |
| RUST      | `207.png` | Pilot 3, corsair captain |
| KADE      | `357.png` | Pilot 4, SwiftHaul rival |
| PIP       | `6.png`   | Pilot 5, the ship AI |
| DISPATCH  | `119.png` | HyperDash dispatcher |
| ZIB       | `12.png`  | The customer |

Not cast yet: 53, 303, 416, 464, 465, 475. Portraits are drawn at exactly
128 px (a 512 px source maps to 2 screen pixels per art pixel) without smoothing.
