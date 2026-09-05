extends Area3D

const SPEED := 22.0
const LIFE := 1.4

var _velocity := Vector3.ZERO
var _life := LIFE


func throw(direction: Vector3) -> void:
	var dir := direction.normalized()
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD
	_velocity = dir * SPEED
	if is_inside_tree() and absf(dir.dot(Vector3.UP)) < 0.98:
		look_at(global_position + dir, Vector3.UP)


func _ready() -> void:
	_ignite_blade()


func _ignite_blade() -> void:
	var blade := StandardMaterial3D.new()
	blade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blade.albedo_color = Color(0.72, 0.94, 1.0)
	blade.emission_enabled = true
	blade.emission = Color(0.18, 0.62, 1.0)
	blade.emission_energy_multiplier = 16.0
	blade.disable_receive_shadows = true
	var meshes: Array[MeshInstance3D] = []
	var visual := get_node_or_null("Visual")
	if visual is MeshInstance3D:
		meshes.append(visual)
	for child in find_children("*", "MeshInstance3D", true, false):
		meshes.append(child as MeshInstance3D)
	for mi in meshes:
		if mi.mesh == null:
			continue
		var applied := false
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var albedo := Color.BLACK
			if src is StandardMaterial3D:
				albedo = (src as StandardMaterial3D).albedo_color
			elif src is BaseMaterial3D:
				albedo = (src as BaseMaterial3D).albedo_color
			# Blue blade surface (mat5) — leave the dark hilt and red button.
			if albedo.b > 0.5 and albedo.b > albedo.r + 0.2:
				mi.set_surface_override_material(s, blade)
				applied = true
		if not applied and mi.mesh.get_surface_count() > 1:
			mi.set_surface_override_material(1, blade)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("damageables"):
		return
	var squad: Node = null
	if body.is_in_group("troopers"):
		squad = body
	elif body.get_parent() and body.get_parent().is_in_group("troopers"):
		squad = body.get_parent()
	if squad:
		squad.queue_free()
		queue_free()
		return
	if body is StaticBody3D:
		queue_free()
