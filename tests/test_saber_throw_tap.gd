extends SceneTree


func _initialize() -> void:
	var packed := load("res://player/player.tscn") as PackedScene
	var player := packed.instantiate() as CharacterBody3D
	root.add_child(player)
	await process_frame
	await process_frame

	# A tap is down+up before physics runs — the key is not still held.
	Input.action_press("attack")
	Input.action_release("attack")
	await physics_frame
	await physics_frame

	var saber: Node = null
	for child in player.get_parent().get_children():
		if child != player and child is Area3D and String(child.name).begins_with("Lightsaber"):
			saber = child
			break
	if saber == null:
		push_error("a tap of attack should throw the saber without holding the input")
		quit(1)
		return

	print("PASS: saber throws on a tap, not a hold")
	quit()
