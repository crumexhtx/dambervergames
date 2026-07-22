extends RefCounted
class_name UpgradePool
## Weighted 3-card offers from the v1 upgrade pool.

const CARDS := [
	{"id": "WPN_TAIL", "name": "Heavier Tail", "desc": "Tail Slap +1 rank", "rarity": "common", "kind": "weapon", "weapon": "tail"},
	{"id": "WPN_STICK", "name": "Sharper Sticks", "desc": "Stick Throw +1 / unlock", "rarity": "common", "kind": "weapon", "weapon": "stick"},
	{"id": "WPN_SAP", "name": "Stickier Sap", "desc": "Sap Spray +1 / unlock", "rarity": "common", "kind": "weapon", "weapon": "sap"},
	{"id": "STAT_HP", "name": "Thick Fur", "desc": "+20 Max HP, heal 20", "rarity": "common", "kind": "stat"},
	{"id": "STAT_SPD", "name": "Webbed Hustle", "desc": "+12% move speed", "rarity": "common", "kind": "stat"},
	{"id": "STAT_ARM", "name": "Bark Armor", "desc": "+8% armor", "rarity": "common", "kind": "stat"},
	{"id": "STAT_XP", "name": "Curious Beaver", "desc": "+20% XP gain", "rarity": "common", "kind": "stat"},
	{"id": "UTIL_MAG", "name": "Cheek Pouch", "desc": "+40% pickup radius", "rarity": "common", "kind": "util"},
	{"id": "UTIL_ATK", "name": "Mean Streak", "desc": "+12% global damage", "rarity": "common", "kind": "util"},
	{"id": "RARE_THORN", "name": "Burr Coat", "desc": "8 dmg aura / 0.5s", "rarity": "rare", "kind": "rare"},
	{"id": "RARE_DECOY", "name": "Decoy Dam", "desc": "Decoy every 12s", "rarity": "rare", "kind": "rare"},
	{"id": "RARE_OVERBITE", "name": "Overbite", "desc": "Dash deals 25 path dmg", "rarity": "rare", "kind": "rare"},
]


static func roll_offers(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for c in CARDS:
		if not _is_available(c):
			continue
		var weight := 60
		if c.rarity == "rare":
			weight = 15
		elif c.kind == "weapon" and c.weapon not in GameState.owned_weapons:
			weight = 25
		# At weapon cap, weapon unlocks convert to ranks of owned / stats — still allow owned weapon ranks
		if c.kind == "weapon" and c.weapon not in GameState.owned_weapons:
			if GameState.owned_weapons.size() >= GameState.max_weapons:
				continue
			# Stick/Sap gated by meta unless somehow already owned
			if c.weapon == "stick" and not MetaProgression.unlock_stick_in_pool and "stick" not in GameState.owned_weapons:
				# Still allow mid-run unlock via card once meta unlocked OR after level 3 naturally
				# Design: Stick available in offers when meta unlocked; also allow from level offers after early game
				if GameState.level < 3:
					continue
			if c.weapon == "sap" and not MetaProgression.unlock_sap_in_pool and GameState.level < 6:
				continue
		if c.id == "RARE_DECOY" and not MetaProgression.unlock_decoy_in_pool:
			# Still allow rare if decoy unlocked via meta; otherwise skip until unlocked
			continue
		for i in weight:
			pool.append(c)
	var offers: Array[Dictionary] = []
	var used: Dictionary = {}
	while offers.size() < count and pool.size() > 0:
		var pick: Dictionary = pool[randi() % pool.size()]
		if used.has(pick.id):
			# allow duplicates for stackable sometimes — skip identical in same offer set
			continue
		used[pick.id] = true
		offers.append(pick)
	# Fallback fill
	while offers.size() < count:
		offers.append(CARDS[3])  # Thick Fur
	return offers


static func _is_available(c: Dictionary) -> bool:
	if c.kind == "weapon":
		var w: String = c.weapon
		if w in GameState.owned_weapons and int(GameState.weapon_ranks.get(w, 0)) >= 5:
			return false
	return true


static func apply(card: Dictionary, player: Player) -> void:
	GameState.upgrades_taken.append(str(card.name))
	GameState.upgrades_changed.emit(GameState.upgrades_taken)
	match str(card.id):
		"WPN_TAIL", "WPN_STICK", "WPN_SAP":
			var wid: String = card.weapon
			var wm := player.weapon_manager as WeaponManager
			if wid in GameState.owned_weapons:
				wm.rank_up(wid)
			else:
				wm.unlock_weapon(wid)
		"STAT_HP":
			GameState.max_hp += 20.0
			GameState.heal(20.0)
		"STAT_SPD":
			var cap := GameState.base_move_speed * 1.6
			GameState.move_speed = minf(cap, GameState.move_speed * 1.12)
		"STAT_ARM":
			GameState.armor = minf(0.4, GameState.armor + 0.08)
		"STAT_XP":
			GameState.xp_gain *= 1.2
		"UTIL_MAG":
			GameState.pickup_radius *= 1.4
			player.refresh_pickup_radius()
		"UTIL_ATK":
			GameState.global_damage += 0.12
		"RARE_THORN":
			GameState.thorns_dps = 8.0
		"RARE_DECOY":
			GameState.decoy_enabled = true
		"RARE_OVERBITE":
			GameState.overbite_enabled = true
