extends RefCounted
const RELEASE_TIME := 0.28
const RECOVERY_TIME := 0.52
const END_TIME := 0.76
var direction := 'SE'
var elapsed := 0.0
var active := false
var released := false

func set_facing(value: String) -> bool:
	if active or value not in ['SE', 'SW', 'NE', 'NW']:
		return false
	direction = value
	return true

func start_cast() -> bool:
	if active or direction != 'SE':
		return false
	active = true
	elapsed = 0.0
	released = false
	return true

func cancel() -> void:
	active = false
	elapsed = 0.0
	released = false

func advance(delta: float) -> int:
	if not active:
		return 0
	elapsed += maxf(delta, 0.0)
	var events := 0
	if elapsed >= RELEASE_TIME and not released:
		released = true
		events = 1
	if elapsed >= END_TIME:
		active = false
	return events

func pose() -> String:
	if not active:
		return direction.to_lower()
	if elapsed < 0.08:
		return 'cast-lift-se'
	if elapsed < 0.20:
		return 'cast-windup-se'
	if elapsed < 0.28:
		return 'cast-extend-se'
	if elapsed < 0.52:
		return 'cast-release-se'
	if elapsed < 0.60:
		return 'cast-extend-se'
	if elapsed < 0.68:
		return 'cast-windup-se'
	return 'cast-lift-se'
