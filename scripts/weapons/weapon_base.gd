extends Node2D
class_name WeaponBase
## Base auto-weapon with target policies.

enum Policy { NEAREST, RANDOM_IN_RANGE, AURA, FACING }

@export var weapon_id: String = ""
@export var policy: Policy = Policy.NEAREST
@export var base_cooldown: float = 1.0
@export var base_damage: float = 10.0
@export var base_range: float = 4.0
@export var prioritize_elites: bool = false

var cooldown_left: float = 0.0
var player: Player


func setup(p: Player) -> void:
	player = p


func rank() -> int:
	return int(GameState.weapon_ranks.get(weapon_id, 0))


func cooldown() -> float:
	var cd := base_cooldown
	var r := rank()
	# every 3rd rank: -10% cooldown
	var reductions := int(r / 3)
	cd *= pow(0.9, reductions)
	return cd


func damage() -> float:
	var dmg := base_damage * (1.0 + 0.15 * rank())
	return dmg * GameState.global_damage * DebugBalance.player_damage_mult


func range_px() -> float:
	var r := base_range
	var rank_i := rank()
	var radius_bonuses := int(rank_i / 3)
	r += 0.2 * radius_bonuses
	return GameState.pixels(r)


func _process(delta: float) -> void:
	if player == null or not GameState.run_active or GameState.soft_paused:
		return
	cooldown_left -= delta
	if cooldown_left <= 0.0:
		fire()
		cooldown_left = cooldown()


func fire() -> void:
	pass


func find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_score := INF
	var r := range_px()
	var candidates: Array[Node2D] = []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d := player.global_position.distance_to(e.global_position)
		if d <= r:
			candidates.append(e)
	if candidates.is_empty():
		return null
	match policy:
		Policy.RANDOM_IN_RANGE:
			return candidates[randi() % candidates.size()]
		Policy.FACING, Policy.AURA:
			return null
		_:
			for e in candidates:
				var d := player.global_position.distance_to(e.global_position)
				var score := d
				if prioritize_elites and ("elite" in e.get_groups() or (e.get("is_elite") == true)):
					score -= 1000.0
				if e.is_in_group("boss"):
					score -= 2000.0
				if score < best_score:
					best_score = score
					best = e
			return best
