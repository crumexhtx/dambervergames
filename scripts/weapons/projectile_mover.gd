extends Area2D
## Simple projectile mover used by Stick Throw.

var velocity: Vector2 = Vector2.ZERO
var life: float = 1.0
var damage_amount: float = 10.0
var source: Node2D


func setup(vel: Vector2, lifetime: float, dmg: float, src: Node2D) -> void:
	velocity = vel
	life = lifetime
	damage_amount = dmg
	source = src
	body_entered.connect(_on_body)
	monitoring = true
	monitorable = false


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var from := source.global_position if source else global_position
		body.take_damage(damage_amount, from)
		queue_free()
