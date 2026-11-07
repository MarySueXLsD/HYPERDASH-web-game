# itch.io page kit: HYPERDASH

Live page: https://marysue.itch.io/hyperdash

Everything below is ready to paste into the itch.io "Edit game" form, top to bottom.

---

## Basics

| Field | Value |
|---|---|
| **Title** | HYPERDASH: Lightspeed Courier |
| **Project URL** | `hyperdash` (or `hyperdash-lightspeed-courier` if taken) |
| **Short description / tagline** | Five couriers, one parcel, two minutes. A pixel-art microgame dash across the galaxy. |
| **Classification** | Games |
| **Kind of project** | HTML |
| **Release status** | Released (or *Prototype* if you'd rather signal "jam build") |
| **Pricing** | No payments (or "$0 or donate") |

## Uploads

- File: `dist/Hyperdash-itch.zip`, ticked as **This file will be played in the browser**.

## Trailer

Paste `https://www.youtube.com/watch?v=NmJwidkzUJU` into **Gameplay video or trailer** on the Edit game page. itch then shows the video above the game. The source render is `dist/itch/trailer/Hyperdash-trailer.mp4` (kept out of git; it's on YouTube).

The live page's description opens with "Ninety seconds of flying", but the game's guarantee is two minutes (`G.GUARANTEE = 120`, and the trailer says "2 minutes or it's free"). The description below keeps "Two minutes".

## Embed options

| Setting | Value |
|---|---|
| Embed in page | Manually set size |
| Viewport dimensions | **540 × 960** |
| Mobile friendly | ✔, orientation **Portrait** |
| Automatically start on page load | off (the game needs a tap first for sound anyway) |
| Fullscreen button | ✔ |
| Enable scrollbars | off |
| SharedArrayBuffer support | off |

---

## Description (paste into the description editor)

> **Two minutes of flying. Forty thousand light-years. Or it's free.**
>
> You drive for HyperDash Express, the cheapest courier in the galaxy. Your ship breaks every few seconds, and each fault is a microgame you have moments to fix: dodge rocks, rewire the reactor, dock at full burn. Every fix makes you faster, and the music speeds up with you.
>
> The delivery clock only runs while you're fixing things. Fast clears earn tips; mistakes cost cargo and time.
>
> ### Five couriers, one parcel
> When your pilot goes down, the next one pulls the parcel from the wreck and carries on. **Nova**, **Vex**, **Captain Rust**, **Kade** and **PIP** each bring their own story, ship and perk.
>
> ### Features
> - 24 microgames across five sectors, plus a Hyperlane boss
> - Story, Endless and Training modes
> - Pixel art, cutscenes, and a soundtrack that follows your speed
> - Mouse, touch or keyboard; shake and flashes can be turned off
>
> Made for **SlapJam**. Theme: **SPEED**.
>
> Character portraits by **Batareya**, from [500 Fantasy Pixel Art Portraits](https://batareya.itch.io/500-fantasy-pixel-art-portraits-a-world-of-characters-for-your-projects).

---

## Screenshots (upload in this order)

All are 1080 × 1920 PNG captures straight from the game, in `dist/itch/screenshots/`.

| File | What it shows |
|---|---|
| `01_title.png` | Title screen |
| `02_pilot_card.png` | Pilot 1 of 5: Nova's intro card |
| `03_cutscene_dispatch.png` | Cutscene with the Dispatch portrait |
| `04_prompt_grab.png` | A microgame prompt stamp: GRAB! |
| `05_jump_rings.png` | JUMP!: time the warp ring |
| `06_signed_fast.png` | A clean, fast delivery: SIGNED + FAST |
| `07_damaged.png` | A crash: DAMAGED, minus 6 seconds |
| `08_boss_warning.png` | The Hyperlane boss warning |

**Cover image:** `dist/itch/cover_630x500.png` (itch's recommended 630 × 500).

Simpler alternative: `dist/itch/cover_simple_630x500.png` (logo, ship and tagline, readable at the 315 × 250 thumbnail). Animated copies: `cover_simple_630x500.gif` and `cover_simple_630x500.apng.png`. Check the live page if you use one, because itch's handling of animated images has been unreliable.

---

## Metadata

| Field | Value |
|---|---|
| **Genre** | Action |
| **Tags** (itch allows up to 10) | `microgames`, `fast-paced`, `arcade`, `pixel-art`, `sci-fi`, `space`, `short`, `funny`, `mobile`, `singleplayer` |
| **Made with** | HaxeFlixel |
| **Average session** | A few minutes |
| **Languages** | English |
| **Inputs** | Mouse, Touchscreen, Keyboard |
| **Accessibility** | None of itch's checkboxes strictly apply. The description mentions the shake and flash toggles. |
| **Multiplayer** | None |
| **Player count** | Singleplayer |

## Theme (open your game page and click **Edit theme**)

The idea: the page looks like deep space at night, with the game's safety-orange brand and parcel-label colours on top.

### COLOR
| Field | Value | Why |
|---|---|---|
| **BG** | `#120E22` | The game's indigo space. Never flat black. |
| **BG 2** | `#211C2B` | Ink, for the content column. Slightly lighter, so the column reads as a panel. |
| **Text** | `#EEEAE0` | Receipt-paper off-white. Easy to read on ink. |
| **Link** | `#FF5B1F` | HyperDash safety orange. |

**More options…** under COLOR, where shown:
| Field | Value |
|---|---|
| Button color | `#FF5B1F` |
| Button text | `#211C2B` |
| Border color | `#3A3352` |
| Border radius / style | smallest / square (the game uses chamfered, not rounded, shapes) |

### TEXT
| Field | Value |
|---|---|
| **Font** | A pixel or mono face if the list has one: **VT323** or **Press Start 2P** for headers; otherwise **Cousine** or **Roboto Mono**. Keep body text in **Lato** if the pixel font is hard to read at length. |
| **Size** | Large |

**More options…** under TEXT: header font, the pixel font above. Header colour: `#FF5B1F`.

### LAYOUT
| Field | Value |
|---|---|
| **Screenshots** | **Sidebar**. The screenshots are tall (portrait), so a sidebar column shows them at a good size; "Auto" tends to make a wide row of tiny thumbnails. |

### IMAGES (files in `dist/itch/theme/`)
| Slot | File | Settings |
|---|---|---|
| **Banner** | `banner_960x300.png` | Align: center. It replaces the plain title text at the top of the page. |
| **Background** | `background_tile_512.png` | Repeat: **tile** (repeat both ways), position top-left. It tiles seamlessly. |
| **Embed BG** | `embed_bg_tile_512.png` | Repeat: **tile**. A darker, quieter starfield behind the game frame, so the 540 × 960 game stands out. |

Pixel art should stay sharp: upload the PNGs as they are, without resizing them in an editor first.

**Animated versions (optional).** These replace the three files above. Rebuild them with `python dist/itch/make_theme_gifs.py`.

| Slot | GIF | APNG (same animation) | Settings |
|---|---|---|---|
| **Banner** | `banner_960x300.gif` | `banner_960x300.apng.png` | Align: center |
| **Background** | `background_tile_512.gif` | `background_tile_512.apng.png` | Repeat: **tile** (repeat both ways), position top-left. It tiles seamlessly while it moves. |
| **Embed BG** | `embed_bg_540x960.gif` | `embed_bg_540x960.apng.png` | Repeat: **no repeat**, position center. The middle is kept clear for the Run game button. |

Simple still banner in the style of the cover image: `banner_simple_960x300.png` (Align: center). It has the logo, the five pilots and the tagline, and no animation.

Spare art-free versions, with no logo, text, ship, parcels, stamp or hazard stripe: `banner_clean_960x300` and `embed_bg_clean_540x960` (each also comes as `.gif` and `.apng.png`).

itch has been flattening some animated GIF banners to a single frame, so check the live page after uploading. If the GIF doesn't move, upload the APNG. Each file starts on its strongest frame, so a flattened image still looks finished.

---

## Before you publish

1. **Portrait licence: checked.** The portraits come from Batareya's
   [500 Fantasy Pixel Art Portraits](https://batareya.itch.io/500-fantasy-pixel-art-portraits-a-world-of-characters-for-your-projects).
   The page says they're "100% free for personal and commercial use", and attribution is not required but appreciated.
   The credit line is already in the description above and in the game's Credits screen.
   Optional: itch lets you link the asset pack under **Related links / "Made with"** on your page too.
2. **AI disclosure: your call.** itch.io asks whether a project uses generative AI. Two things to weigh:
   - The game's code, procedural art, music, sound and these page texts were written with an AI assistant.
   - The portrait pack's own page labels it **"AI Assisted" / "AI Generated"**.

   Answer that field to fit your jam's rules.
