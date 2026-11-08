# Sora Tsunagi (空繋ぎ)

First playable prototype of Thong Do’s endless 2D anime dash game, plus the design draft. Sora Tsunagi (空繋ぎ, loosely "mending the sky") is the working title, pending native Japanese review and trademark clearance.

This is a separate project from **Reincarnated as WHAT?!** and **Kinetic Arm**.

This build starts in Moonheld. It is a landscape runner meant to prove run, jump, dash, and dash-or-die on a phone. The world loop order is Glassfall, Moonheld, Lanternfall, and this run begins at Moonheld. Glassfall and Lanternfall still have no plates. Sky Slivers are pickups. Guardians are named but not fought yet. The other fighters, music, ads, and the leaderboard are out of scope.

- [Design draft](docs/DESIGN.md) (latest, November 7 2026)
- [Build plan v1](docs/BUILD_PLAN_V1.md)
- [Art direction](docs/ART_DIRECTION_PROPOSAL.md)

## Run it

Tested with **Godot 4.7.2** (the 4.7 line). The project uses the GL Compatibility renderer.

1. Install Godot 4.7 from [the engine site](https://godotengine.org/download).
2. Open this folder (`project.godot`) in the Godot project manager.
3. Press F5 / Play. The window is a 16:9 view of a 1920×1080 playfield.

On the start screen, tap anywhere (or press Space / Enter). The same run keeps one score across three lives. Falling off or touching a monster without dashing costs a life and drops you on the next platform. The third loss opens the score screen; tap again to run from the start.

### Controls

| Input | Action |
|---|---|
| Left half of the screen, tap | Short hop. Hold through the rise for a full jump |
| Left half, tap again in the air | Weaker double jump (a tuck / gainer, not a second hop) |
| Right half, tap | Dash-punch. The coated fist only comes out during the dash |
| Falling fast onto a platform | Knees absorb it. A hard landing rolls and sheds a little speed |
| Mouse | Same zones, left button. Right button dashes |
| Keyboard | Space / W / Up jump and glide. Shift / K / J dash |

Jumps have coyote time and a short input buffer. A dash that doesn't kill anything breaks the combo. Getting hit breaks it too.

## Web build

Export templates for 4.7.2 have to be installed once (Editor → Manage Export Templates, or the path below). The Web preset is `export_presets.cfg`. Thread support is off so the build can be hosted as static files.

```bash
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server --directory build/web 8080
```

Open `http://localhost:8080`. Browsers will not run a Godot web build from `file://`. The first tap starts the run and unlocks audio. Phones should be landscape; portrait shows a rotate hint.

The Web preset is single-threaded (`variant/thread_support=false`) and the page shell in `export/web_shell.html` keeps the canvas on the screen (`100dvh`, no scroll, `touch-action: none`). GitHub Pages cannot send the COOP/COEP headers a threaded build would need, so this is the build that runs at [https://thongdo05.github.io/sora-tsunagi/](https://thongdo05.github.io/sora-tsunagi/).

`.github/workflows/pages.yml` exports that preset on every push to `main` and deploys it with GitHub Pages. Pull requests still upload a `glassfall-web` artifact from `.github/workflows/web-export.yml` and do not publish the site. Use the trailing slash on the Pages URL so `index.js` and `index.wasm` resolve inside `/sora-tsunagi/`.

iOS and Android presets are not included. Web is the phone test path for v1.

## Tuning

All gameplay numbers are in [`assets/tuning/game_tuning.tres`](assets/tuning/game_tuning.tres) (`GameTuning` in `game_tuning.gd`). That includes run speed and its ramp, gravity, jump and double-jump velocities, glide, dash distance / duration / cooldown, coyote time and buffers, hit-stop, shake, monster odds, gap ratios, and scoring. Change a value and press F5.

Jump height is `jump_velocity² / (2 × gravity)`. Dash length is `dash_distance` pixels covered during `dash_duration`.

## What is placeholder

- The pirate is the single attack-pose cutout. At rest a mask recolors the coated arm to skin and hides the painted lightning. The black arm and red-black sparks come back only during the dash. A small patch of the original coating can remain where the sleeve meets the forearm. Bob and squash are code, not new frames.
- Platforms are the Moonheld dock pieces in `assets/worlds/moonheld/` (docks, coral ledges, stone slabs, buoys). Monsters are still drawn shapes. The backdrop streams the six-panel Moonheld chain from `assets/worlds/world_loop.tres`. That resource still lists Glassfall, then Moonheld, then Lanternfall. `start_id` is `moonheld`.
- Sky Slivers sit on jump and dash arcs. Collecting one plays a short chime that steps up in pitch. The HUD counts the run. The results screen shows that count and the lifetime total saved in `user://sora_progress.cfg`.
- UI is type and flat panels. There is no music.

Concept art stays out of this repo. The Glassfall look mock is a reference only and is not committed.

## Check

```bash
godot --headless --path . -s res://tests/smoke_test.gd
```

That bots a few seconds of a run, spends all three lives, and restarts. `SORA_NO_PAUSE=1` is worth setting if the window is unfocused. `SORA_SCREENSHOT` and `SORA_GAMEOVER` save PNGs when a display is available.
