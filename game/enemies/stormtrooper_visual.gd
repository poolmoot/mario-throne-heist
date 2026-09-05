extends Node3D

## Studio Meshy runtime pack: Idle, Walk, Run on this skeleton.
@onready var _anim: AnimationPlayer = get_node_or_null("Model/AnimationPlayer")


func _ready() -> void:
	if _anim == null:
		_anim = _find_anim(self)
	if _anim == null:
		return
	for clip in ["Idle", "Walk", "Run"]:
		if _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip("idle")


func play_clip(kind: String) -> void:
	if _anim == null:
		return
	var clip := _clip_name(kind)
	if clip == "" or not _anim.has_animation(clip):
		return
	if kind == "shoot":
		_recoil()
	if _anim.current_animation == clip and _anim.is_playing():
		return
	_anim.play(clip)


func _recoil() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:x", -8.0, 0.07)
	tween.tween_property(self, "rotation_degrees:x", 0.0, 0.12)


func _clip_name(kind: String) -> String:
	match kind:
		"idle":
			return "Idle" if _anim.has_animation("Idle") else ""
		"walk":
			if _anim.has_animation("Walk"):
				return "Walk"
			return "Run" if _anim.has_animation("Run") else ""
		"shoot":
			if _anim.has_animation("Attack"):
				return "Attack"
			if _anim.has_animation("Shoot"):
				return "Shoot"
			return "Idle" if _anim.has_animation("Idle") else ""
		_:
			return ""


func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for child in n.get_children():
		var found := _find_anim(child)
		if found:
			return found
	return null
