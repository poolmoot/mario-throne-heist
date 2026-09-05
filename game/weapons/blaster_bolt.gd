extends Area3D

var velocity := Vector3.ZERO
var shooter: Node = null

const LIFE := 1.6

var _life := LIFE


func _ready() -> void:
	monitoring = false
	await get_tree().create_timer(0.05).timeout
	if not is_inside_tree():
		return
	monitoring = true
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	if velocity.length_squared() > 0.01 and is_inside_tree():
		look_at(global_position + velocity, Vector3.UP)
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	if body.is_in_group("troopers"):
		return
	if body.has_method("kill") and body.is_in_group("damageables"):
		body.kill()
		queue_free()
		return
	if body is StaticBody3D:
		queue_free()
