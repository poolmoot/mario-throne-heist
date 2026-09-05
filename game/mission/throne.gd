extends Area3D

@export var hover_height := 0.55
@export var hover_amp := 0.14
@export var hover_speed := 2.4
@export var spin_speed := 1.6

@onready var _crown: Node3D = $Crown

var _t := 0.0


func _ready() -> void:
	if _crown:
		_crown.position.y = hover_height


func _process(delta: float) -> void:
	if _crown == null:
		return
	_t += delta
	_crown.position.y = hover_height + sin(_t * hover_speed) * hover_amp
	_crown.rotate_y(delta * spin_speed)
