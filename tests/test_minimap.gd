extends SceneTree

const MinimapScript := preload("res://game/mission/minimap.gd")
const MAP := Vector2(132, 132)
const NORTH := Vector3(0, 0, -1)
const SPAWN := Vector3(-72, 0.55, -64)


func _initialize() -> void:
	var packed := load("res://game/mission/mission_hud.tscn") as PackedScene
	var hud := packed.instantiate()
	root.add_child(hud)
	await process_frame

	var minimap := hud.get_node_or_null("Root/Minimap") as Control
	if minimap == null:
		push_error("HUD must have a Minimap in the bottom-left")
		quit(1)
		return

	if minimap.anchor_top < 0.99 or minimap.anchor_bottom < 0.99:
		push_error("minimap must be anchored to the bottom")
		quit(1)
		return
	if minimap.anchor_left > 0.01 or minimap.anchor_right > 0.01:
		push_error("minimap must be anchored to the left")
		quit(1)
		return

	var size := minimap.size
	if abs(size.x - size.y) > 1.0:
		push_error("minimap must be a square so it can draw as a circle, got %s" % size)
		quit(1)
		return
	if minimap.clip_children == Control.CLIP_CHILDREN_DISABLED:
		push_error("minimap must clip children to a circle like GTA")
		quit(1)
		return

	var center := MAP * 0.5
	var at_player := MinimapScript.world_to_map(SPAWN, MAP, SPAWN, NORTH)
	if at_player.distance_to(center) > 1.0:
		push_error("GTA radar keeps the player at the circle center, got %s" % at_player)
		quit(1)
		return

	var ahead := MinimapScript.world_to_map(SPAWN + Vector3(0, 0, -12), MAP, SPAWN, NORTH)
	if ahead.y >= at_player.y:
		push_error("heading-up radar should draw forward toward the top, got %s" % ahead)
		quit(1)
		return

	var right := MinimapScript.world_to_map(SPAWN + Vector3(12, 0, 0), MAP, SPAWN, NORTH)
	if right.x <= at_player.x:
		push_error("heading-up radar should draw right toward the right, got %s" % right)
		quit(1)
		return

	var looking_east := MinimapScript.world_to_map(SPAWN + Vector3(12, 0, 0), MAP, SPAWN, Vector3(1, 0, 0))
	if looking_east.y >= at_player.y:
		push_error("when facing east, east should be up on the radar, got %s" % looking_east)
		quit(1)
		return

	var far := MinimapScript.world_to_map(Vector3(400, 0, 400), MAP, SPAWN, NORTH)
	if far.distance_to(center) > MAP.x * 0.5 - 1.0:
		push_error("off-map blips should clamp to the circle rim, got %s" % far)
		quit(1)
		return

	if MinimapScript.cell_kind(Vector2i(0, 1)) != MinimapScript.KIND_ROAD:
		push_error("west street column should be a road")
		quit(1)
		return
	if MinimapScript.cell_kind(Vector2i(1, 1)) != MinimapScript.KIND_BUILDING:
		push_error("lot next to the west street should be a building")
		quit(1)
		return
	if MinimapScript.cell_kind(Vector2i(10, 10)) != MinimapScript.KIND_PLAZA:
		push_error("city center should be plaza")
		quit(1)
		return

	var city := MinimapScript.bake_city_map(128)
	var road_px := MinimapScript.city_texel(Vector3(0, 0, 0), 128)
	var building_px := MinimapScript.city_texel(Vector3(8, 0, -8), 128)
	var road_c := city.get_pixel(road_px.x, road_px.y)
	var building_c := city.get_pixel(building_px.x, building_px.y)
	if road_c.r + road_c.g + road_c.b < building_c.r + building_c.g + building_c.b:
		push_error("GTA-style roads should be lighter than buildings, road=%s building=%s" % [road_c, building_c])
		quit(1)
		return
	if road_c.is_equal_approx(building_c):
		push_error("minimap must paint roads and buildings as different colors")
		quit(1)
		return

	print("PASS: circular minimap")
	quit()
