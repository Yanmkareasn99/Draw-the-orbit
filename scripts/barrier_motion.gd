extends RefCounted
## Damped elastic waves along the drawn stroke. Keep its resting collision
## geometry and ink cost stable so the player's chosen rebound angle survives.
const SETTLE_TIME := 1.6
const MAX_IMPACTS := 8
const MAX_DISPLACEMENT := 22.0

static func prepare(barrier: Dictionary) -> void:
	var samples := PackedVector2Array()
	var distances := PackedFloat32Array()
	var points: PackedVector2Array = barrier.points
	var walked := 0.0
	samples.append(points[0])
	distances.append(0.0)
	for i in range(1, points.size()):
		var length := points[i - 1].distance_to(points[i])
		var count := maxi(1, ceili(length / 8.0))
		for j in range(1, count + 1):
			var fraction := float(j) / count
			samples.append(points[i - 1].lerp(points[i], fraction))
			distances.append(walked + length * fraction)
		walked += length
	barrier.samples = samples
	barrier.sample_distances = distances
	barrier.impacts = []

static func impact(barrier: Dictionary, distance: float, direction: Vector2, speed: float, mass: float) -> void:
	if not barrier.has("impacts"):
		prepare(barrier)
	if barrier.impacts.size() >= MAX_IMPACTS:
		barrier.impacts.pop_front()
	barrier.impacts.append({"distance": distance, "direction": direction,
		"amplitude": clampf((8.0 + speed * 0.12) * mass, 8.0, MAX_DISPLACEMENT), "age": 0.0})

static func advance(barrier: Dictionary, dt: float) -> void:
	if not barrier.has("impacts"):
		return
	for i in range(barrier.impacts.size() - 1, -1, -1):
		barrier.impacts[i].age += dt
		if barrier.impacts[i].age >= SETTLE_TIME:
			barrier.impacts.remove_at(i)

static func points_for(barrier: Dictionary) -> PackedVector2Array:
	if not barrier.has("impacts") or barrier.impacts.is_empty():
		return barrier.points
	var points: PackedVector2Array = barrier.samples.duplicate()
	var length: float = barrier.length
	for i in range(1, points.size() - 1):
		var distance: float = barrier.sample_distances[i]
		# Pin both ends; the body stretches toward the incoming UFO's motion.
		var pin := smoothstep(0.0, 28.0, minf(distance, length - distance))
		var offset := Vector2.ZERO
		for hit in barrier.impacts:
			var gap := absf(distance - hit.distance)
			var phase: float = hit.age - gap / 650.0
			if phase <= 0.0:
				continue
			var envelope := exp(-gap / 110.0) * exp(-hit.age * 3.5)
			offset += hit.direction * hit.amplitude * sin(phase * 19.0) * envelope * pin
		points[i] += offset.limit_length(MAX_DISPLACEMENT)
	return points
