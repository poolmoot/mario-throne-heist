class_name LightCoverDetector
extends RefCounted

## Fires once when the sensor is covered. Holding covered does not retrigger.
## Uncovering re-arms after a short cooldown.

const CALIB_SAMPLES := 12
const COVER_RATIO := 0.45
const COOLDOWN := 0.25

var baseline := -1.0
var _calib_sum := 0.0
var _calib_n := 0
var _covered := false
var _pending := false
var _cooldown_left := 0.0


func sample(lux: float, delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _calib_n < CALIB_SAMPLES:
		_calib_sum += lux
		_calib_n += 1
		if _calib_n == CALIB_SAMPLES:
			baseline = _calib_sum / float(CALIB_SAMPLES)
		return

	var now_covered := lux < baseline * COVER_RATIO
	if now_covered and not _covered and _cooldown_left <= 0.0:
		_pending = true
		_cooldown_left = COOLDOWN
	_covered = now_covered


func consume_throw() -> bool:
	if not _pending:
		return false
	_pending = false
	return true
