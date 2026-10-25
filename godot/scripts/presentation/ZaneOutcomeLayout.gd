## Pure screen-space placement for the at-most-three admitted outcome labels.
## Rectangles include font outline; reserve the whole existing upward float.
extends RefCounted

const GAP := 8.0

static func place(preferred: Array[Rect2], safe: Rect2, obstacles: Array[Rect2], rise: float) -> Array[Rect2]:
	var result: Array[Rect2] = []
	result.resize(preferred.size())
	var order: Array[int] = []
	for i in preferred.size(): order.append(i)
	order.sort_custom(func(a: int,b: int) -> bool:
		var left := preferred[a].get_center()
		var right := preferred[b].get_center()
		return left.x < right.x if not is_equal_approx(left.x,right.x) else left.y < right.y
	)
	var blocked: Array[Rect2] = []
	for obstacle in obstacles: blocked.append(obstacle.grow(GAP))
	for i in order:
		var desired := preferred[i]
		var xs: Array[float] = [desired.position.x,safe.position.x,safe.end.x-desired.size.x]
		var ys: Array[float] = [desired.position.y,safe.position.y+rise,safe.end.y-desired.size.y]
		for rect in blocked:
			xs.append(rect.position.x-desired.size.x)
			xs.append(rect.end.x)
			ys.append(rect.position.y-desired.size.y)
			ys.append(rect.end.y+rise)
		var best := Rect2(_clamp_position(desired.position,desired.size,safe,rise),desired.size)
		var distance := INF
		for x in xs:
			for y in ys:
				var candidate := Rect2(_clamp_position(Vector2(x,y),desired.size,safe,rise),desired.size)
				var swept := candidate.merge(Rect2(candidate.position+Vector2(0,-rise),candidate.size))
				if not safe.encloses(swept): continue
				var clear := true
				for rect in blocked:
					if swept.intersects(rect):
						clear = false
						break
				# Favor up/side displacement over dropping a callout onto its unit header.
				var delta := candidate.position-desired.position
				var cost := delta.x*delta.x+delta.y*delta.y*(4.0 if delta.y > 0 else 1.0)
				if clear and cost < distance:
					best = candidate
					distance = cost
		result[i] = best
		blocked.append(best.merge(Rect2(best.position+Vector2(0,-rise),best.size)).grow(GAP))
	return result

static func _clamp_position(point: Vector2, label_extent: Vector2, safe: Rect2, rise: float) -> Vector2:
	return Vector2(clampf(point.x,safe.position.x,safe.end.x-label_extent.x),clampf(point.y,safe.position.y+rise,safe.end.y-label_extent.y))
