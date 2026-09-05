extends SceneTree

const Catalog := preload("res://game/startups/startup_catalog.gd")


func _initialize() -> void:
	var entries: Array = Catalog.load_entries()
	if entries.size() != 20:
		push_error("catalog should list 20 Danish startups, got %s" % entries.size())
		quit(1)
		return

	var lunar: Dictionary = {}
	for entry in entries:
		if str(entry.get("id", "")) == "lunar":
			lunar = entry
			break
	if lunar.is_empty() or int(lunar.get("valuation", 0)) <= 0:
		push_error("catalog must include Lunar with a valuation")
		quit(1)
		return

	var pickup_packed := load("res://game/startups/startup_pickup.tscn") as PackedScene
	if pickup_packed == null:
		push_error("missing startup pickup scene")
		quit(1)
		return
	var pickup := pickup_packed.instantiate() as Area3D
	root.add_child(pickup)
	pickup.setup(lunar)
	await process_frame
	await process_frame
	if pickup.position.y < 0.2:
		push_error("startup pickup should float above the floor")
		quit(1)
		return

	var audio := pickup.get_node_or_null("CollectAudio") as AudioStreamPlayer3D
	if audio == null or audio.stream == null:
		push_error("startup pickup must have a Mario voice CollectAudio stream")
		quit(1)
		return
	if not str(audio.stream.resource_path).contains("mario_collect"):
		push_error("collect sound should be the Mario voice clip, got %s" % audio.stream.resource_path)
		quit(1)
		return

	var player := CharacterBody3D.new()
	player.name = "Player"
	root.add_child(player)
	pickup._on_body_entered(player)
	await process_frame
	if not is_instance_valid(audio) or not audio.playing:
		push_error("collecting a startup should play the Mario voice")
		quit(1)
		return
	if pickup.is_queued_for_deletion():
		push_error("pickup must wait for Mario voice to finish before freeing")
		quit(1)
		return
	if pickup.visible:
		push_error("collected startup should hide while the Mario voice plays")
		quit(1)
		return

	var scene_packed := load("res://game/first_build.tscn") as PackedScene
	var scene := scene_packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var startups := scene.get_node_or_null("Startups")
	if startups == null or startups.get_child_count() < 18:
		push_error("first_build should spawn about 20 startups, got %s" % (0 if startups == null else startups.get_child_count()))
		quit(1)
		return

	var exit := scene.get_node("Mission/ExitZone") as Node3D
	var exit_xz := Vector3(72, exit.global_position.y, 72)
	if exit.global_position.distance_to(exit_xz) > 8.0:
		push_error("exit should be on the SE corner, got %s" % exit.global_position)
		quit(1)
		return

	print("PASS: startups catalog, pickups, Mario voice, and SE exit")
	quit()
