extends SceneTree

const STATE_BRIEFING := 0
const STATE_INFILTRATION := 1
const STATE_ESCAPE := 2
const STATE_SUCCESS := 3


func _initialize() -> void:
	var packed := load("res://game/first_build.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	var troopers := scene.get_node_or_null("Troopers")
	if troopers:
		troopers.queue_free()
		await physics_frame

	var player := scene.get_node("Player") as CharacterBody3D
	var mission := scene.get_node("Mission")

	if mission.state != STATE_BRIEFING:
		push_error("spawn must stay in briefing, got %s" % mission.state)
		quit(1)
		return

	await _drive_player_to(player, Vector3(-72, 0.55, -58))
	if mission.state != STATE_INFILTRATION:
		push_error("gate should start infiltration, got %s" % mission.state)
		quit(1)
		return

	await _drive_player_to(player, Vector3(12, 0.55, 12))
	if mission.state != STATE_ESCAPE:
		push_error("throne should start escape, got %s" % mission.state)
		quit(1)
		return

	await _drive_player_to(player, Vector3(72, 0.55, 72))
	if mission.state != STATE_SUCCESS:
		push_error("exit should succeed after claim, got %s" % mission.state)
		quit(1)
		return

	print("PASS: mission loop run briefing to escape")
	quit()


func _drive_player_to(player: CharacterBody3D, dest: Vector3) -> void:
	player.global_position = dest + Vector3(0, 0, -1.5)
	player.velocity = Vector3.ZERO
	await physics_frame
	for _i in 12:
		player.velocity = Vector3(0, 0, 6)
		player.move_and_slide()
		await physics_frame
	player.global_position = dest
	player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
