# Art & Animation Pipeline — Beaver Survivor

Characters ship with **articulated polygon silhouettes** plus a drop-in path for custom sprite sheets. You do not need to wait on final art to playtest motion.

## What runs today

| Mode | When | How it animates |
|------|------|-----------------|
| **Silhouette** (default) | No `sheet.png` / `sprite_frames.tres` | Named parts (`body`, `head`, `tail`, wings…) driven by `CharacterAnimator` |
| **Sprite** | Sheet or SpriteFrames present under the character folder | `AnimatedSprite2D` plays `idle` / `run` / `dash` / `chew` / `attack` / `hit` / `death` / `telegraph` / `lunge` |

Code entry points:

- `scripts/fx/character_animator.gd` — state machine + motion
- `scripts/fx/character_catalog.gd` — per-character paths and layout
- `scripts/fx/silhouettes.gd` — articulated builders (`build_beaver`, …)

## Folder layout

```
assets/sprites/characters/<id>/
  sheet.png              # optional: auto-sliced at runtime
  sprite_frames.tres     # optional: wins over sheet.png if both exist
```

Character ids: `beaver`, `hornet`, `rat`, `fox`, `drone`, `bulldozer`.

## Sheet convention (Aseprite / LibreSprite)

Default for most cast:

- Frame size **48×48** (bulldozer **64×64**)
- **6 columns**
- Nearest-neighbor / pixel art; export PNG with transparency
- Facing: draw looking **right** (code flips for left)

| Row | Animation | Frames | Loop | Notes |
|----:|-----------|-------:|:----:|-------|
| 0 | idle | 4 | yes | Breath / sway |
| 1 | run | 6 | yes | Clear silhouette bounce |
| 2 | dash | 3 | no | Stretch / blur ok |
| 3 | chew | 4 | yes | Head/jaw emphasis |
| 4 | attack | 4 | no | Tail slap / bite / shoot |
| 5 | hit | 2 | no | Flash pose |
| 6 | death | 4 | no | Cartoony flop |
| 7 | telegraph | 2 | yes | Fox / boss wind-up |
| 8 | lunge | 3 | no | Commit attack |

Total sheet height ≈ `9 × frame_h`. Extra empty rows are fine.

### Aseprite export

1. One layer or flattened PNG.
2. File → Export Sprite Sheet → **By rows**, frame size matching table.
3. Save as `assets/sprites/characters/<id>/sheet.png`.
4. Open project once in Godot so the `.import` file is generated.

Optional: build a `SpriteFrames` resource in the editor and save as `sprite_frames.tres` in the same folder for hand-tuned FPS / frame order.

## Style guide (game feel)

- Cute, chaotic, readable at ~32–64 px on mobile
- High contrast silhouette first; detail second
- No gore — cartoon fails only
- Elite tint is applied in code; keep base art readable without it

## Authoring new characters

1. Add a branch in `CharacterCatalog.get_def`.
2. Add `Silhouettes.build_<name>` + wire `build_articulated`.
3. Set `enemy_id` / player setup id to match.
4. Drop sprites later under `assets/sprites/characters/<id>/` — no further code needed if layout matches.

## Tools

Recommended: **Aseprite** or **LibreSprite**. Spine/DragonBones are not required for v1; flip-book sheets keep the mobile build simple.
