package first_battle

import "core:slice"
import "base:intrinsics"

import "core:math"
import la "core:math/linalg"


float  :: f32
double :: f64
vec2   :: [2]f32
vec3   :: [3]f32
vec4   :: [4]f32
ivec2  :: [2]i32
ivec3  :: [3]i32
ivec4  :: [4]i32
uvec2  :: [2]u32
uvec3  :: [3]u32
uvec4  :: [4]u32
bvec2  :: [2]b32
bvec3  :: [3]b32
bvec4  :: [4]b32
mat2   :: matrix[2, 2]f32
mat3   :: matrix[3, 3]f32
mat4   :: matrix[4, 4]f32
u8vec4 :: [4]u8

ratio  :: distinct f32
rvec2  :: distinct [2]f32

Rect :: struct {
	using pos: vec2,
	size:      vec2,
}
AABB :: Rect

TAU     :: la.TAU
PI      :: la.PI
HALF_PI :: la.PI / 2

// Epsilon for floating-point comparisons in geometric operations
EPSILON :: f32(math.F32_EPSILON)

remainder  :: math.remainder
mod        :: la.mod
to_radians :: la.to_radians
to_degrees :: la.to_degrees
cos        :: la.cos
sin        :: la.sin
tan        :: la.tan
dot        :: la.dot
cross      :: la.cross
pow        :: la.pow
exp        :: la.exp
lerp       :: la.lerp
distance   :: la.distance
sqrt       :: la.sqrt
normalize  :: la.normalize
normalize0 :: la.normalize0
floor      :: la.floor
ceil       :: la.ceil
sign       :: la.sign

@require_results
cbrt :: #force_inline proc "contextless" (x: f32) -> f32 {
	return x * x * x
}

@require_results
hypot_f32_3d :: proc "contextless" (x, y, z: f32) -> f32 {
	x, y, z := abs(x), abs(y), abs(z)

	if math.is_inf(x, 1) || math.is_inf(y, 1) || math.is_inf(z, 1) {
		return math.inf_f32(1)
	}
	if math.is_nan(x) || math.is_nan(y) || math.is_nan(z) {
		return math.nan_f32()
	}

	// make p the largest
	if x < y {
		x, y = y, x
	}
	if x < z {
		x, z = z, x
	}
	if x == 0 {
		return 0
	}
	y = y / x
	z = z / x
	return x * sqrt(1 + y*y + z*z)
}

@require_results
hypot_vec3 :: proc "contextless" (v: vec3) -> f32 {
	return hypot_f32_3d(v.x, v.y, v.z)
}

hypot :: proc {
	math.hypot_f16, math.hypot_f16le, math.hypot_f16be,
	math.hypot_f32, math.hypot_f32le, math.hypot_f32be,
	math.hypot_f64, math.hypot_f64le, math.hypot_f64be,
	hypot_f32_3d, hypot_vec3,
}

to_vec3_2_1 :: #force_inline proc "contextless" (v: vec2 = 0, z: f32 = 0) -> vec3 {return {v.x, v.y, z}}
to_vec3_1_2 :: #force_inline proc "contextless" (x: f32 = 0, v: vec2 = 0) -> vec3 {return {x, v.x, v.y}}
to_vec3 :: proc {to_vec3_2_1, to_vec3_1_2}


UP    :: vec3{ 0, 1, 0}
DOWN  :: vec3{ 0,-1, 0}
LEFT  :: vec3{-1, 0, 0}
RIGHT :: vec3{ 1, 0, 0}
FRONT :: vec3{ 0, 0, 1}
BACK  :: vec3{ 0, 0,-1}

VEC2_SQUARE :: [4]vec2{
	{0, 0},
	{1, 0},
	{1, 1},
	{0, 1},
}

midpoint :: proc "contextless" (a, b: $T/[2]$S) -> T
	where intrinsics.type_is_numeric(S)
{
	return {(a.x + b.x) / 2, (a.y + b.y) / 2}
}

// cast_vec2 :: #force_inline proc "contextless" ($D: typeid, v: [2]$S) -> [2]D
// 	where intrinsics.type_is_numeric(S),
// 	      intrinsics.type_is_numeric(D) {
// 	return {D(v.x), D(v.y)}
// }
array_cast :: la.array_cast
@(require_results)
cast_vec2 :: #force_inline proc "contextless" (v: $T/[2]$S) -> vec2
	where intrinsics.type_is_numeric(S) {
	return {f32(v.x), f32(v.y)}
}
@(require_results)
cast_ivec2 :: #force_inline proc "contextless" (v: $T/[2]$S) -> ivec2
	where intrinsics.type_is_numeric(S) {
	return {i32(v.x), i32(v.y)}
}
@(require_results)
vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> vec3 {
	return {v.x, v.y, z}
}

@(require_results)
mat3_translate :: proc "contextless" (v: vec2) -> mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: vec2) -> mat3 {
	return {
		v.x, 0,   0,
		0,   v.y, 0,
		0,   0,   1,
	}
}
@(require_results)
mat3_rotate :: proc "contextless" (angle: f32) -> mat3 {
	c := cos(angle)
	s := sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}
@(require_results)
mat3_projection :: proc "contextless" (size: vec2) -> mat3 {
	return {
		2/size.x, 0,       -1,
		0,       -2/size.y, 1,
		0,        0,        1,
	}
}
@(require_results)
mat3_flip_y :: proc "contextless" () -> mat3 {
	return {
		1,  0, 0,
		0, -1, 0,
		0,  0, 1,
	}
}
@(require_results)
mat3_flip_x :: proc "contextless" () -> mat3 {
	return {
		-1, 0, 0,
		 0, 1, 0,
		 0, 0, 1,
	}
}
@(require_results)
vec2_transform :: proc "contextless" (v: vec2, m: mat3) -> vec2 {
	return {
		v.x * m[0].x + v.y * m[1].x + m[2].x,
		v.x * m[0].y + v.y * m[1].y + m[2].y,
	}
}
mat3_transform_point :: proc "contextless" (m: mat3, v: vec2) -> vec2 {
	return vec2_transform(v, m)
}

vec2_arr_transform :: proc "contextless" (pts: []vec2, m: mat3) {
	for &p in pts {
		p = vec2_transform(p, m)
	}
}
// Transform a direction vector (ignoring translation component)
@(require_results)
vec2_transform_dir :: proc "contextless" (v: vec2, m: mat3) -> vec2 {
    return {
        v.x * m[0].x + v.y * m[1].x,
        v.x * m[0].y + v.y * m[1].y,
    }
}

@(require_results)
mat4_translate :: proc "contextless" (v: vec3) -> mat4 {
	return {
		1, 0, 0, v.x,
		0, 1, 0, v.y,
		0, 0, 1, v.z,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_scale :: proc "contextless" (v: vec3) -> (m: mat4) {
	return {
		v.x, 0,   0,   0,
		0,   v.y, 0,   0,
		0,   0,   v.z, 0,
		0,   0,   0,   1,
	}
}
@(require_results)
mat4_rotate_x :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)
	return {
		1, 0, 0, 0,
		0, c, s, 0,
		0,-s, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_y :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)
	return {
		c, 0,-s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_z :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)

	return {
		c,  s, 0, 0,
		-s, c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1,
	}
}
@(require_results)
mat4_rotate_vec :: #force_inline proc "contextless" (v: vec3) -> mat4 {
	return mat4_rotate_x(v.x) * mat4_rotate_y(v.y) * mat4_rotate_z(v.z)
}

@(require_results)
mat4_flip_y :: proc "contextless" () -> mat4 {
	return {
		1,  0, 0, 0,
		0, -1, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1,
	}
}
@(require_results)
mat4_flip_x :: proc "contextless" () -> mat4 {
	return {
		-1, 0, 0, 0,
		 0, 1, 0, 0,
		 0, 0, 1, 0,
		 0, 0, 0, 1,
	}
}

@(require_results)
mat4_perspective :: proc "contextless" (fov, aspect, near, far: f32) -> mat4 {
	f     := tan(fov*0.5)
	range := 1 / (near - far)

	return {
		f/aspect, 0, 0,                    0,
		0,        f, 0,                    0,
		0,        0, (near + far) * range, near * far * range * 2,
		0,        0, -1,                   0,
	}
}
@(require_results)
mat4_look_at :: proc "contextless" (eye, target, up: vec3) -> mat4 {
	// f  := normalize(target - eye)
	// s  := normalize(cross(f, up))
	// u  := cross(s, f)
	// fe := dot(f, eye)

	// return {
	// 	+s.x, +s.y, +s.z, -dot(s, eye),
	// 	+u.x, +u.y, +u.z, -dot(u, eye),
	// 	-f.x, -f.y, -f.z, +fe,
	// 	0,    0,    0,    1,
	// }

	z := normalize(eye - target)
	x := normalize(cross(up, z))
	y := normalize(cross(z, x))

	return {
		x.x, y.x, z.x, eye.x,
		x.y, y.y, z.y, eye.y,
		x.z, y.z, z.z, eye.z,
		0,   0,   0,   1,
	}
}

// Convert 2D transformation mat3 to 3D mat4 (places translation in 4th column)
mat4_from_mat3_2d :: #force_inline proc "contextless" (m: mat3) -> mat4 {
	return {
		m[0].x, m[1].x, 0, m[2].x,  // rotation/scale + translation x
		m[0].y, m[1].y, 0, m[2].y,  // rotation/scale + translation y
		0,      0,      1, 0,       // z axis (unused in 2D)
		0,      0,      0, 1,       // homogeneous coordinate
	}
}

// Rotates a vector around an axis
@(require_results)
vec3_rotate :: proc "contextless" (v, axis: vec3, angle: f32) -> vec3 {

	axis  := normalize(axis)
	angle := angle * 0.5

	w   := axis*sin(angle)
	wv  := cross(w, v)
	wwv := cross(w, wv)

	wv  *= cos(angle)*2
	wwv *= 2

	return v + wv + wwv
}

@(require_results)
vec3_on_radius :: proc "contextless" (r, a, y: f32) -> vec3 {
	return {r * cos(a), y, r * sin(a)}
}

@(require_results)
vec3_transform :: proc "contextless" (v: vec3, m: mat4) -> vec3 {
	w := m[0][3] * v.x + m[1][3] * v.y + m[2][3] * v.z + m[3][3]

	return {
		(m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z + m[3][0]) / w,
		(m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z + m[3][1]) / w,
		(m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z + m[3][2]) / w,
	}
}

normals_from_positions :: proc (dst, src: []vec3) #no_bounds_check {
	assert(len(dst) >= len(src))
	assert(len(src) % 3 == 0)

	for i in 0 ..< len(src)/3 {
		a := src[i*3+0]
		b := src[i*3+1]
		c := src[i*3+2]

		normal := normalize(cross(b-a, c-a))

		dst[i*3+0] = normal
		dst[i*3+1] = normal
		dst[i*3+2] = normal
	}
}

@require_results
get_extents :: proc (positions: []vec3) -> (v_min, v_max: vec3) #no_bounds_check {

	if len(positions) > 0 {
		v_min = positions[0]
		v_max = positions[0]

		for pos in positions[1:] {
			v_min.x = min(pos.x, v_min.x)
			v_min.y = min(pos.y, v_min.y)
			v_min.z = min(pos.z, v_min.z)
			v_max.x = max(pos.x, v_max.x)
			v_max.y = max(pos.y, v_max.y)
			v_max.z = max(pos.z, v_max.z)
		}
	}

	return
}

extend_extents :: proc (v_min, v_max: ^vec3, positions: []vec3) {
	p_min, p_max := get_extents(positions)
	v_min^, v_max^ = get_extents({v_min^, v_max^, p_min, p_max})
}

points_bounds :: proc (points: []vec2) -> Rect #no_bounds_check {

	if len(points) == 0 do return {}

	min := points[0]
	max := points[0]

	for p in points[1:] {
		min = la.min(min, p)
		max = la.max(max, p)
	}

	return {min, max-min}
}
rect_to_points :: proc (r: Rect) -> [4]vec2 {
	return {
		r.pos,
		{r.pos.x + r.size.x, r.pos.y},
		{r.pos.x + r.size.x, r.pos.y + r.size.y},
		{r.pos.x, r.pos.y + r.size.y},
	}
}
rect_transform :: proc (r: Rect, m: mat3) -> Rect {
	points := rect_to_points(r)
	vec2_arr_transform(points[:], m)
	return points_bounds(points[:])
}
rect_union :: proc (a, b: Rect) -> Rect {
	min := la.min(a.pos, b.pos)
	max := la.max(a.pos + a.size, b.pos + b.size)

	return {min, max-min}
}

correct_extents :: proc (
	positions: []vec3,
	in_min:  vec3, in_max:  vec3,
	out_min: vec3, out_max: vec3,
) {
	in_span  := hypot(in_max-in_min)
	out_span := hypot(out_max-out_min)

	for &pos in positions {
		pos -= (in_max-in_min)/2 + in_min
		pos *= out_span/in_span
	}
}

DT_FIXED :: 1.0/60.0

exp_decay :: proc (a, b, decay: f32, dt: f32 = DT_FIXED) -> f32 {
	return b + (a-b) * exp(-decay * (dt/DT_FIXED))
}


vec2_from_angle :: proc "contextless" (angle: f32) -> vec2 {return {cos(angle), sin(angle)}}
vec2_from_rot      :: vec2_from_angle
vec2_from_rotation :: vec2_from_angle
rot_to_vec2        :: vec2_from_angle

@require_results vec2_angle           :: proc "contextless" (a, b: vec2) -> f32 {return  la.atan2(a.y-b.y, a.x-b.x)}
@require_results vec2_angle_clockwise :: proc "contextless" (a, b: vec2) -> f32 {return -la.atan2(b.y-a.y, b.x-a.x)}

vec2_rotate_angle :: proc "contextless" (v: vec2, angle: f32) -> vec2 {
	return vec2_rotate_vec(v, vec2_from_rot(angle))
}
vec2_rotate_vec :: proc "contextless" (v, rot: vec2) -> vec2 {
	return {
		v.x * rot.x - v.y * rot.y,
		v.x * rot.y + v.y * rot.x,
	}
}
vec2_rotate_angle_origin :: proc "contextless" (v: vec2, angle: f32, origin: vec2) -> vec2 {
	translated := v - origin
	rotated	:= vec2_rotate_angle(translated, angle)
	return rotated + origin
}
vec2_rotate_vec_origin :: proc "contextless" (v, rot: vec2, origin: vec2) -> vec2 {
	translated := v - origin
	rotated	:= vec2_rotate_vec(translated, rot)
	return rotated + origin
}
vec2_rotate :: proc {vec2_rotate_angle, vec2_rotate_vec, vec2_rotate_angle_origin, vec2_rotate_vec_origin}

angle_normalize :: proc (a: f32) -> f32 {
	return remainder(a, TAU)
}

angle_exp_decay :: proc (angle, goal, decay: f32, dt: f32 = DT_FIXED) -> f32 {
	angle := angle_normalize(angle)
	goal  := angle_normalize(goal)
	diff  := angle_normalize(goal - angle)

	if diff > PI {
		diff -= TAU
	}

	return angle_normalize(angle + diff * exp(-decay * (dt/DT_FIXED)))
}

angle_in_range :: proc "contextless" (a, b, c: f32) -> bool {
	return (a <= b && b <= c) || (c <= b && b <= a)
}

// Return a left-perpendicular vector (rotate +90°)
perp_left  :: proc "contextless" (v: vec2) -> vec2 {return {-v.y, v.x}}
// Return a right-perpendicular vector (rotate -90°)
perp_right :: proc "contextless" (v: vec2) -> vec2 {return {v.y, -v.x}}


// Check if two points are approximately equal within epsilon tolerance
vec2_approx_equal :: proc "contextless" (a, b: vec2, epsilon := EPSILON) -> bool {
	return la.abs(a.x - b.x) < epsilon && la.abs(a.y - b.y) < epsilon
}

// Barycentric coordinate test
point_in_triangle :: proc "contextless" (p, a, b, c: vec2) -> bool {
	v0 := c - a
	v1 := b - a
	v2 := p - a

	dot00 := dot(v0, v0)
	dot01 := dot(v0, v1)
	dot02 := dot(v0, v2)
	dot11 := dot(v1, v1)
	dot12 := dot(v1, v2)

	inv_denom := 1 / (dot00 * dot11 - dot01 * dot01)
	u := (dot11 * dot02 - dot01 * dot12) * inv_denom
	v := (dot00 * dot12 - dot01 * dot02) * inv_denom

	return u >= 0 && v >= 0 && u + v <= 1
}
// Barycentric coordinate test with epsilon tolerance
point_in_triangle_approx :: proc "contextless" (p, a, b, c: vec2, epsilon := EPSILON) -> bool {
	v0 := c - a
	v1 := b - a
	v2 := p - a

	dot00 := dot(v0, v0)
	dot01 := dot(v0, v1)
	dot02 := dot(v0, v2)
	dot11 := dot(v1, v1)
	dot12 := dot(v1, v2)

	denom := dot00 * dot11 - dot01 * dot01

	// Handle degenerate triangle (all points collinear)
	if abs(denom) < epsilon do return false

	inv_denom := 1 / denom
	u := (dot11 * dot02 - dot01 * dot12) * inv_denom
	v := (dot00 * dot12 - dot01 * dot02) * inv_denom

	// Use epsilon tolerance for boundary checks
	return u >= -epsilon && v >= -epsilon && u + v <= 1 + epsilon
}

// Edge-based point-in-triangle test
// Tests which side of each edge the point is on
// Assumes counter-clockwise triangle orientation
point_in_triangle_edge :: proc "contextless" (p, a, b, c: vec2) -> bool {
	// Calculate cross product for each edge
	// For a counter-clockwise triangle, point is inside if it's to the left of all edges
	// Cross product (edge × point_vector) tells us which side the point is on

	edge1 := (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x) // edge a->b
	edge2 := (c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x) // edge b->c
	edge3 := (a.x - c.x) * (p.y - c.y) - (a.y - c.y) * (p.x - c.x) // edge c->a

	// For counter-clockwise triangles, all cross products should be >= 0 for inside/on edge
	// If any is < 0, point is outside
	has_negative := edge1 < 0 || edge2 < 0 || edge3 < 0
	has_positive := edge1 > 0 || edge2 > 0 || edge3 > 0

	// Point is inside only if all have the same sign (or zero)
	return !(has_negative && has_positive)
}

// Edge-based point-in-triangle test with epsilon tolerance
// More robust for scaled/transformed geometry
point_in_triangle_edge_approx :: proc "contextless" (p, a, b, c: vec2, epsilon := EPSILON) -> bool {
	// Calculate cross product for each edge
	edge1 := (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x) // edge a->b
	edge2 := (c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x) // edge b->c
	edge3 := (a.x - c.x) * (p.y - c.y) - (a.y - c.y) * (p.x - c.x) // edge c->a

	// Apply epsilon tolerance to edge tests
	// Point is inside if it's on the left side (or within epsilon) of all edges
	return edge1 >= -epsilon && edge2 >= -epsilon && edge3 >= -epsilon
}

point_in_polygon :: proc "contextless" (p: vec2, pts: []vec2) -> (inside: bool) {
	// Ray-casting algorithm
	for a, i in pts {
		b := pts[(i+1)%len(pts)]
		if (a.y > p.y) != (b.y > p.y) && p.x < (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x {
			inside = !inside
		}
	}
	return
}

point_in_rect :: proc "contextless" (p: vec2, r: Rect) -> bool {
	return p.x >= r.pos.x && p.x <= r.pos.x + r.size.x &&
	       p.y >= r.pos.y && p.y <= r.pos.y + r.size.y
}
point_in_aabb :: point_in_rect

// Determine the turn direction of the triplet (a, b, c)
// Returns:
// - a positive value if c is to the left of the line a->b,
// - negative if to the right,
// - and zero if collinear.
turn_direction :: proc "contextless" (a, b, c: vec2) -> f32 {
	// (b - a) x (c - a)
	return (a.x-c.x) * (b.y-a.y) - (b.x-a.x) * (a.y-c.y)
}

// counter-clockwise check
ccw :: proc "contextless" (a, b, c: vec2) -> bool {
	return (b.x-a.x) * (c.y-a.y) < (c.x-a.x) * (b.y-a.y) // flipped for y-down coordinate system
}

polygon_ccw :: proc "contextless" (pts: []vec2) -> bool {
	sum: f32
	for i in 0 ..< len(pts) {
		a := pts[i]
		b := pts[(i+1) % len(pts)]
		sum += (b.x - a.x) * (b.y + a.y)
	}
	return sum < 0 // flipped for y-down coordinate system
}
poly_ccw :: polygon_ccw

polygon_enforce_ccw :: proc (pts: []vec2) {
	if !polygon_ccw(pts) {
		slice.reverse(pts)
	}
}

// ccw segments intersection check - doesn't handle collinear segments
@require_results
ccw_segments_intersecting :: proc "contextless" (a, b, c, d: vec2) -> bool {
	return ccw(a, c, d) != ccw(b, c, d) &&
	       ccw(a, b, c) != ccw(a, b, d)
}

@require_results
segments_intersecting :: proc "contextless" (p1, p2, p3, p4: vec2) -> bool {
	d1 := cross(p1-p3, p4-p3)
	d2 := cross(p2-p3, p4-p3)
	d3 := cross(p3-p1, p2-p1)
	d4 := cross(p4-p1, p2-p1)

	return sign(d1) != sign(d2) && sign(d3) != sign(d4)
}

@require_results
segments_intersection :: proc "contextless" (p1, p2, p3, p4: vec2) -> (pos: vec2, ok: bool) {
	d1 := cross(p1-p3, p4-p3)
	d2 := cross(p2-p3, p4-p3)
	d3 := cross(p3-p1, p2-p1)
	d4 := cross(p4-p1, p2-p1)

	if sign(d1) != sign(d2) && sign(d3) != sign(d4) {
		t := d1 / (d1 - d2)
		return lerp(p1, p2, t), true
	}

	return
}

// Check if two polygons intersect (share any edge intersection or one contains the other)
@require_results
polygons_intersect_or_contain :: proc(poly_a, poly_b: []vec2) -> bool {

	// Check for edge intersections
	for i in 1..=len(poly_a) {
		a1, a2 := poly_a[i-1], poly_a[i % len(poly_a)]

		for j in 1..=len(poly_b) {
			b1, b2 := poly_b[j-1], poly_b[j % len(poly_b)]

			if segments_intersecting(a1, a2, b1, b2) {
				return true
			}
		}
	}

	// Check if one is inside the other
	if point_in_polygon(poly_a[0], poly_b) ||
	   point_in_polygon(poly_b[0], poly_a) {
		return true
	}

	return false
}

// Compute area using shoelace formula
@require_results
polygon_area :: proc "contextless" (poly: []vec2) -> (area: f32) {
	for i in 1..=len(poly) {
		area += cross(poly[i-1], poly[i % len(poly)])
	}
	return area * 0.5
}

// Clip a polygon against a line segment.
// Returns vertices of the polygon that lie on the side of the line defined by clip_start->clip_end.
// The "inside" side is determined by the left perpendicular of the clip segment (CCW winding).
@require_results
segment_clip_polygon :: proc(poly: []vec2, clip_start, clip_end: vec2, allocator := context.allocator) -> []vec2 {

	clip_dir := normalize(clip_end - clip_start)
	clip_dir = perp_left(clip_dir) // Use left perpendicular for CCW inside test
	clipped := make([dynamic]vec2, allocator)

	for i in 1 ..= len(poly) {
		a, b := poly[i-1], poly[i % len(poly)]

		// Check which side of the clip line each vertex is on using CCW
		if dot(a - clip_start, clip_dir) >= 0 {
			append(&clipped, a)
		}

		// Edge crosses the clip line - compute intersection
		intersect := segments_intersection(clip_start, clip_end, a, b) or_continue
		append(&clipped, intersect)
	}

	return clipped[:]
}

// Clip a polygon against a line.
// The "inside" side is determined by the left perpendicular of the clip line (CCW winding).
@require_results
line_clip_polygon :: proc(poly: []vec2, clip_pos, clip_dir: vec2, allocator := context.allocator) -> []vec2 {

	clipped := make([dynamic]vec2, allocator)

	for i in 1 ..< len(poly) + 1 {
		a, b := poly[i - 1], poly[i % len(poly)]

		// Check which side of the clip line each vertex is on
		clip_a := dot(a - clip_pos, clip_dir) < 0
		clip_b := dot(b - clip_pos, clip_dir) < 0

		if !clip_a {
			append(&clipped, a)
		}

		// Edge crosses the clip line - compute intersection
		if clip_a != clip_b {
			dot1 := dot(a, clip_dir)
			dot2 := dot(b, clip_dir)
			t := (dot(clip_pos, clip_dir) - dot1) / (dot2 - dot1)
			clip := lerp(a, b, t)

			append(&clipped, clip)
		}
	}

	return clipped[:]
}

Ray :: struct {
	origin: vec2,
	dir:    vec2, // should be normalized
}

Raycast_Hit :: struct {
    pos: vec2,
    n:   vec2,
    t:   f32,
}

// Ray vs segment [a, b]; returns smallest t >= 0, and u in [0,1] along the segment.
// Based on solving origin + t*dir = a + u*(b-a) in 2D via cross products.
ray_intersect_segment :: proc (r: Ray, a, b: vec2) -> (t: f32, u: f32, ok: bool) {

    v := b - a
    w := r.origin - a
    denom := cross(r.dir, v)

	// Parallel (or collinear). Treat as no hit for typical raycast; special-case if you want.
    if abs(denom) < math.F32_EPSILON do return

    inv := 1.0 / denom
    t = cross(v, w) * inv
    u = cross(r.dir, w) * inv
	ok = t >= 0.0 && u >= 0.0 && u <= 1.0

    return
}

// Generic (possibly concave) polygon: test all edges and pick smallest positive t.
// verts should be in a consistent winding (CCW for outward normals).
// For concave shapes this returns intersection with the first edge hit; if you need
// strictly the boundary entering hit for concave shapes, this is correct for raycasts.
ray_intersect_polygon_edges :: proc (r: Ray, verts: []vec2) -> (hit: Raycast_Hit, hit_idx: int, ok: bool) {

    hit.t = math.INF_F32

    for i in 0 ..< len(verts) {
        j := (i+1) % len(verts)

		a, b := verts[i], verts[j]

        t, _, hok := ray_intersect_segment(r, a, b)
        if hok && t >= 0.0 && t < hit.t {
			hit.t   = t
			hit.pos = r.origin + r.dir * t
			hit.n   = normalize(perp_left(b - a))
			hit_idx = i
			ok      = true
        }
    }

    return
}

// Optimized raycast for convex polygons - returns on first hit (entry point).
// verts must be in CCW winding order for correct outward normals.
// For convex shapes, the first edge intersection is always the entry point.
ray_intersect_convex_polygon :: proc (r: Ray, verts: []vec2) -> (hit: Raycast_Hit, hit_idx: int, ok: bool) {

    for i in 0 ..< len(verts) {
        j := (i+1) % len(verts)

		a, b := verts[i], verts[j]

        t, _, hok := ray_intersect_segment(r, a, b)
        if hok && t >= 0.0 {
            hit.t   = t
            hit.pos = r.origin + r.dir * t
            hit.n   = normalize(perp_left(b - a))
            return hit, i, true
        }
    }

    return
}

// Ray vs Axis-Aligned Bounding Box (AABB/Rect).
// Uses slab method - tests intersection with each axis-aligned plane.
// Returns the closest intersection point and the normal of the face hit.
ray_intersect_rect :: proc (r: Ray, rect: Rect) -> (hit: Raycast_Hit, ok: bool) {

	inv_dir := 1/r.dir

	// Calculate t values for intersection with each pair of planes
	t1 := (rect.pos.x - r.origin.x) * inv_dir.x
	t2 := (rect.pos.x + rect.size.x - r.origin.x) * inv_dir.x
	t3 := (rect.pos.y - r.origin.y) * inv_dir.y
	t4 := (rect.pos.y + rect.size.y - r.origin.y) * inv_dir.y

	// Find min/max for each axis
	t_min_x := min(t1, t2)
	t_max_x := max(t1, t2)
	t_min_y := min(t3, t4)
	t_max_y := max(t3, t4)

	// Overall entry and exit points
	t_min := max(t_min_x, t_min_y)
	t_max := min(t_max_x, t_max_y)

	// No intersection if t_max < t_min or t_max < 0 (box is behind ray)
	if t_max < t_min || t_max < 0 {
		return
	}

	// Use t_min if >= 0 (ray starts outside), otherwise use t_max (ray starts inside)
	hit.t = t_min if t_min >= 0 else t_max
	hit.pos = r.origin + r.dir * hit.t

	// Determine which face was hit by checking which axis had the entry point
	if t_min >= 0 {
		// Ray starts outside - determine entry face
		if t_min == t_min_x {
			// Hit left or right face
			hit.n = {-1, 0} if r.dir.x > 0 else {1, 0}
		} else {
			// Hit top or bottom face
			hit.n = {0, -1} if r.dir.y > 0 else {0, 1}
		}
	} else {
		// Ray starts inside - determine exit face
		if t_max == t_max_x {
			hit.n = {1, 0} if r.dir.x > 0 else {-1, 0}
		} else {
			hit.n = {0, 1} if r.dir.y > 0 else {0, -1}
		}
	}

	return hit, true
}
ray_intersect_aabb :: ray_intersect_rect
