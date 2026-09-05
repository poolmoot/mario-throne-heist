extends SceneTree

const Detector := preload("res://game/input/light_cover_detector.gd")


func _calibrate(detector) -> void:
	for _i in 20:
		detector.sample(100.0, 0.016)


func _initialize() -> void:
	var detector = Detector.new()
	_calibrate(detector)

	detector.sample(20.0, 0.016)
	if not detector.consume_throw():
		push_error("covering the sensor should fire immediately")
		quit(1)
		return

	detector.sample(18.0, 0.016)
	detector.sample(15.0, 0.016)
	if detector.consume_throw():
		push_error("holding a hand on the sensor must not fire again")
		quit(1)
		return

	# Lift the hand, then cover again after cooldown.
	for _i in 20:
		detector.sample(100.0, 0.05)
	detector.sample(20.0, 0.016)
	if not detector.consume_throw():
		push_error("a new cover after uncovering should fire again")
		quit(1)
		return

	print("PASS: light cover fires on contact, not while held")
	quit()
