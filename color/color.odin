package color

import "base:builtin"

import la "core:math/linalg"


FRGB  :: distinct [3]f32
FRGBA :: distinct [4]f32

URGB  :: distinct [3]u8
URGBA :: distinct [4]u8

RGB  :: URGB
RGBA :: URGBA

Color :: union {
	FRGB,
	FRGBA,
	URGB,
	URGBA,
}

// Constructors and converters

frgb_from_scalars  :: proc "contextless" (r, g, b: f32)    -> FRGB  {return {r, g, b}}
frgba_from_scalars :: proc "contextless" (r, g, b, a: f32) -> FRGBA {return {r, g, b, a}}
urgb_from_scalars  :: proc "contextless" (r, g, b: u8)     -> URGB  {return {r, g, b}}
urgba_from_scalars :: proc "contextless" (r, g, b, a: u8)  -> URGBA {return {r, g, b, a}}

frgb_from_rgba  :: proc "contextless" (c: FRGBA) -> FRGB  {return {c.r, c.g, c.b}}
urgb_from_rgba  :: proc "contextless" (c: URGBA) -> URGB  {return {c.r, c.g, c.b}}

frgba_from_rgb  :: proc "contextless" (c: FRGB, a: f32) -> FRGBA {return {c.r, c.g, c.b, a}}
urgba_from_rgb  :: proc "contextless" (c: URGB, a: u8)  -> URGBA {return {c.r, c.g, c.b, a}}

urgb_from_2_1_u8 :: proc "contextless" (rg: $A/[2]u8, b: u8) -> URGB {return {rg.r, rg.g, b}}
urgb_from_1_2_u8 :: proc "contextless" (r: u8, gb: $A/[2]u8) -> URGB {return {r, gb.r, gb.g}}

urgba_from_3_1_u8 :: proc "contextless" (rgb: $A/[3]u8, a: u8)       -> URGBA {return {rgb.r, rgb.g, rgb.b, a}}
urgba_from_1_3_u8 :: proc "contextless" (r: u8, gba: $A/[3]u8)       -> URGBA {return {r, gba.r, gba.g, gba.b}}
urgba_from_2_2_u8 :: proc "contextless" (rg: $A/[2]u8, ba: $B/[2]u8) -> URGBA {return {rg.r, rg.g, ba.r, ba.g}}

frgb_from_2_1_f32 :: proc "contextless" (rg: $A/[2]f32, b: f32) -> FRGB {return {rg.r, rg.g, b}}
frgb_from_1_2_f32 :: proc "contextless" (r: f32, gb: $A/[2]f32) -> FRGB {return {r, gb.r, gb.g}}

frgba_from_3_1_f32 :: proc "contextless" (rgb: $A/[3]f32, a: f32)       -> FRGBA {return {rgb.r, rgb.g, rgb.b, a}}
frgba_from_1_3_f32 :: proc "contextless" (r: f32, gba: $A/[3]f32)       -> FRGBA {return {r, gba.r, gba.g, gba.b}}
frgba_from_2_2_f32 :: proc "contextless" (rg: $A/[2]f32, ba: $B/[2]f32) -> FRGBA {return {rg.r, rg.g, ba.r, ba.g}}

frgba_from_4_1_f32 :: proc "contextless" (rgb: $A/[4]f32, a: f32) -> FRGBA {return {rgb.r, rgb.g, rgb.b, a}}
frgba_from_1_4_f32 :: proc "contextless" (r: f32, gba: $A/[4]f32) -> FRGBA {return {r, gba.r, gba.g, gba.b}}

frgba_from_urgba :: proc "contextless" (c: URGBA) -> FRGBA {return {f32(c.r) / 255.0, f32(c.g) / 255.0, f32(c.b) / 255.0, f32(c.a) / 255.0}}
urgba_from_frgba :: proc "contextless" (c: FRGBA) -> URGBA {return {u8(builtin.clamp(c.r * 255.0, 0.0, 255.0)), u8(builtin.clamp(c.g * 255.0, 0.0, 255.0)), u8(builtin.clamp(c.b * 255.0, 0.0, 255.0)), u8(builtin.clamp(c.a * 255.0, 0.0, 255.0))}}
frgb_from_urgb   :: proc "contextless" (c: URGB)  -> FRGB {return {f32(c.r) / 255.0, f32(c.g) / 255.0, f32(c.b) / 255.0}}
urgb_from_frgb   :: proc "contextless" (c: FRGB)  -> URGB {return {u8(builtin.clamp(c.r * 255.0, 0.0, 255.0)), u8(builtin.clamp(c.g * 255.0, 0.0, 255.0)), u8(builtin.clamp(c.b * 255.0, 0.0, 255.0))}}

frgb_from_color  :: proc "contextless" (color: Color) -> FRGB {
	switch c in color {
	case FRGB:  return c
	case FRGBA: return frgb_from_rgba(c)
	case URGB:  return frgb_from_urgb(c)
	case URGBA: return frgb_from_urgb(urgb_from_rgba(c))
	case:       return {}
	}
}
frgba_from_color :: proc "contextless" (color: Color) -> FRGBA {
	switch c in color {
	case FRGBA: return c
	case FRGB:  return frgba_from_rgb(c, 1.0)
	case URGBA: return frgba_from_urgba(c)
	case URGB:  return frgba_from_rgb(frgb_from_urgb(c), 1.0)
	case:       return {}
	}
}
urgb_from_color  :: proc "contextless" (color: Color) -> URGB {
	switch c in color {
	case URGB:  return c
	case URGBA: return urgb_from_rgba(c)
	case FRGB:  return urgb_from_frgb(c)
	case FRGBA: return urgb_from_frgb(frgb_from_rgba(c))
	case:       return {}
	}
}
urgba_from_color :: proc "contextless" (color: Color) -> URGBA {
	switch c in color {
	case URGBA: return c
	case URGB:  return urgba_from_rgb(c, 255)
	case FRGBA: return urgba_from_frgba(c)
	case FRGB:  return urgba_from_rgb(urgb_from_frgb(c), 255)
	case:       return {}
	}
}

frgb  :: proc {frgb_from_color,  frgb_from_scalars,  frgb_from_rgba, frgb_from_urgb,   frgb_from_2_1_f32,  frgb_from_1_2_f32}
frgba :: proc {frgba_from_color, frgba_from_scalars, frgba_from_rgb, frgba_from_urgba, frgba_from_3_1_f32, frgba_from_1_3_f32, frgba_from_2_2_f32, frgba_from_4_1_f32, frgba_from_1_4_f32}
urgb  :: proc {urgb_from_color,  urgb_from_scalars,  urgb_from_rgba, urgb_from_frgb,   urgb_from_2_1_u8,   urgb_from_1_2_u8}
urgba :: proc {urgba_from_color, urgba_from_scalars, urgba_from_rgb, urgba_from_frgba, urgba_from_3_1_u8,  urgba_from_1_3_u8, urgba_from_2_2_u8}
rgb   :: urgb
rgba  :: urgba

// Common colors

FRGBA_BLACK         :: FRGBA{0.0,  0.0,  0.0,  1.0}
FRGBA_DARK_GRAY     :: FRGBA{0.2,  0.2,  0.2,  1.0}
FRGBA_GRAY          :: FRGBA{0.5,  0.5,  0.5,  1.0}
FRGBA_LIGHT_GRAY    :: FRGBA{0.8,  0.8,  0.8,  1.0}
FRGBA_WHITE         :: FRGBA{1.0,  1.0,  1.0,  1.0}
FRGBA_RED           :: FRGBA{1.0,  0.0,  0.0,  1.0}
FRGBA_GREEN         :: FRGBA{0.0,  1.0,  0.0,  1.0}
FRGBA_BLUE          :: FRGBA{0.0,  0.0,  1.0,  1.0}
FRGBA_CYAN          :: FRGBA{0.0,  1.0,  1.0,  1.0}
FRGBA_MAGENTA       :: FRGBA{1.0,  0.0,  1.0,  1.0}
FRGBA_YELLOW        :: FRGBA{1.0,  1.0,  0.0,  1.0}
FRGBA_ORANGE        :: FRGBA{1.0,  0.5,  0.0,  1.0}
FRGBA_PURPLE        :: FRGBA{0.5,  0.0,  0.5,  1.0}

URGBA_BLACK         :: URGBA{  0,    0,    0,  255}
URGBA_DARK_GRAY     :: URGBA{ 51,   51,   51,  255}
URGBA_GRAY          :: URGBA{128,  128,  128,  255}
URGBA_LIGHT_GRAY    :: URGBA{204,  204,  204,  255}
URGBA_WHITE         :: URGBA{255,  255,  255,  255}
URGBA_RED           :: URGBA{255,    0,    0,  255}
URGBA_GREEN         :: URGBA{  0,  255,    0,  255}
URGBA_BLUE          :: URGBA{  0,    0,  255,  255}
URGBA_CYAN          :: URGBA{  0,  255,  255,  255}
URGBA_MAGENTA       :: URGBA{255,    0,  255,  255}
URGBA_YELLOW        :: URGBA{255,  255,    0,  255}
URGBA_ORANGE        :: URGBA{255,  128,    0,  255}
URGBA_PURPLE        :: URGBA{128,    0,  128,  255}

// Utility functions

frgb_clamp :: proc "contextless" (c: FRGB) -> FRGB {
	return {
		builtin.clamp(c.r, 0.0, 1.0),
		builtin.clamp(c.g, 0.0, 1.0),
		builtin.clamp(c.b, 0.0, 1.0),
	}
}
frgba_clamp :: proc "contextless" (c: FRGBA) -> FRGBA {
	return {
		builtin.clamp(c.r, 0.0, 1.0),
		builtin.clamp(c.g, 0.0, 1.0),
		builtin.clamp(c.b, 0.0, 1.0),
		builtin.clamp(c.a, 0.0, 1.0),
	}
}
clamp :: proc {frgb_clamp, frgba_clamp}

frgb_lerp :: proc "contextless" (a, b: FRGB, t: f32) -> FRGB {
	return {
		la.lerp(a.r, b.r, t),
		la.lerp(a.g, b.g, t),
		la.lerp(a.b, b.b, t),
	}
}
frgba_lerp :: proc "contextless" (a, b: FRGBA, t: f32) -> FRGBA {
	return {
		la.lerp(a.r, b.r, t),
		la.lerp(a.g, b.g, t),
		la.lerp(a.b, b.b, t),
		la.lerp(a.a, b.a, t),
	}
}
urgb_lerp :: proc "contextless" (a, b: URGB, t: f32) -> URGB {
	return {
		u8(builtin.clamp(la.lerp(f32(a.r), f32(b.r), t), 0.0, 255.0)),
		u8(builtin.clamp(la.lerp(f32(a.g), f32(b.g), t), 0.0, 255.0)),
		u8(builtin.clamp(la.lerp(f32(a.b), f32(b.b), t), 0.0, 255.0)),
	}
}
urgba_lerp :: proc "contextless" (a, b: URGBA, t: f32) -> URGBA {
	return {
		u8(builtin.clamp(la.lerp(f32(a.r), f32(b.r), t), 0.0, 255.0)),
		u8(builtin.clamp(la.lerp(f32(a.g), f32(b.g), t), 0.0, 255.0)),
		u8(builtin.clamp(la.lerp(f32(a.b), f32(b.b), t), 0.0, 255.0)),
		u8(builtin.clamp(la.lerp(f32(a.a), f32(b.a), t), 0.0, 255.0)),
	}
}
lerp :: proc {frgb_lerp, frgba_lerp, urgb_lerp, urgba_lerp}

frgb_darken :: proc "contextless" (c: FRGB, factor: f32) -> FRGB {
	return {
		builtin.clamp(c.r * (1.0 - factor), 0.0, 1.0),
		builtin.clamp(c.g * (1.0 - factor), 0.0, 1.0),
		builtin.clamp(c.b * (1.0 - factor), 0.0, 1.0),
	}
}
frgba_darken :: proc "contextless" (c: FRGBA, factor: f32) -> FRGBA {
	return {
		builtin.clamp(c.r * (1.0 - factor), 0.0, 1.0),
		builtin.clamp(c.g * (1.0 - factor), 0.0, 1.0),
		builtin.clamp(c.b * (1.0 - factor), 0.0, 1.0),
		builtin.clamp(c.a, 0.0, 1.0),
	}
}
urgb_darken :: proc "contextless" (c: URGB, factor: f32) -> URGB {
	return {
		u8(builtin.clamp(f32(c.r) * (1.0 - factor), 0.0, 255.0)),
		u8(builtin.clamp(f32(c.g) * (1.0 - factor), 0.0, 255.0)),
		u8(builtin.clamp(f32(c.b) * (1.0 - factor), 0.0, 255.0)),
	}
}
urgba_darken :: proc "contextless" (c: URGBA, factor: f32) -> URGBA {
	return {
		u8(builtin.clamp(f32(c.r) * (1.0 - factor), 0.0, 255.0)),
		u8(builtin.clamp(f32(c.g) * (1.0 - factor), 0.0, 255.0)),
		u8(builtin.clamp(f32(c.b) * (1.0 - factor), 0.0, 255.0)),
		u8(builtin.clamp(f32(c.a), 0.0, 255.0)),
	}
}
darken :: proc {frgb_darken, frgba_darken, urgb_darken, urgba_darken}

frgb_lighten :: proc "contextless" (c: FRGB, factor: f32) -> FRGB {
	return {
		builtin.clamp(c.r + (1.0 - c.r) * factor, 0.0, 1.0),
		builtin.clamp(c.g + (1.0 - c.g) * factor, 0.0, 1.0),
		builtin.clamp(c.b + (1.0 - c.b) * factor, 0.0, 1.0),
	}
}
frgba_lighten :: proc "contextless" (c: FRGBA, factor: f32) -> FRGBA {
	return {
		builtin.clamp(c.r + (1.0 - c.r) * factor, 0.0, 1.0),
		builtin.clamp(c.g + (1.0 - c.g) * factor, 0.0, 1.0),
		builtin.clamp(c.b + (1.0 - c.b) * factor, 0.0, 1.0),
		builtin.clamp(c.a, 0.0, 1.0),
	}
}
urgb_lighten :: proc "contextless" (c: URGB, factor: f32) -> URGB {
	return {
		u8(builtin.clamp(f32(c.r) + (255.0 - f32(c.r)) * factor, 0.0, 255.0)),
		u8(builtin.clamp(f32(c.g) + (255.0 - f32(c.g)) * factor, 0.0, 255.0)),
		u8(builtin.clamp(f32(c.b) + (255.0 - f32(c.b)) * factor, 0.0, 255.0)),
	}
}
urgba_lighten :: proc "contextless" (c: URGBA, factor: f32) -> URGBA {
	return {
		u8(builtin.clamp(f32(c.r) + (255.0 - f32(c.r)) * factor, 0.0, 255.0)),
		u8(builtin.clamp(f32(c.g) + (255.0 - f32(c.g)) * factor, 0.0, 255.0)),
		u8(builtin.clamp(f32(c.b) + (255.0 - f32(c.b)) * factor, 0.0, 255.0)),
		u8(builtin.clamp(f32(c.a), 0.0, 255.0)),
	}
}
lighten :: proc {frgb_lighten, frgba_lighten, urgb_lighten, urgba_lighten}
