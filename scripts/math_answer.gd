class_name MathAnswer
extends RefCounted
## Reads answers such as "3", "0.75", "3/4" and "1 3/4".

const TOLERANCE := 0.000001


static func parse(text: String) -> float:
	var parts := text.strip_edges().split(" ", false)
	if parts.size() == 1:
		return _parse_part(parts[0])
	if parts.size() == 2 and parts[1].contains("/") and parts[0].is_valid_int():
		var fraction := _parse_part(parts[1])
		if is_nan(fraction) or fraction < 0.0:
			return NAN
		return float(parts[0]) + fraction
	return NAN


static func same_value(a: String, b: String) -> bool:
	var x := parse(a)
	var y := parse(b)
	if is_nan(x) or is_nan(y):
		return false
	return absf(x - y) < TOLERANCE


static func _parse_part(part: String) -> float:
	if part.contains("/"):
		var pieces := part.split("/")
		if pieces.size() != 2 or not pieces[0].is_valid_int() or not pieces[1].is_valid_int():
			return NAN
		if int(pieces[1]) == 0:
			return NAN
		return float(pieces[0]) / float(pieces[1])
	return float(part) if part.is_valid_float() else NAN
