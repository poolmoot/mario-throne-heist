extends Node3D

signal spotted(body: Node3D)


func _on_vision_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		spotted.emit(body)
