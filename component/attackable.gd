class_name Attackable
extends Node3D

const ATTACKABLE_META = "attackable"

signal attacked(damage: int, knockback: Vector3)
signal invincibility_changed(invincible: bool)

@export var invincibility_time := 0.3

var _invincible_timer: Timer

func _ready() -> void:
	get_parent().set_meta(ATTACKABLE_META, self)
	_invincible_timer = Timer.new()
	_invincible_timer.one_shot = true
	_invincible_timer.wait_time = invincibility_time
	_invincible_timer.timeout.connect(invincibility_changed.emit.bind(false))
	add_child(_invincible_timer)

func hit(damage: int, knockback: Vector3) -> void:
	attacked.emit(damage, knockback)
	invincibility_changed.emit(true)
	_invincible_timer.start()


func is_invinvible() -> bool:
	return not _invincible_timer.is_stopped()
