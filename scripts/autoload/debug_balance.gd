extends Node
## Exposed tuning knobs for balance pass.
## Baked defaults target: new player clears Waves 1–3; Wave 5 reachable; Wave 10+boss on practiced runs.

## Targets (see docs/BALANCE.md)
## - Waves 1–3 clearable with Tail Slap only
## - Wave 5 reachable on a good first run
## - Wave 10 + boss on practiced runs

var wave_budget_mult: float = 1.0
var hp_mult: float = 1.0
var dmg_mult: float = 1.0
var player_damage_mult: float = 1.0
var xp_mult: float = 1.0
var breather_duration: float = 2.8  # base reference; per-wave values scale from this
var node_hp_mult: float = 0.9  # slightly faster chew so mining stays meaningful
var show_dev_overlay: bool = false


func reset_defaults() -> void:
	wave_budget_mult = 1.0
	hp_mult = 1.0
	dmg_mult = 1.0
	player_damage_mult = 1.0
	xp_mult = 1.0
	breather_duration = 2.8
	node_hp_mult = 0.9
