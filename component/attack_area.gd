class_name AttackArea
extends Area3D

@export var active := true
@export var damage := 1
@export var knockback := 6.0


func _physics_process(_delta: float) -> void:
	if not active:
		return
	
	for body in get_overlapping_bodies():
		if body.has_meta(Attackable.ATTACKABLE_META):
			var attackable := body.get_meta(Attackable.ATTACKABLE_META) as Attackable
			if not attackable.is_invinvible():
				var knockback_direction = global_position.direction_to(attackable.global_position)
				attackable.hit(damage, knockback_direction * knockback)
