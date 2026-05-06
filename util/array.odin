package util

import "base:runtime"
import "base:intrinsics"
import sa "core:container/small_array"

in_bounds_slice         :: #force_inline proc "contextless" (arr: $T/[]$E, #any_int i: int) -> bool            {return i >= 0 && i < len(arr)}
in_bounds_array         :: #force_inline proc "contextless" (arr: $T/[$N]$E, #any_int i: int) -> bool          {return i >= 0 && i < len(arr)}
in_bounds_dyn_array     :: #force_inline proc "contextless" (arr: $T/[dynamic]$E, #any_int i: int) -> bool     {return i >= 0 && i < len(arr)}
in_bounds_soa_slice     :: #force_inline proc "contextless" (arr: $T/#soa[]$E, #any_int i: int) -> bool        {return i >= 0 && i < len(arr)}
in_bounds_soa_array     :: #force_inline proc "contextless" (arr: $T/#soa[$N]$E, #any_int i: int) -> bool      {return i >= 0 && i < len(arr)}
in_bounds_soa_dyn_array :: #force_inline proc "contextless" (arr: $T/#soa[dynamic]$E, #any_int i: int) -> bool {return i >= 0 && i < len(arr)}
in_bounds_range         :: #force_inline proc "contextless" (min, max, #any_int i: int) -> bool                {return i >= min && i < max}
in_bounds :: proc {in_bounds_slice, in_bounds_array, in_bounds_dyn_array, in_bounds_soa_slice, in_bounds_soa_array, in_bounds_soa_dyn_array, in_bounds_range}

last_array           :: #force_inline proc "contextless" (arr: $T/[$N]$E, n := 1)                  ->  E #no_bounds_check {return arr[len(arr)-n]}
last_dyn_array       :: #force_inline proc "contextless" (arr: $T/[dynamic]$E, n := 1)             ->  E #no_bounds_check {return arr[len(arr)-n]}
last_slice           :: #force_inline proc "contextless" (arr: $T/[]$E, n := 1)                    ->  E #no_bounds_check {return arr[len(arr)-n]}
last_array_ptr       :: #force_inline proc "contextless" (arr: $T/^[$N]$E, n := 1)                 -> ^E #no_bounds_check {return &arr[len(arr)-n]}
last_dyn_array_ptr   :: #force_inline proc "contextless" (arr: $T/^[dynamic]$E, n := 1)            -> ^E #no_bounds_check {return &arr[len(arr)-n]}
last_slice_ptr       :: #force_inline proc "contextless" (arr: $T/^[]$E, n := 1)                   -> ^E #no_bounds_check {return &arr[len(arr)-n]}
last_small_array     :: #force_inline proc "contextless" (arr: $T/sa.Small_Array($N, $E), n := 1)  ->  E #no_bounds_check {return arr.data[sa.len(arr)-n]}
last_small_array_ptr :: #force_inline proc "contextless" (arr: $T/^sa.Small_Array($N, $E), n := 1) -> ^E #no_bounds_check {return &arr.data[sa.len(arr)-n]}
last :: proc {last_array, last_dyn_array, last_slice, last_array_ptr, last_dyn_array_ptr, last_slice_ptr, last_small_array, last_small_array_ptr}

last_array_safe           :: #force_inline proc "contextless" (arr: $T/[$N]$E, n := 1)                  -> (el:  E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return arr[len(arr)-n], true}
last_dyn_array_safe       :: #force_inline proc "contextless" (arr: $T/[dynamic]$E, n := 1)             -> (el:  E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return arr[len(arr)-n], true}
last_slice_safe           :: #force_inline proc "contextless" (arr: $T/[]$E, n := 1)                    -> (el:  E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return arr[len(arr)-n], true}
last_array_ptr_safe       :: #force_inline proc "contextless" (arr: $T/^[$N]$E, n := 1)                 -> (el: ^E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return &arr[len(arr)-n], true}
last_dyn_array_ptr_safe   :: #force_inline proc "contextless" (arr: $T/^[dynamic]$E, n := 1)            -> (el: ^E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return &arr[len(arr)-n], true}
last_slice_ptr_safe       :: #force_inline proc "contextless" (arr: $T/^[]$E, n := 1)                   -> (el: ^E, ok: bool) #no_bounds_check {if len(arr)-n < 0 || n <= 0    {return {}, false} else do return &arr[len(arr)-n], true}
last_small_array_safe     :: #force_inline proc "contextless" (arr: $T/sa.Small_Array($N, $E), n := 1)  -> (el:  E, ok: bool) #no_bounds_check {if sa.len(arr)-n < 0 || n <= 0 {return {}, false} else do return arr.data[sa.len(arr)-n], true}
last_small_array_ptr_safe :: #force_inline proc "contextless" (arr: $T/^sa.Small_Array($N, $E), n := 1) -> (el: ^E, ok: bool) #no_bounds_check {if sa.len(arr)-n < 0 || n <= 0 {return {}, false} else do return &arr.data[sa.len(arr)-n], true}
last_safe :: proc {last_array_safe, last_dyn_array_safe, last_slice_safe, last_array_ptr_safe, last_dyn_array_ptr_safe, last_slice_ptr_safe, last_small_array_safe, last_small_array_ptr_safe}

/*
Moves an element from one position to another within a slice, preserving order.

**Inputs**
- `arr`: The slice to operate on
- `from`: The index of the element to move
- `to`: The destination index

Example:

	import "core:slice"
	import "core:fmt"

	ordered_move_example :: proc() {
		data := []int{0, 1, 2, 3, 4}
		fmt.println(data)

		// Move element at index 1 to index 3
		slice.ordered_move(data, 1, 3)
		fmt.println(data)

		// Move it back
		slice.ordered_move(data, 3, 1)
		fmt.println(data)
	}

Output:

	[0, 1, 2, 3, 4]
	[0, 2, 3, 1, 4]
	[0, 1, 2, 3, 4]

*/
ordered_move :: proc "contextless" (arr: $T/[]$E, #any_int from, to: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, from, len(arr))
	runtime.bounds_check_error_loc(loc, to,   len(arr))

	if from == to || size_of(E) == 0 do return

	if from < to {
		tmp := arr[from]
		copy(arr[from:to], arr[from+1:to+1])
		arr[to] = tmp
	} else { // from > to
		tmp := arr[from]
		copy(arr[to+1:from+1], arr[to:from])
		arr[to] = tmp
	}
}

/*
Moves multiple consecutive elements from one position to another within a slice, preserving order.

**Inputs**
- `arr`: The slice to operate on
- `from`: The starting index of the elements to move
- `n`: The number of elements to move
- `to`: The destination index (where the first element will be placed)

Example:

	import "core:slice"
	import "core:fmt"

	ordered_move_many_example :: proc() {
		data := []int{0, 1, 2, 3, 4, 5, 6}
		fmt.println(data)

		// Move 2 elements starting at index 1 to index 4
		slice.ordered_move_many(data, 1, 2, 4)
		fmt.println(data)

		// Move them back
		slice.ordered_move_many(data, 4, 2, 1)
		fmt.println(data)
	}

Output:

	[0, 1, 2, 3, 4, 5, 6]
	[0, 3, 4, 1, 2, 5, 6]
	[0, 1, 2, 3, 4, 5, 6]

*/
ordered_move_many :: proc "contextless" (arr: $T/[]$E, #any_int from, to, n: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, from, len(arr))
	runtime.bounds_check_error_loc(loc, from+n, len(arr)+1)
	runtime.bounds_check_error_loc(loc, to, len(arr))
	runtime.bounds_check_error_loc(loc, to+n, len(arr)+1)

	if from == to || n <= 0 || size_of(E) == 0 do return

	tmp_arr: [5]E
	tmp := tmp_arr[:min(n, len(tmp_arr))]
	n := n

	if from < to {
		for n > 0 {
			chunk := min(n, len(tmp))
			copy(tmp, arr[from:][:chunk])
			copy(arr[from:to], arr[from+chunk:to+chunk])
			copy(arr[to:to+chunk], tmp[:chunk])
			n -= chunk
		}
	} else { // from > to
		for n > 0 {
			chunk := min(n, len(tmp))
			copy(tmp, arr[from:][:chunk])
			copy(arr[to+chunk:from+chunk], arr[to:from])
			copy(arr[to:to+chunk], tmp[:chunk])
			n -= chunk
		}
	}
}

/*
Moves an element from one position to another within a struct-of-arrays (SOA) slice, preserving order.

**Inputs**
- `array`: The SOA slice to operate on
- `from`: The index of the element to move
- `to`: The destination index

Example:

	import "core:slice"
	import "core:fmt"

	ordered_move_soa_example :: proc() {
		Point :: struct {x, y: int}
		points: #soa[5]Point = {
			{1, 2}, {3, 4}, {5, 6}, {7, 8}, {9, 10}
		}

		// Move element at index 1 to index 3
		slice.ordered_move_soa(points[:], 1, 3)
		fmt.println(points.x)
		fmt.println(points.y)
	}

Output:

	[1, 5, 7, 3, 9]
	[2, 6, 8, 4, 10]

*/
ordered_move_soa :: proc (array: $T/#soa[]$E, #any_int from, to: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, from, len(array))
	runtime.bounds_check_error_loc(loc, to,   len(array))

	if from == to || size_of(E) == 0 do return

	dst, src := from, from+1
	if from > to {
		dst, src = to+1, to
	}

	ti := runtime.type_info_base(type_info_of(typeid_of(T)))
	si := &ti.variant.(runtime.Type_Info_Struct)

	field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)

	array := array
	tmp: E

	for i in 0..<field_count {
		data := (^uintptr)(uintptr(&array) + uintptr(si.offsets[i]))^
		size := si.types[i].variant.(runtime.Type_Info_Multi_Pointer).elem.size

		runtime.mem_copy_non_overlapping(&tmp, rawptr(data + uintptr(from*size)), size)
		runtime.mem_copy(rawptr(data + uintptr(dst*size)), rawptr(data + uintptr(src*size)), size * abs(from - to))
		runtime.mem_copy_non_overlapping(rawptr(data + uintptr(to*size)), &tmp, size)
	}

	return
}

@require_results
append_ptr_soa :: #force_inline proc (arr: ^#soa[dynamic]$E, loc := #caller_location) -> (ptr: #soa^#soa[dynamic]E, err: runtime.Allocator_Error) #optional_allocator_error {
	append_nothing_soa(arr, loc) or_return
	ptr = &arr[len(arr)-1]
	return
}

@require_results
clone_soa :: proc (arr: $T/#soa[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (new_arr: T, err: runtime.Allocator_Error) #optional_allocator_error {
	new_arr = make_soa_dynamic_array_len_cap(T, len(arr), cap(arr), allocator, loc) or_return

	when size_of(E) == 0 do return

	ti := type_info_of(typeid_of(T))
	ti = runtime.type_info_base(ti)
	si := &ti.variant.(runtime.Type_Info_Struct)

	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

	arr := arr

	for i in 0..<field_count {
		src := (^rawptr)(uintptr(&arr)     + uintptr(si.offsets[i]))^
		dst := (^rawptr)(uintptr(&new_arr) + uintptr(si.offsets[i]))^
		size := si.types[i].variant.(runtime.Type_Info_Multi_Pointer).elem.size

		runtime.mem_copy_non_overlapping(dst, src, size * len(arr))
	}

	return
}

copy_array :: #force_inline proc "contextless" (dst: []$S, src: [$N]S) {
	src := src
	copy(dst, src[:])
}

copy_pattern :: #force_inline proc "contextless" (dst: []$S, src: []S) #no_bounds_check {
	for i in 0..<len(dst)/len(src) {
		copy(dst[i*len(src):][:len(src)], src)
	}
}

// Reset a dynamic array to its new initial items
reset :: proc (arr: ^$T/[dynamic]$E, init: []E) -> (err: runtime.Allocator_Error) {
	resize(arr, len(init)) or_return
	copy(arr[:], init)
	return
}

/*
Groups items into connected components based on a connectivity check function.

Items are considered part of the same component if they are directly or transitively
connected according to the check function. The check function returns true if two
items should be considered connected.

**Inputs**
- `items`: The slice of items to group
- `check`: A function that returns true if two items should be in the same group
- `allocator`: The allocator to use for creating groups (default: context.allocator)

**Returns**
- A slice of groups, where each group is a slice of indices into the original items array

Example:

	import "core:fmt"

	group_connected_components_example :: proc() {
		// Group numbers that differ by 1 (adjacent numbers)
		numbers := []int{1, 2, 5, 6, 7, 10}

		check_adjacent :: proc(a, b: int) -> bool {
			return abs(a - b) == 1
		}

		groups := group_connected_components(numbers, check_adjacent)

		for group, i in groups {
			fmt.printf("Group %d: ", i)
			for idx in group {
				fmt.printf("%d ", numbers[idx])
			}
			fmt.println()
		}
	}

Output:

	Group 0: 1 2
	Group 1: 5 6 7
	Group 2: 10

*/
@require_results
group_connected_components :: proc (items: $T/[]$E, check: proc (E, E) -> bool, allocator := context.allocator) -> [][]int #no_bounds_check {
	if len(items) == 0 do return {}

	indices := make([]int, len(items), allocator)
	for &p, i in indices {
		p = i
	}

	groups := make([dynamic][]int, 0, len(indices), allocator)
	defer shrink(&groups)

	items_loop: for item, item_idx in items {
		for &group, group_idx in groups {
			for g in group {
				check(item, items[g]) or_continue

				// Move the current item index right after the group
				group_start := slice_idx_from_slice(group, indices)
				group_end   := group_start + len(group)
				ordered_move(indices, item_idx, group_end)

				// Increase group len to join the new item
				slice_len_add(&group, +1)
				group_end += 1

				// Increase starts of all groups after this one
				if item_idx > group_end do for &group2 in groups[group_idx+1:] {
					slice_start_idx_add(&group2, +1)
				}

				// Combine following, connected groups
				for group2_idx := group_idx+1; group2_idx < len(groups); group2_idx += 1 {
					group2 := &groups[group2_idx]
					for g2 in group2 {
						check(item, items[g2]) or_continue

						// Move indices in group2 after group1
						group2_start := slice_idx_from_slice(group2^, indices)
						ordered_move_many(indices, group2_start, group_end, len(group2))

						// Increase group1 len
						slice_len_add(&group, +len(group2))
						group_end += len(group2)

						// Correct beginnings of groups between group1 and group2
						for &group3 in groups[group_idx+1:group2_idx] {
							slice_start_idx_add(&group3, +len(group2))
						}

						// Remove group2
						ordered_remove(&groups, group2_idx)
						group2_idx -= 1

						break
					}
				}

				continue items_loop
			}
		}

		// if not found in any groups, add a new one
		append(&groups, indices[item_idx:][:1])
	}

	return groups[:]
}
