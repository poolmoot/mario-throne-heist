extends SceneTree

const FACE_WEST_OFFSET := {
	"building_A": 0.0,
	"building_B": 270.0,
	"building_C": 0.0,
	"building_D": 90.0,
	"building_E": 270.0,
	"building_F": 180.0,
	"building_G": 180.0,
	"building_H": 180.0,
}


func _initialize() -> void:
	var packed := load("res://assets/environment/kaykit/kaykit_city.tscn") as PackedScene
	var city := packed.instantiate() as Node3D
	root.add_child(city)
	await process_frame
	await process_frame

	var tiles: Node3D = city.get_node("Visuals/Tiles")
	if tiles.get_child_count() != 441:
		push_error("Expected 19x19 city plus building ring (441 tiles), got %s" % tiles.get_child_count())
		quit(1)
		return

	var corner := tiles.get_node_or_null("road_corner_0_0") as Node3D
	if corner == null or abs(corner.rotation_degrees.y) > 0.01:
		push_error("NW corner should be road_corner at yaw 0")
		quit(1)
		return

	var junction := tiles.get_node_or_null("road_junction_9_9") as Node3D
	if junction == null:
		push_error("Center crossroads should be a four-way junction")
		quit(1)
		return

	if not _building_faces(tiles, 10, 7, 0.0):
		quit(1)
		return
	if not _building_faces(tiles, 8, 7, 180.0):
		quit(1)
		return

	# Perimeter wall faces the nearest inner road, not out of the world.
	if not _building_faces(tiles, -1, 9, 180.0):
		quit(1)
		return
	if not _building_faces(tiles, 19, 9, 0.0):
		quit(1)
		return
	if not _building_faces(tiles, 9, -1, 270.0):
		quit(1)
		return
	if not _building_faces(tiles, 9, 19, 90.0):
		quit(1)
		return
	if not _building_faces(tiles, -1, -1, 180.0):
		quit(1)
		return

	print("PASS: city is walled by buildings facing the nearest road")
	quit()


func _building_faces(tiles: Node3D, x: int, z: int, face_road: float) -> bool:
	var building := _find_building(tiles, x, z)
	if building == null:
		push_error("Missing building at %s,%s" % [x, z])
		return false
	var suffix := "_%d_%d" % [x, z]
	var piece := str(building.name).substr(0, str(building.name).length() - suffix.length())
	var expected := wrapf(face_road + float(FACE_WEST_OFFSET[piece]), 0.0, 360.0)
	if abs(wrapf(building.rotation_degrees.y - expected, -180.0, 180.0)) > 0.5:
		push_error("Building %s at %s,%s yaw=%s expected=%s" % [piece, x, z, building.rotation_degrees.y, expected])
		return false
	return true


func _find_building(tiles: Node3D, x: int, z: int) -> Node3D:
	var suffix := "_%d_%d" % [x, z]
	for child in tiles.get_children():
		var name := str(child.name)
		if name.begins_with("building_") and name.ends_with(suffix):
			return child
	return null
