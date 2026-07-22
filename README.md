# Beaver Survivor

Mobile-first top-down auto-shooter: chew wood, survive forest swarms, extract to the dam.

DRG-inspired loop (mine under fire → swarms → extract) with a cute beaver fantasy.

## Requirements

- [Godot 4.3+](https://godotengine.org/) (Mobile renderer)

## Run

1. Open this folder in Godot (`project.godot`)
2. Press **F5** (main scene: `scenes/main_menu.tscn`)
3. Play with keyboard (WASD + Space dash + Esc pause) or touch joystick + DASH button

## Controls

| Input | Action |
|-------|--------|
| Left virtual stick / WASD | Move |
| Dash button / Space | Dash |
| Auto | Weapons fire, loot vacuum, chew nodes |
| Hold in Dam zone (after boss) | Extract (needs ≥1 wood, 3s) |

## Android export

See [`docs/ANDROID_EXPORT.md`](docs/ANDROID_EXPORT.md). Copy `export_presets.cfg.example` → `export_presets.cfg`.

## Meta / v1.1

Bank wood from extracts (and **25% on death from Wave 6+**). Unlock tree includes Stick/Sap/Chomp pools, Decoy, **1 free level-up reroll**, second dash.

## Project layout

- `docs/DESIGN.md` — systems blueprint
- `docs/ART.md` — character animation + sprite drop-in pipeline
- `assets/sfx/` — procedural hit / pickup / level-up WAVs
- `assets/sprites/characters/` — optional per-character `sheet.png` overrides
- `scripts/fx/character_animator.gd` — idle/run/dash/chew/attack/hit/death
- `scripts/fx/silhouettes.gd` — articulated beaver / enemy / prop shapes
- `scenes/` — menu, run, unlocks, settings

## Debug / mobile options

Settings → reduce shake, damage numbers, large joystick, **perf lite**.

**Debug builds only:** balance sliders + F3 overlay (hidden in release exports).

## Testing

See [`docs/TESTING.md`](docs/TESTING.md) for headless smoke + unit checks.
