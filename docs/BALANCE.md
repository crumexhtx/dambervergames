# Balance targets (feel & fairness pass)

Baked into wave table / weapon / enemy defaults. Debug sliders still override.

## Player targets

| Milestone | Goal |
|-----------|------|
| Waves 1–3 | Clearable with **Tail Slap only** + dash |
| Wave 5 | Reachable on a good first run |
| Wave 10 + boss | Practiced runs; timeout extract is a weaker win |
| Breather | Long enough to chew/vacuum; enemies **freeze** during breather |

## Tuned defaults (this pass)

- **Tail Slap:** 14 dmg / 0.9s / 1.5u, stronger knockback
- **Early waves:** lower budgets + HP mults (W1 budget 10 @ 0.9×)
- **Rats / Hornets:** slightly less HP & contact
- **Fox:** 0.45s orange line telegraph before lunge; lower contact
- **Drone:** 2.2s fire rate, 8 dmg bolts, diamond tip cue
- **Boss:** 1050 HP, 18 contact
- **Wave clear wood:** `max(2, wave)` pile + slightly more XP gems
- **Node HP mult default:** 0.9 (faster chew)
- **Breather base:** 2.8s reference

## Dev overlay

In-run **F3** (or Settings → Dev overlay): FPS, enemy count, wave phase, budget kill %, wood/min, damage dealt.

## Checklist

1. New player clears Waves 1–3 without upgrade luck?
2. Move-only dodge fair vs fox lunge by Wave 5?
3. Breathers long enough to chew, short enough to keep pressure?
4. Wood scarcity meaningful without starving combat XP?
5. ~60fps mid phone with 80 enemies on Wave 10? (use Perf lite if needed)
