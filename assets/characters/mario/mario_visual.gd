extends Node3D

## Studio Meshy runtime pack: Idle, Walk, Run, Jump on this skeleton.
@onready var _anim: AnimationPlayer = $Model/AnimationPlayer

var moving := false
var move_speed := 0.0


func _ready() -> void:
	for clip in ["Idle", "Walk", "Run"]:
		var animation := _anim.get_animation(clip)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR
	_play("Idle")


func set_moving(value: bool) -> void:
	moving = value
	_play_locomotion()


func set_moving_speed(value: float) -> void:
	move_speed = clampf(value, 0.0, 1.0)
	if moving:
		_play_locomotion()


func jump() -> void:
	_play("Jump")


func fall() -> void:
	if _anim.current_animation != "Jump":
		_play("Jump")


func punch() -> void:
	pass


func _play_locomotion() -> void:
	if not moving:
		_play("Idle")
		return
	_play("Run" if move_speed > 0.55 else "Walk")


func _play(clip: String) -> void:
	if _anim.current_animation == clip and _anim.is_playing():
		return
	_anim.play(clip)
