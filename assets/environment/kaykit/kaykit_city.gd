extends Node3D

## KayKit City Builder Bits (CC0, Kay Lousberg).
## Native tiles are 2×2 m. This node is scaled 4× so Mario fits the streets.
## Mesh defaults at yaw 0 (Godot: N=−Z, E=+X, S=+Z, W=−X):
##   road_straight → N+S
##   road_corner → E+S
##   road_tsplit → N+E+S (missing W)
##   building facade → west
const CELL := 2.0
const GRID := 19
const BLOCK := 3
const PIECE_PATH := "res://assets/environment/kaykit/%s.gltf"
const N := 1
const E := 2
const S := 4
const W := 8

const BUILDINGS := [
	"building_A", "building_B", "building_C", "building_D",
	"building_E", "building_F", "building_G", "building_H",
]
const BUILDING_HEIGHTS := {
	"building_A": 1.65,
	"building_B": 2.1,
	"building_C": 2.2,
	"building_D": 2.4,
	"building_E": 2.6,
	"building_F": 2.7,
	"building_G": 2.98,
	"building_H": 3.05,
}
const BUILDING_YAW_OFFSET := {
	"building_A": 0.0,
	"building_B": 270.0,
	"building_C": 0.0,
	"building_D": 90.0,
	"building_E": 270.0,
	"building_F": 180.0,
	"building_G": 180.0,
	"building_H": 180.0,
}
const CARS := ["car_taxi", "car_police", "car_sedan", "car_hatchback", "car_stationwagon"]
const BILLBOARD_LOGOS := ["summer_engine", "antler"]
const BILLBOARD_PATH := "res://assets/environment/kaykit/logos/%s.png"
const BILLBOARD_WORLD_WIDTH := 3.5
const BILLBOARD_Y := 0.9
const BILLBOARD_OUTSET := 1.04

const WORLD_SCALE := 4.0

@onready var _tiles: Node3D = $Visuals/Tiles
@onready var _props: Node3D = $Visuals/Props
@onready var _collision: Node3D = $Collision

var _building_i := 0
var _car_i := 0


func _ready() -> void:
	_build()


func _build() -> void:
	_clear(_tiles)
	_clear(_props)
	_clear(_collision)
	_add_ground()
	for z in GRID:
		for x in GRID:
			_place_cell(Vector2i(x, z))
	_add_perimeter_buildings()
	_add_plaza_props()


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID and cell.y < GRID


func _plaza_origin() -> Vector2i:
	var junction := int(float(GRID) / float(BLOCK * 2)) * BLOCK
	return Vector2i(junction + 1, junction + 1)


func _is_plaza(cell: Vector2i) -> bool:
	var origin := _plaza_origin()
	return cell.x >= origin.x and cell.x <= origin.x + 1 and cell.y >= origin.y and cell.y <= origin.y + 1


func _is_road(cell: Vector2i) -> bool:
	if not _in_bounds(cell):
		return false
	if _is_plaza(cell):
		return false
	return cell.x % BLOCK == 0 or cell.y % BLOCK == 0


func _is_walkable(cell: Vector2i) -> bool:
	return _is_road(cell) or _is_plaza(cell)


func _cell_to_local(cell: Vector2i) -> Vector3:
	var center := (GRID - 1) * 0.5
	return Vector3((cell.x - center) * CELL, 0.0, (cell.y - center) * CELL)


func _spawn(parent: Node3D, piece: String, cell: Vector2i, yaw_degrees: float = 0.0, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var packed := load(PIECE_PATH % piece) as PackedScene
	var node := packed.instantiate() as Node3D
	node.name = "%s_%d_%d" % [piece, cell.x, cell.y]
	node.position = _cell_to_local(cell) + offset
	node.rotation_degrees.y = yaw_degrees
	parent.add_child(node)
	return node


func _add_ground() -> void:
	var span := (GRID + 2) * CELL * WORLD_SCALE
	_add_box_collision(Vector3.ZERO, Vector3(span, 0.8, span), 0.0, -0.4)


func _add_box_collision(world_pos: Vector3, world_size: Vector3, yaw_degrees: float = 0.0, y_center: float = -INF) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = world_pos
	body.rotation_degrees.y = yaw_degrees
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = world_size
	shape.shape = box
	shape.position.y = world_size.y * 0.5 if y_center == -INF else y_center
	body.add_child(shape)
	_collision.add_child(body)


func _world_pos(cell: Vector2i, offset: Vector3 = Vector3.ZERO) -> Vector3:
	return (_cell_to_local(cell) + offset) * WORLD_SCALE


func _place_cell(cell: Vector2i) -> void:
	if _is_plaza(cell):
		_spawn(_tiles, "base", cell)
		return
	if _is_road(cell):
		_place_road(cell)
		return
	_place_building(cell)


func _road_mask(cell: Vector2i) -> int:
	var mask := 0
	if _is_walkable(cell + Vector2i(0, -1)):
		mask |= N
	if _is_walkable(cell + Vector2i(1, 0)):
		mask |= E
	if _is_walkable(cell + Vector2i(0, 1)):
		mask |= S
	if _is_walkable(cell + Vector2i(-1, 0)):
		mask |= W
	return mask


func _road_piece_and_yaw(mask: int, cell: Vector2i) -> Array:
	match mask:
		N | S, N, S:
			var ns_piece := "road_straight"
			if mask == (N | S) and cell.y % BLOCK == 2:
				ns_piece = "road_straight_crossing"
			return [ns_piece, 0.0]
		E | W, E, W:
			var ew_piece := "road_straight"
			if mask == (E | W) and cell.x % BLOCK == 2:
				ew_piece = "road_straight_crossing"
			return [ew_piece, 90.0]
		E | S:
			return ["road_corner", 0.0]
		N | E:
			return ["road_corner", 90.0]
		N | W:
			return ["road_corner", 180.0]
		S | W:
			return ["road_corner", 270.0]
		N | E | S:
			return ["road_tsplit", 0.0]
		N | E | W:
			return ["road_tsplit", 90.0]
		N | S | W:
			return ["road_tsplit", 180.0]
		E | S | W:
			return ["road_tsplit", 270.0]
		N | E | S | W:
			return ["road_junction", 0.0]
		_:
			var yaw := 90.0 if mask & (E | W) else 0.0
			return ["road_straight", yaw]


func _place_road(cell: Vector2i) -> void:
	var mask := _road_mask(cell)
	var piece_yaw: Array = _road_piece_and_yaw(mask, cell)
	_spawn(_tiles, piece_yaw[0], cell, piece_yaw[1])
	_maybe_add_road_prop(cell, mask)


func _place_building(cell: Vector2i) -> void:
	var piece: String = BUILDINGS[_building_i % BUILDINGS.size()]
	_building_i += 1
	_add_building(piece, cell, _building_yaw(cell, piece))


func _building_yaw(cell: Vector2i, piece: String) -> float:
	# Offsets first rotate each mesh so its facade points west, then this
	# yaw turns that facade toward the nearest road.
	var dir := _nearest_walkable_dir(cell)
	var face_road := _dir_to_face_yaw(dir)
	return wrapf(face_road + float(BUILDING_YAW_OFFSET.get(piece, 0.0)), 0.0, 360.0)


func _nearest_walkable_dir(cell: Vector2i) -> Vector2i:
	var best_dir := Vector2i(1, 0)
	var best_score := INF
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			if dx == 0 and dz == 0:
				continue
			var other := cell + Vector2i(dx, dz)
			if not _is_walkable(other):
				continue
			var score := float(dx * dx + dz * dz) * 10.0
			if dx != 0 and dz != 0:
				score += 1.0
			if dx == 0:
				score += 0.5
			if score < best_score:
				best_score = score
				best_dir = Vector2i(dx, dz)
	return best_dir


func _dir_to_face_yaw(dir: Vector2i) -> float:
	if abs(dir.x) >= abs(dir.y):
		return 180.0 if dir.x > 0 else 0.0
	return 270.0 if dir.y > 0 else 90.0


func _add_perimeter_buildings() -> void:
	const WALL := ["building_E", "building_F", "building_G", "building_H"]
	var wall_i := 0
	for z in range(-1, GRID + 1):
		for x in range(-1, GRID + 1):
			if x >= 0 and x < GRID and z >= 0 and z < GRID:
				continue
			var piece: String = WALL[wall_i % WALL.size()]
			wall_i += 1
			var cell := Vector2i(x, z)
			_add_building(piece, cell, _building_yaw(cell, piece))


func _add_building(piece: String, cell: Vector2i, yaw_degrees: float) -> void:
	var building := _spawn(_tiles, piece, cell, yaw_degrees)
	var height: float = BUILDING_HEIGHTS.get(piece, 2.5)
	_add_box_collision(_world_pos(cell), Vector3(1.95, height, 1.95) * WORLD_SCALE)
	_maybe_add_billboard(building, piece, cell)


func _maybe_add_billboard(building: Node3D, piece: String, cell: Vector2i) -> void:
	if (cell.x + cell.y) % 5 != 0:
		return
	var logo: String = BILLBOARD_LOGOS[absi(cell.x + cell.y) % BILLBOARD_LOGOS.size()]
	_add_billboard(building, piece, logo)


func _add_billboard(building: Node3D, piece: String, logo: String) -> void:
	var texture := load(BILLBOARD_PATH % logo) as Texture2D
	if texture == null:
		push_error("Missing billboard logo %s" % logo)
		return
	var local_width := BILLBOARD_WORLD_WIDTH / WORLD_SCALE
	var aspect := float(texture.get_width()) / maxf(float(texture.get_height()), 1.0)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(local_width, local_width / aspect)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var board := MeshInstance3D.new()
	board.name = "billboard_%s" % logo
	board.mesh = mesh
	board.material_override = material
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var yaw_offset := float(BUILDING_YAW_OFFSET.get(piece, 0.0))
	board.position = Vector3(-BILLBOARD_OUTSET, BILLBOARD_Y, 0.0).rotated(Vector3.UP, deg_to_rad(-yaw_offset))
	board.rotation_degrees.y = -90.0 - yaw_offset
	building.add_child(board)


func _connection_count(mask: int) -> int:
	var n := 0
	if mask & N:
		n += 1
	if mask & E:
		n += 1
	if mask & S:
		n += 1
	if mask & W:
		n += 1
	return n


func _maybe_add_road_prop(cell: Vector2i, mask: int) -> void:
	var bits := _connection_count(mask)
	if bits == 4 and (cell.x + cell.y) % 6 == 0:
		var light_off := Vector3(0.7, 0.0, 0.7)
		_spawn(_props, "trafficlight_A", cell, 0.0, light_off)
		_add_box_collision(_world_pos(cell, light_off), Vector3(0.3, 1.4, 0.3) * WORLD_SCALE)
		return
	if bits == 2 and (cell.x + cell.y) % 4 == 0:
		var ns := mask == (N | S)
		var car: String = CARS[_car_i % CARS.size()]
		_car_i += 1
		var yaw := 0.0 if ns else 90.0
		var car_off := Vector3(0.35, 0.1, 0.0) if ns else Vector3(0.0, 0.1, 0.35)
		_spawn(_props, car, cell, yaw, car_off)
		_add_box_collision(_world_pos(cell, car_off), Vector3(0.55, 0.42, 1.1) * WORLD_SCALE, yaw)
	if bits == 2 and cell.x % 3 == 0 and cell.y % 2 == 1:
		var lamp_off := Vector3(-0.75, 0.0, 0.0)
		_spawn(_props, "streetlight", cell, 0.0, lamp_off)
		_add_box_collision(_world_pos(cell, lamp_off), Vector3(0.2, 1.6, 0.2) * WORLD_SCALE)
	if bits == 2 and cell.y % 3 == 0 and cell.x % 2 == 1:
		var lamp_off_ew := Vector3(0.0, 0.0, -0.75)
		_spawn(_props, "streetlight", cell, 90.0, lamp_off_ew)
		_add_box_collision(_world_pos(cell, lamp_off_ew), Vector3(0.2, 1.6, 0.2) * WORLD_SCALE, 90.0)


func _add_plaza_props() -> void:
	var origin := _plaza_origin()
	_spawn_blocking("bench", origin, 90.0, Vector3(-0.4, 0.1, 0.0), Vector3(0.75, 0.35, 0.28))
	_spawn_blocking("bench", origin + Vector2i(1, 0), 270.0, Vector3(0.4, 0.1, 0.0), Vector3(0.75, 0.35, 0.28))
	_spawn_blocking("watertower", origin + Vector2i(0, 1), 0.0, Vector3(0.0, 0.1, 0.2), Vector3(0.8, 2.4, 0.8))
	_spawn_blocking("bush", origin + Vector2i(1, 1), 0.0, Vector3(-0.3, 0.1, -0.2), Vector3(0.45, 0.5, 0.45))
	_spawn_blocking("bush", origin + Vector2i(1, 1), 25.0, Vector3(0.35, 0.1, 0.25), Vector3(0.45, 0.5, 0.45))
	_spawn_blocking("firehydrant", origin + Vector2i(0, -1), 0.0, Vector3(0.0, 0.1, 0.7), Vector3(0.18, 0.45, 0.18))


func _spawn_blocking(piece: String, cell: Vector2i, yaw_degrees: float, offset: Vector3, local_size: Vector3) -> void:
	_spawn(_props, piece, cell, yaw_degrees, offset)
	_add_box_collision(_world_pos(cell, offset), local_size * WORLD_SCALE, yaw_degrees)
