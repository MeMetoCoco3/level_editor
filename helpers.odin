package main

import "core:math"

radians_from_vector :: proc(v: Vector2) -> f32 {
	return math.atan2_f32(v.y, v.x)
}

vec2_normalize :: proc(v: ^Vector2) {
	x, y: f32
	if v.x == 0 {
		x = 0
	} else {
		x = v.x / abs(v.x)
	}
	if v.y == 0 {
		y = 0
	} else {
		y = v.y / abs(v.y)
	}
	v.x = x
	v.y = y
}


angle_from_vector :: proc(v0: Vector2) -> f32 {
	return math.atan2(v0.y, v0.x) * (180.0 / math.PI)
}
