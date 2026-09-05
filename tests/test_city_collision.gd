extends SceneTree


func _initialize() -> void:
	var packed := load("res://assets/environment/kaykit/kaykit_city.tscn") as PackedScene
	var city := packed.instantiate() as Node3D
	root.add_child(city)
	await physics_frame
	await physics_frame

	var collision := city.get_node("Collision") as Node3D
	if collision == null:
		push_error("city is missing Collision")
		quit(1)
		return

	for body in collision.get_children():
		if not body is StaticBody3D:
			continue
		var scale := (body as Node3D).global_transform.basis.get_scale()
		if abs(scale.x - 1.0) > 0.05 or abs(scale.y - 1.0) > 0.05 or abs(scale.z - 1.0) > 0.05:
			push_error("physics body is scaled %s — Godot will let the player clip through" % scale)
			quit(1)
			return

	var car := _first_named(city, "car_")
	if car == null:
		push_error("city has no car props to collide with")
		quit(1)
		return

	var hits := _hits_at(city, car.global_position + Vector3(0, 0.8, 0), 0.35)
	if hits.is_empty():
		push_error("player can walk through parked cars")
		quit(1)
		return

	if not _ray_hits(city, Vector3(-72, 2, 0), Vector3(-90, 2, 0)):
		push_error("west map edge is open — expected a building wall")
		quit(1)
		return
	if not _ray_hits(city, Vector3(72, 2, 0), Vector3(90, 2, 0)):
		push_error("east map edge is open — expected a building wall")
		quit(1)
		return
	if not _ray_hits(city, Vector3(0, 2, -72), Vector3(0, 2, -90)):
		push_error("north map edge is open — expected a building wall")
		quit(1)
		return
	if not _ray_hits(city, Vector3(0, 2, 72), Vector3(0, 2, 90)):
		push_error("south map edge is open — expected a building wall")
		quit(1)
		return

	print("PASS: city collision is unscaled and blocks cars and map edges")
	quit()


func _first_named(root_node: Node, prefix: String) -> Node3D:
	for child in root_node.get_children():
		if child is Node3D and str(child.name).begins_with(prefix):
			return child
		var nested := _first_named(child, prefix)
		if nested:
			return nested
	return null


func _hits_at(city: Node3D, pos: Vector3, radius: float) -> Array:
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = Transform3D(Basis(), pos)
	params.collision_mask = 1
	return city.get_world_3d().direct_space_state.intersect_shape(params, 8)


func _ray_hits(city: Node3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	return not city.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
