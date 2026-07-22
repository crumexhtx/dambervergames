extends CanvasLayer
class_name LevelUpUI

signal card_chosen(card: Dictionary)

@onready var panel: PanelContainer = $Panel
@onready var title: Label = $Panel/VBox/Title
@onready var cards_row: HBoxContainer = $Panel/VBox/Cards

var _offers: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_offers(offers: Array[Dictionary]) -> void:
	_offers = offers
	visible = true
	GameState.set_soft_paused(true)
	get_tree().paused = true
	for c in cards_row.get_children():
		c.queue_free()
	for card in offers:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 160)
		btn.text = "%s\n\n%s\n[%s]" % [card.name, card.desc, str(card.rarity).capitalize()]
		btn.pressed.connect(_pick.bind(card))
		cards_row.add_child(btn)
	Juice.shake(3.0, 0.1)


func _pick(card: Dictionary) -> void:
	visible = false
	get_tree().paused = false
	GameState.set_soft_paused(false)
	card_chosen.emit(card)
