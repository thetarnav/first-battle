package first_battle

in_bounds_slice         :: #force_inline proc "contextless" (arr: $T/[]$E, #any_int i: int) -> bool            {return i >= 0 && i < len(arr)}
in_bounds_array         :: #force_inline proc "contextless" (arr: $T/[$N]$E, #any_int i: int) -> bool          {return i >= 0 && i < len(arr)}
in_bounds_dyn_array     :: #force_inline proc "contextless" (arr: $T/[dynamic]$E, #any_int i: int) -> bool     {return i >= 0 && i < len(arr)}
in_bounds_soa_slice     :: #force_inline proc "contextless" (arr: $T/#soa[]$E, #any_int i: int) -> bool        {return i >= 0 && i < len(arr)}
in_bounds_soa_array     :: #force_inline proc "contextless" (arr: $T/#soa[$N]$E, #any_int i: int) -> bool      {return i >= 0 && i < len(arr)}
in_bounds_soa_dyn_array :: #force_inline proc "contextless" (arr: $T/#soa[dynamic]$E, #any_int i: int) -> bool {return i >= 0 && i < len(arr)}
in_bounds_range         :: #force_inline proc "contextless" (min, max, #any_int i: int) -> bool                {return i >= min && i < max}
in_bounds :: proc {in_bounds_slice, in_bounds_array, in_bounds_dyn_array, in_bounds_soa_slice, in_bounds_soa_array, in_bounds_soa_dyn_array, in_bounds_range}

