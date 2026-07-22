# Testing

## Smoke (scene boots)

```bash
godot --headless --path . --script res://scripts/dev/smoke_test.gd
```

Expect: `SMOKE_OK`

## Unit checks (save, upgrades, abandon, pickup guards, character animator)

```bash
godot --headless --path . res://scenes/dev/unit_checks.tscn --quit-after 120
```

Expect: `UNIT_CHECKS_OK`

## Manual playtest focus

1. Pickups never double-award wood/XP
2. Fox telegraph line stays fixed; lunge follows that line
3. Burr Coat / Decoy / Overbite offered at most once per run
4. Release export: Settings has no balance sliders
5. Notch devices: HUD / pause clear of safe area
6. Beaver / enemies bob and face move direction; dash/attack/hit/death poses play; fox telegraph/lunge anims
