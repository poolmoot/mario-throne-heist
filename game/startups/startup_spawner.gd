extends Node3D

const CELL := 2.0
const GRID := 19
const BLOCK := 3
const WORLD_SCALE := 4.0
const PICKUP_SCENE := preload("res://game/startups/startup_pickup.tscn")
const Catalog := preload("res://game/startups/startup_catalog.gd")


func _ready() -> void:
	_spawn_all()


func _spawn_all() -> void:
	var entries: Array = Catalog.load_entries()
	var slots: Array[Vector3] = _pickup_slots()
	var count: int = mini(entries.size(), slots.size())
	for i in count:
		var pickup := PICKUP_SCENE.instantiate() as Area3D
		pickup.position = slots[i]
		add_child(pickup)
		if pickup.has_method("setup"):
			pickup.setup(entries[i])


func _pickup_slots() -> Array[Vector3]:
	var walkable: Array[Vector3] = []
	for z in GRID:
		for x in GRID:
			var cell := Vector2i(x, z)
			if not _is_walkable(cell):
				continue
			if _is_reserved(cell):
				continue
			walkable.append(_world_pos(cell))
	var slots: Array[Vector3] = []
	if walkable.is_empty():
		return slots
	var step := maxi(1, int(walkable.size() / 20.0))
	var i := 0
	while slots.size() < 20 and i < walkable.size():
		slots.append(walkable[i])
		i += step
	return slots


func _is_reserved(cell: Vector2i) -> bool:
	if cell.x == 0 and cell.y <= 2:
		return true
	if cell.x >= 10 and cell.x <= 11 and cell.y >= 10 and cell.y <= 11:
		return true
	if cell.x >= 17 and cell.y >= 17:
		return true
	return false


func _is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID or cell.y >= GRID:
		return false
	var origin := Vector2i(10, 10)
	if cell.x >= origin.x and cell.x <= origin.x + 1 and cell.y >= origin.y and cell.y <= origin.y + 1:
		return true
	return cell.x % BLOCK == 0 or cell.y % BLOCK == 0


func _world_pos(cell: Vector2i) -> Vector3:
	var center := (GRID - 1) * 0.5
	return Vector3((cell.x - center) * CELL, 0.0, (cell.y - center) * CELL) * WORLD_SCALE
