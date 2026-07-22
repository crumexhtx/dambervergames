# Beaver Survivor — Systems Design (v1)

Single-player, top-down auto-shooter with mining/loot and extract. Beaver theme. Mobile-first.

**Pillars:** auto-shooting · upgrade choices · swarm survival · mining/loot

Fantasy: DRG-inspired drop-in → mine under fire → survive swarms → extract haul to the dam. Cute, chaotic, cartoon fails (never gory).

Working titles: **Beaver Survivor** · **Dam It: Survivor** · **Chew & Survive**

## Win / Lose / Extract

- **10 waves** + **Bulldozer boss** (~8–10 min)
- Wave clear: kill ~70% of spawned budget **or** survive duration cap
- Breather 2–3s between waves (shrinks later)
- **Win:** clear Wave 10, finish boss phase, channel **3s** in Dam with ≥1 wood
- Boss timeout (~90s): extract still opens (reduced wood bonus)
- **Lose:** HP → 0; silly defeat summary

## Player (start)

| Stat | Start |
|------|------:|
| Max HP | 100 |
| Move speed | 3.2 u/s (cap ~5 / +60%) |
| Pickup radius | 1.2 u |
| Armor | 0 (soft cap 40%) |
| Dash | 1 charge, 4s CD, 2.5 u, 0.25s i-frames |
| Chew | 15/s to nearest node in 1.5 u (always-on) |

Contact damage ticks every **0.5s**. Berries auto-heal +20 below 40% HP.

## Controls (mobile)

Virtual joystick move · tap/button dash · auto weapons · auto vacuum · hold dam to extract.

## Weapons (max 3)

- **Tail Slap** (starter): aura pulse 1.0s / 12 dmg / 1.4 u
- **Stick Throw**: nearest projectile 0.85s / 18 dmg
- **Sap Spray**: facing cone 0.4s / 6 dmg + 20% slow
- Ranks 0–5 via upgrade cards (+15% dmg; every 3rd: +radius or −CD)

## Upgrades

On level-up: soft-pause, **3 cards**. Weights ~60% owned/common · 25% new weapon · 15% rare. Pool includes Thick Fur, Webbed Hustle, Bark Armor, Curious Beaver, Cheek Pouch, Mean Streak, Burr Coat, Decoy Dam, Overbite.

## Mining & loot

Sapling / Tree / Rock / Berry bush / Crate → wood, stone, berries, XP. Vacuum in pickup radius.

## Enemies & waves

Rat (1) · Hornet (2) · Fox (5) · Drone (4) · Elite ×3 cost. Alive cap 80. Elites from Wave 4+. Patterns: trickle / burst / ambush.

**Boss — Bulldozer** (1200 HP): chase + push → hornet packs @60% → charge telegraph @30%.

## Map

Forest clearing ~50×50 u, hand-scattered props, ponds, Dam Extract Zone north. Soft bounds. Camera follow + lead.

## Meta (banked wood)

50 HP · 100 Stick pool · 150 start berry · 200 Sap pool · 300 Decoy · 400 second dash. No energy gate.

## Feel / a11y

Screen shake, damage numbers, vacuum, level-up cards, leaf death bursts. Toggles: reduce shake, damage numbers, large joystick.

## Debug knobs

Wave budget · enemy HP/DMG · player DMG · XP · breather · node HP.

## Out of v1

Classes, biomes, co-op, endless, carry weight, rerolls/banishes, dailies, partial bank-on-death (v1.1).

*Living doc — update when systems change in implementation.*
