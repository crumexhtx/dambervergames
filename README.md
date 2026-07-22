# Beaver Survivor

Mobile-first top-down auto-shooter: chew wood, survive forest swarms, extract to the dam.

DRG-inspired loop (mine under fire → swarms → extract) with a cute beaver fantasy.

## Requirements

- [Godot 4.3+](https://godotengine.org/) (4.x Forward Plus / Mobile renderer)

## Run

1. Open this folder in Godot (`project.godot`)
2. Press **F5** (main scene: `scenes/main_menu.tscn`)
3. Play with keyboard (WASD + Space dash + Esc pause) or touch joystick + DASH button

## Controls

| Input | Action |
|-------|--------|
| Left virtual stick / WASD | Move |
| Dash button / Space / tap right side | Dash |
| Auto | Weapons fire, loot vacuum, chew nodes |
| Hold in Dam zone (after boss) | Extract (needs ≥1 wood, 3s) |

## Project layout

- `docs/DESIGN.md` — systems blueprint summary
- `scenes/` — main menu, run, unlocks, settings
- `scripts/` — player, weapons, enemies, waves, loot, meta, UI

## Meta

Bank wood from successful extracts. Spend it on Unlocks (HP, Stick/Sap pool, berry, decoy, second dash).

## Debug

Settings → debug sliders for wave budget, HP/DMG multipliers, XP, breather, node HP.
