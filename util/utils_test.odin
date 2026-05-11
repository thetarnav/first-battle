#+ test
package util

import "core:testing"
import "core:slice"

@(test)
test_ordered_move :: proc (t: ^testing.T) {
	a := [5]int{0, 1, 2, 3, 4}

	ordered_move(a[:], 1, 3)
	testing.expect_value(t, a, [5]int{0, 2, 3, 1, 4})

	ordered_move(a[:], 3, 1)
	testing.expect_value(t, a, [5]int{0, 1, 2, 3, 4})
}

@(test)
test_ordered_move_soa :: proc (t: ^testing.T) {
	S :: struct {
		x: u8,
		y: f64,
	}
	a: #soa[5]S
	for i in 0..<len(a) {
		a[i].x = u8(i)
		a[i].y = f64(i) * 1.5
	}
	// a: #soa[5]S = {{0, 0.0}, {1, 1.5}, {2, 3.0}, {3, 4.5}, {4, 6.0}}

	ordered_move_soa(a[:], 1, 3)
	testing.expect_value(t, a.x, [5]u8{0, 2, 3, 1, 4})
	testing.expect_value(t, a.y, [5]f64{0.0, 3.0, 4.5, 1.5, 6.0})

	ordered_move_soa(a[:], 3, 1)
	testing.expect_value(t, a.x, [5]u8{0, 1, 2, 3, 4})
	testing.expect_value(t, a.y, [5]f64{0.0, 1.5, 3.0, 4.5, 6.0})
}

@(test)
test_ordered_move_soa_slice :: proc (t: ^testing.T) {
	S :: struct {
		x: u8,
		y: int,
	}
	a: #soa[10]S
	for i in 0..<len(a) {
		a[i].x = u8(i)
		a[i].y = int(i)
	}

	original_x := slice.clone(a.x[1:6], context.temp_allocator)
	original_y := slice.clone(a.y[1:6], context.temp_allocator)

	changed_x := slice.clone(original_x, context.temp_allocator)
	changed_y := slice.clone(original_y, context.temp_allocator)

	changed_x[1], changed_x[2], changed_x[3] = original_x[2], original_x[3], original_x[1]
	changed_y[1], changed_y[2], changed_y[3] = original_y[2], original_y[3], original_y[1]

	testing.expect(t, !slice.equal(original_x, changed_x))
	testing.expect(t, !slice.equal(original_y, changed_y))

	testing.expect(t, slice.equal(a.x[1:6], original_x))
	testing.expect(t, slice.equal(a.y[1:6], original_y))

	ordered_move_soa(a[1:6], 1, 3)
	testing.expect(t, slice.equal(a.x[1:6], changed_x))
	testing.expect(t, slice.equal(a.y[1:6], changed_y))

	ordered_move_soa(a[1:6], 3, 1)
	testing.expect(t, slice.equal(a.x[1:6], original_x))
	testing.expect(t, slice.equal(a.y[1:6], original_y))
}

@(test)
test_group_connected_components :: proc (t: ^testing.T) {
	// Test empty slice
	{
		items: []int
		groups := group_connected_components(items, proc(a, b: int) -> bool {return false}, context.temp_allocator)
		testing.expect_value(t, len(groups), 0)
	}

	// Test single item
	{
		items := []int{42}
		groups := group_connected_components(items, proc(a, b: int) -> bool {return false}, context.temp_allocator)
		testing.expect_value(t, len(groups), 1)
		testing.expect_value(t, len(groups[0]), 1)
		testing.expect_value(t, groups[0][0], 0)
	}

	// Test no connections - each item is its own group
	{
		items := []int{1, 2, 3, 4, 5}
		groups := group_connected_components(items, proc(a, b: int) -> bool {return false}, context.temp_allocator)
		testing.expect_value(t, len(groups), 5)
		for g, i in groups {
			testing.expect_value(t, len(g), 1)
			testing.expect_value(t, g[0], i)
		}
	}

	// Test all connected - single group
	{
		items := []int{1, 2, 3, 4, 5}
		groups := group_connected_components(items, proc(a, b: int) -> bool {return true}, context.temp_allocator)
		testing.expect_value(t, len(groups), 1)
		testing.expect_value(t, len(groups[0]), 5)
		// Check all indices are present
		for i in 0..<5 {
			found := false
			for idx in groups[0] {
				if idx == i {
					found = true
					break
				}
			}
			testing.expect(t, found, "Expected to find index in group")
		}
	}

	// Test grouping by adjacency (difference of 1)
	{
		items := []int{1, 2, 5, 6, 10, 11, 12}
		check_adjacent :: proc(a, b: int) -> bool {
			return abs(a - b) == 1
		}
		groups := group_connected_components(items, check_adjacent, context.temp_allocator)

		testing.expect_value(t, len(groups), 3)

		// Group 1: items[0,1] = {1, 2}
		testing.expect_value(t, len(groups[0]), 2)
		testing.expect(t, slice.contains(groups[0], 0))
		testing.expect(t, slice.contains(groups[0], 1))

		// Group 2: items[2,3] = {5, 6}
		testing.expect_value(t, len(groups[1]), 2)
		testing.expect(t, slice.contains(groups[1], 2))
		testing.expect(t, slice.contains(groups[1], 3))

		// Group 3: items[4,5,6] = {10, 11, 12}
		testing.expect_value(t, len(groups[2]), 3)
		testing.expect(t, slice.contains(groups[2], 4))
		testing.expect(t, slice.contains(groups[2], 5))
		testing.expect(t, slice.contains(groups[2], 6))
	}

	// Test grouping with transitive connections
	{
		items := []int{1, 3, 5, 7, 9}
		// Connect items that differ by 2
		check_diff_2 :: proc(a, b: int) -> bool {
			return abs(a - b) == 2
		}
		groups := group_connected_components(items, check_diff_2, context.temp_allocator)

		// All should be connected: 1-3-5-7-9
		testing.expect_value(t, len(groups), 1)
		testing.expect_value(t, len(groups[0]), 5)
	}

	// Test with structs
	{
		Point :: struct {
			x, y: int,
		}
		points := []Point{
			{0, 0}, {1, 0}, {5, 5}, {6, 5}, {10, 10},
		}
		// Connect points within distance 2
		check_distance :: proc(a, b: Point) -> bool {
			dx := a.x - b.x
			dy := a.y - b.y
			dist_sq := dx*dx + dy*dy
			return dist_sq <= 4
		}
		groups := group_connected_components(points, check_distance, context.temp_allocator)

		testing.expect_value(t, len(groups), 3)

		// Group 1: points[0,1]
		testing.expect_value(t, len(groups[0]), 2)

		// Group 2: points[2,3]
		testing.expect_value(t, len(groups[1]), 2)

		// Group 3: points[4]
		testing.expect_value(t, len(groups[2]), 1)
	}
}

@(test)
test_slice_min_proc :: proc (t: ^testing.T) {
	// Test empty slice
	{
		s: []int
		res, ok := slice_min_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, !ok)
		testing.expect_value(t, res, 0)
	}

	// Test single element
	{
		s := []int{42}
		res, ok := slice_min_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, 42)
	}

	// Test multiple elements
	{
		s := []int{5, 3, 8, 1, 9, 2}
		res, ok := slice_min_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, 1)
	}

	// Test with custom projection (absolute value)
	{
		s := []int{-5, 3, -1, 2}
		res, ok := slice_min_proc(s, proc(x: int) -> int {return abs(x)})
		testing.expect(t, ok)
		testing.expect_value(t, res, -1)
	}

	// Test with negative numbers
	{
		s := []int{-5, -3, -8, -1}
		res, ok := slice_min_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, -8)
	}
}

@(test)
test_slice_max_proc :: proc (t: ^testing.T) {
	// Test empty slice
	{
		s: []int
		res, ok := slice_max_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, !ok)
		testing.expect_value(t, res, 0)
	}

	// Test single element
	{
		s := []int{42}
		res, ok := slice_max_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, 42)
	}

	// Test multiple elements
	{
		s := []int{5, 3, 8, 1, 9, 2}
		res, ok := slice_max_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, 9)
	}

	// Test with custom projection (absolute value)
	{
		s := []int{-5, 3, -8, 2}
		res, ok := slice_max_proc(s, proc(x: int) -> int {return abs(x)})
		testing.expect(t, ok)
		testing.expect_value(t, res, -8)
	}

	// Test with negative numbers
	{
		s := []int{-5, -3, -8, -1}
		res, ok := slice_max_proc(s, proc(x: int) -> int {return x})
		testing.expect(t, ok)
		testing.expect_value(t, res, -1)
	}
}
