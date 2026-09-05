extends SceneTree

const MissionTimerScript := preload("res://game/mission/mission_timer.gd")


func _initialize() -> void:
	var timer = MissionTimerScript.new()
	if timer.acquisition_remaining != 120.0:
		push_error("fresh timer must be 120s")
		quit(1)
		return
	timer.start_infiltration()
	timer.tick(10.0)
	if abs(timer.acquisition_remaining - 110.0) > 0.001:
		push_error("tick should consume acquisition time")
		quit(1)
		return
	timer.claim()
	if timer.is_expired():
		push_error("claimed run is not expired")
		quit(1)
		return
	timer.tick(3.5)
	if abs(timer.escape_elapsed - 3.5) > 0.001:
		push_error("escape stopwatch should run after claim")
		quit(1)
		return
	if abs(timer.acquisition_used - 10.0) > 0.001:
		push_error("acquisition_used should freeze at claim")
		quit(1)
		return
	var failer = MissionTimerScript.new()
	failer.start_infiltration()
	failer.tick(120.0)
	if not failer.is_expired():
		push_error("120s of infiltration must expire")
		quit(1)
		return
	print("PASS: mission timer")
	quit()
