package first_battle

// outline_from_points :: proc (pts: []vec2, allocator := context.allocator) -> []vec2 {
//     if len(pts) < 3 do return {}
//
//     outline := make([dynamic]vec2, 3, 16, allocator=allocator)
//     defer shrink(&outline)
//
//     copy(outline[:3], pts[:3])
//
//     for p in pts[3:] {
//         extend_outline(&outline, p)
//     }
//
//     return outline[:]
// }
//
// extend_outline :: proc (outline: ^[dynamic]vec2, p: vec2) {
//
//     if len(outline) < 3 {
//         append(outline, p)
//         return
//     }
//
//     if point_in_polygon(p, outline[:]) do return
//
//     added := false
//     for i := 0; i < len(outline); i += 1 {
//         a := outline[i]
//         b := outline[(i+1)%len(outline)]
//         if !ccw(a, b, p) {
//             if added {
//                 outline[i] = p
//             } else {
//                 inject_at(outline, i+1, p)
//                 added = true
//                 i += 1
//             }
//         } else {
//             added = false
//         }
//     }
// }

convex_hull :: proc (points: []Vec2, allocator := context.allocator) -> []Vec2 {

	n := len(points)
	if n <= 1 {
		return points
	}

    cross :: proc(a, b, c: Vec2) -> f32 {
        return (b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)
    }

	// Copy input so we can sort it
	sorted := make([]Vec2, n, allocator=context.temp_allocator)
	copy(sorted, points)

	// Lexicographic sort by x, then y
	for i in 0..<n {
		for j in i+1..<n {
			if sorted[j].x < sorted[i].x || (sorted[j].x == sorted[i].x && sorted[j].y < sorted[i].y) {
				sorted[i], sorted[j] = sorted[j], sorted[i]
			}
		}
	}

	hull := make([dynamic]Vec2, 0, n*2, allocator=allocator)

	// Lower hull
	for p in sorted {
		for len(hull) >= 2 && cross(hull[len(hull)-2], hull[len(hull)-1], p) <= 0 {
            resize(&hull, len(hull)-1)
		}
		append(&hull, p)
	}

	// Upper hull
	t := len(hull) + 1
	for i := n - 2; i >= 0; i -= 1 {
		p := sorted[i]
		for len(hull) >= t && cross(hull[len(hull)-2], hull[len(hull)-1], p) <= 0 {
            resize(&hull, len(hull)-1)
		}
		append(&hull, p)
		if i == 0 {
			break
		}
	}

	// Remove duplicate first/last point
	if len(hull) > 1 {
        resize(&hull, len(hull)-1)
	}

	return hull[:]
}


import "core:math"


// Expands a convex polygon outward by `amount`.
// Assumes `points` are in CCW order.
expand_convex_polygon :: proc(points: []Vec2, amount: f32, allocator := context.allocator) -> []Vec2 {

    vec_cross :: proc(a, b: Vec2) -> f32 {
        return a.x*b.y - a.y*b.x
    }

    vec_len :: proc(v: Vec2) -> f32 {
        return math.sqrt(v.x*v.x + v.y*v.y)
    }

    normalize :: proc(v: Vec2) -> Vec2 {
        l := vec_len(v)
        if l <= 0 {
            return v
        }
        inv := 1.0 / l
        return Vec2{v.x * inv, v.y * inv}
    }

    // For CCW polygons, this is the outward normal of edge a -> b.
    outward_normal_ccw :: proc(a, b: Vec2) -> Vec2 {
        e := Vec2{b.x - a.x, b.y - a.y}
        return normalize(Vec2{e.y, -e.x})
    }

    line_intersection :: proc(p, r, q, s: Vec2) -> Vec2 {
        denom := vec_cross(r, s)
        if math.abs(denom) < 1e-6 {
            return p
        }

        t := vec_cross(Vec2{q.x - p.x, q.y - p.y}, s) / denom
        return Vec2{p.x + r.x*t, p.y + r.y*t}
    }

	n := len(points)
	if n == 0 {
		return nil
	}
	if n == 1 {
		return points
	}
	if amount == 0 {
		out := make([]Vec2, n, allocator=allocator)
		copy(out, points)
		return out
	}

	out := make([dynamic]Vec2, 0, n, allocator=allocator)

	for i in 0..<n {
		prev := points[(i - 1 + n) % n]
		curr := points[i]
		next := points[(i + 1) % n]

		// Offset the two adjacent edges outward
		n0 := outward_normal_ccw(prev, curr)
		n1 := outward_normal_ccw(curr, next)

        append(&out, curr + n0*amount)
        append(&out, curr + n1*amount)

		// p0 := Vec2{prev.x + n0.x*amount, prev.y + n0.y*amount}
		// d0 := Vec2{curr.x - prev.x, curr.y - prev.y}
		//
		// p1 := Vec2{curr.x + n1.x*amount, curr.y + n1.y*amount}
		// d1 := Vec2{next.x - curr.x, next.y - curr.y}
		//
		// // Intersection of the two shifted edge lines
		// v := line_intersection(p0, d0, p1, d1)
		// append(&out, v)
	}

	return out[:]
}
