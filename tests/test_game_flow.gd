extends SceneTree

const GameFlowScript := preload("res://game/mission/game_flow.gd")


func _initialize() -> void:
	var flow = GameFlowScript.new()
	if flow.state != GameFlowScript.State.BRIEFING:
		push_error("must start in briefing")
		quit(1)
		return

	flow.crossed_start_gate()
	if flow.state != GameFlowScript.State.INFILTRATION:
		push_error("gate should start infiltration")
		quit(1)
		return
	flow.crossed_start_gate()
	if flow.state != GameFlowScript.State.INFILTRATION:
		push_error("duplicate gate must be ignored")
		quit(1)
		return

	flow.reached_exit()
	if flow.state != GameFlowScript.State.INFILTRATION:
		push_error("exit before claim must be ignored")
		quit(1)
		return

	flow.stepped_on_throne()
	if flow.state != GameFlowScript.State.ESCAPE:
		push_error("throne should start escape")
		quit(1)
		return
	flow.stepped_on_throne()
	if flow.state != GameFlowScript.State.ESCAPE:
		push_error("duplicate throne must be ignored")
		quit(1)
		return

	flow.reached_exit()
	if flow.state != GameFlowScript.State.SUCCESS:
		push_error("exit after claim should succeed")
		quit(1)
		return

	var timeout_flow = GameFlowScript.new()
	timeout_flow.crossed_start_gate()
	timeout_flow.process_time(120.0)
	if timeout_flow.state != GameFlowScript.State.FAIL:
		push_error("120s without claim must fail")
		quit(1)
		return
	timeout_flow.process_time(1.0)
	if timeout_flow.state != GameFlowScript.State.FAIL:
		push_error("fail must stay failed")
		quit(1)
		return

	var briefing_death = GameFlowScript.new()
	briefing_death.player_died()
	if briefing_death.state != GameFlowScript.State.BRIEFING:
		push_error("death during briefing must be ignored")
		quit(1)
		return
	briefing_death.crossed_start_gate()
	briefing_death.player_died()
	if briefing_death.state != GameFlowScript.State.FAIL:
		push_error("blaster death during infiltration must fail")
		quit(1)
		return
	if briefing_death.fail_reason != "killed":
		push_error("blaster death fail_reason must be killed")
		quit(1)
		return

	print("PASS: game flow")
	quit()
