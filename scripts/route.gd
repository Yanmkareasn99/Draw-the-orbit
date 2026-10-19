extends RefCounted
## Pure route geometry, shared by the game and automated checks.
const MIN_BARRIER_LENGTH := 24.0

static func planet_is_enclosed(paths: Array[PackedVector2Array], center: Vector2) -> bool:
	# Only a connected cycle around the planet seals it in. Angular coverage
	# alone would reject staggered open walls, even though gaps still exist.
	# Use drawn centerlines, without adding UFO clearance or a minimum gap.
	var segments: Array[PackedVector2Array] = []
	var bounds: Array[Rect2] = []
	var graph: Array[Array] = []
	for points in paths:
		for i in range(1, points.size()):
			var a := points[i - 1] - center
			var b := points[i] - center
			segments.append(PackedVector2Array([a, b]))
			bounds.append(Rect2(a, Vector2.ZERO).expand(b).grow(0.0001))
			graph.append([])
	for i in range(segments.size()):
		for j in range(i + 1, segments.size()):
			if not bounds[i].intersects(bounds[j]):
				continue
			var a := segments[i][0]
			var b := segments[i][1]
			var c := segments[j][0]
			var d := segments[j][1]
			var contact = Geometry2D.segment_intersects_segment(a, b, c, d)
			# Collinear segments also connect when they touch or overlap.
			if contact == null:
				for p in [a, b]:
					if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p, c, d)) <= 0.00000001:
						contact = p
				for p in [c, d]:
					if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= 0.00000001:
						contact = p
			if contact == null:
				continue
			var delta := angle_difference(a.angle(), contact.angle()) - angle_difference(c.angle(), contact.angle())
			graph[i].append(Vector2(j, delta))
			graph[j].append(Vector2(i, -delta))
	var angles: Array[float] = []
	angles.resize(segments.size())
	angles.fill(INF)
	for start in range(segments.size()):
		if angles[start] != INF:
			continue
		angles[start] = 0.0
		var pending: Array[int] = [start]
		while not pending.is_empty():
			var current: int = pending.pop_back()
			for edge: Vector2 in graph[current]:
				var next := int(edge.x)
				var angle := angles[current] + edge.y
				if angles[next] == INF:
					angles[next] = angle
					pending.append(next)
				elif absf(angles[next] - angle) > PI:
					# Returning to a segment after a full turn encloses the planet.
					return true
	return false

static func length_of(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

static func nearest(points: PackedVector2Array, point: Vector2) -> Dictionary:
	var best := INF
	var result := {"point": point, "distance": 0.0, "normal": Vector2.UP}
	var walked := 0.0
	for i in range(1, points.size()):
		var candidate := Geometry2D.get_closest_point_to_segment(point, points[i - 1], points[i])
		var gap := candidate.distance_squared_to(point)
		if gap < best:
			best = gap
			result = {"point": candidate, "distance": walked + points[i - 1].distance_to(candidate), "normal": (points[i] - points[i - 1]).orthogonal().normalized()}
		walked += points[i - 1].distance_to(points[i])
	return result

static func at_distance(points: PackedVector2Array, distance: float) -> Vector2:
	var left := fposmod(distance, maxf(length_of(points), 0.001))
	for i in range(1, points.size()):
		var segment := points[i - 1].distance_to(points[i])
		if left <= segment and segment > 0.0:
			return points[i - 1].lerp(points[i], left / segment)
		left -= segment
	return points[0]

static func validate(points: PackedVector2Array, center: Vector2, exclusion: float, budget: float) -> String:
	if points.size() < 4 or length_of(points) < 110.0:
		return "Draw a larger loop"
	return validate_barrier(points, center, exclusion, budget)

static func validate_barrier(points: PackedVector2Array, center: Vector2, exclusion: float, budget: float) -> String:
	if points.size() < 2 or length_of(points) < MIN_BARRIER_LENGTH:
		return "Draw a longer barrier"
	if length_of(points) > budget:
		return "Barrier is too long"
	for i in range(points.size() - 1):
		if points[i].distance_to(points[i + 1]) < 0.1:
			return "Avoid overlapping points"
		if Geometry2D.get_closest_point_to_segment(center, points[i], points[i + 1]).distance_to(center) < exclusion:
			return "Keep outside the planet ring"
		for j in range(i + 2, points.size() - 1):
			if i == 0 and j == points.size() - 2 and points[0].is_equal_approx(points[-1]):
				continue
			if Geometry2D.segment_intersects_segment(points[i], points[i + 1], points[j], points[j + 1]) != null:
				return "Your barrier crosses itself"
	return ""
