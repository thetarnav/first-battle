package util

import    "base:runtime"
import    "base:intrinsics"

@require_results
new_value :: #force_inline proc (value: $T, allocator := context.allocator, loc := #caller_location) -> (ptr: ^T, err: runtime.Allocator_Error) #optional_allocator_error {
	ptr = new(T, allocator, loc) or_return
	ptr^ = value
	return
}

slice_set_len :: #force_inline proc (s: ^$T/[]$E, #any_int new_len: int) {
	ptr := cast(^runtime.Raw_Slice)s
	ptr.len = new_len
}
slice_set_set :: slice_set_len
slice_len_add :: #force_inline proc (s: ^$T/[]$E, #any_int count: int) {
	ptr := cast(^runtime.Raw_Slice)s
	ptr.len += count
}
@require_results
slice_idx_from :: #force_inline proc (s: $T/[]$E, from: rawptr) -> int {
	return int(uintptr(raw_data(s)) - uintptr(from)) / size_of(E)
}
@require_results
slice_idx_from_slice :: #force_inline proc (s: $T/[]$E, from: $U/[]E) -> int {
	return int(uintptr(raw_data(s)) - uintptr(raw_data(from))) / size_of(E)
}
slice_start_idx_add :: #force_inline proc (s: ^$T/[]$E, #any_int count: int) {
	ptr := cast(^runtime.Raw_Slice)s
	ptr.data = rawptr(uintptr(ptr.data) + uintptr(count) * size_of(E))
}

@require_results
slice_equals_by :: proc(a, b: $T/[]$E, f: proc (E, E) -> bool) -> bool #no_bounds_check
{
	if len(a) != len(b) {
		return false
	}
	for i in 0..<len(a) {
		if f(a[i], b[i]) {
			return false
		}
	}
	return true
}

@require_results
array_cast :: proc "contextless" (v: $A/[$N]$E, $T: typeid) -> (w: T)
	where intrinsics.type_is_array(T), len(T) == N #no_bounds_check
{
	for i in 0..<N {
		w[i] = cast(intrinsics.type_elem_type(T))(v[i])
	}
	return
}

@(disabled=ODIN_DISABLE_ASSERT)
assert_equal :: proc (a, b: $T, message := "value assertion", loc := #caller_location)
	where intrinsics.type_is_comparable(T)
{
	if a != b {
		assert(false, fmt.tprintf("%s: %v != %v", message, a, b), loc)
	}
}

is_int :: #force_inline proc (float: f64) -> bool {
	return f64(int(float)) == float
}

alloc_error_message :: proc ($PREFIX: string, err: runtime.Allocator_Error) -> string
{
	switch err {
	case .Invalid_Argument:     return PREFIX+"Invalid_Argument"
	case .Invalid_Pointer:      return PREFIX+"Invalid_Pointer"
	case .Mode_Not_Implemented: return PREFIX+"Mode_Not_Implemented"
	case .Out_Of_Memory:        return PREFIX+"Out_Of_Memory"
	case .None:                 return PREFIX+"None"
	case:                       return PREFIX+"Unknown"
	}
}

@(disabled=ODIN_DISABLE_ASSERT)
alloc_error_assert :: proc ($PREFIX: string, err: runtime.Allocator_Error, loc := #caller_location) {
	if err != nil {
		panic(alloc_error_message("atom_new error: ", err), loc)
	}
}

@require_results
get_or_set_union_ptr :: #force_inline proc "contextless" (u: ^$U, $T: typeid) -> ^T where intrinsics.type_is_union(U) {
	v, is_t := &u.(T)
	if !is_t {
		u^ = T{}
		v, _ = &u.(T)
	}
	return v
}

@require_results
check_union_variant :: #force_inline proc (u: $T, $V: typeid) -> (is_variant: bool) {
	_, is_variant = u.(V)
	return
}

//	for iterating over array item pairs
//
//	```odin
//	idx := 0
//	for a, b in each_wrapping_pair([]int{1, 2, 3}, &idx) {
//		1, 2
//		2, 3
//		3, 1
//	}
//	```
each_wrapping_pair :: proc "contextless" (arr: []$T, i: ^int) -> (a, b: T, ok: bool) #no_bounds_check {
	if i^ >= 0 && i^ < len(arr) {
		a = arr[i^]
		b = arr[(i^+1)%len(arr)]
		i^ += 1
		ok = true
	}
	return
}

wrapping_pair_at :: proc "contextless" (arr: []$T, i: int, loc := #caller_location) -> (a, b: T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, i, len(arr))

	a = arr[i]
	b = arr[(i+1)%len(arr)]
	return
}

/*
0 -> -0 \
1 -> +0 \
2 -> -1 \
3 -> +1 \
4 -> -2 \
5 -> +2 \
*/
two_way_iota :: #force_inline proc "contextless" (i: int) -> int {
	return i / 2 * ((i % 2) * 2 - 1)
}
