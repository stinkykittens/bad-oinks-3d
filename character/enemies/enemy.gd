extends CharacterBody3D

@export var health := 1
@export var knockback_resistance := 1
@export var gravity := 1.0
@export var friction := 3.0

var attackable: Attackable


func _ready() -> void:
	if has_meta(Attackable.ATTACKABLE_META):
		attackable = get_meta(Attackable.ATTACKABLE_META)
		attackable.attacked.connect(_on_attacked)


func _physics_process(delta: float) -> void:
	velocity.x = lerpf(velocity.x, 0, friction * delta)
	velocity.z = lerpf(velocity.z, 0, friction * delta)
	velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * gravity * delta
	move_and_slide()


func die() -> void:
	queue_free()


func _on_attacked(damage: int, knockback: Vector3) -> void:
	health -= damage
	print(knockback)
	velocity += knockback / knockback_resistance
	if health <= 0:
		die()
