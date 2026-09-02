package first_battle

import k2 "./karl2d"

grain_shader:  k2.Shader
grain_texture: k2.Render_Texture

grain_size_loc:        k2.Shader_Constant_Location
grain_pixel_scale_loc: k2.Shader_Constant_Location
grain_strength_loc:    k2.Shader_Constant_Location
grain_time_loc:        k2.Shader_Constant_Location

grain_init :: proc () {

    grain_shader = k2.load_shader_from_bytes(#load("base.vert"), #load("grain.frag"))

    grain_size_loc        = grain_shader.constant_lookup["size"]
    grain_pixel_scale_loc = grain_shader.constant_lookup["pixel_scale"]
    grain_strength_loc    = grain_shader.constant_lookup["strength"]
    grain_time_loc        = grain_shader.constant_lookup["time"]
}

grain_update :: proc () {

    size := window_size
    if size != k2_rect_size(k2.get_texture_rect(grain_texture.texture)) {
        grain_texture = k2.create_render_texture(**Vec2i(size))
    }

    k2.set_shader_constant(grain_shader, grain_size_loc,        size)
    k2.set_shader_constant(grain_shader, grain_strength_loc,    f32(0.026))
    k2.set_shader_constant(grain_shader, grain_pixel_scale_loc, f32(camera_board.zoom / TROOP_MAX_SIZE))
    k2.set_shader_constant(grain_shader, grain_time_loc,        f32(k2.get_time()))
}

glow_shader:  k2.Shader
glow_texture: k2.Render_Texture

glow_sun_pos_loc:  k2.Shader_Constant_Location
glow_strength_loc: k2.Shader_Constant_Location
glow_time_loc:     k2.Shader_Constant_Location

glow_init :: proc () {

    glow_shader = k2.load_shader_from_bytes(#load("base.vert"), #load("glow.frag"))

    glow_sun_pos_loc  = glow_shader.constant_lookup["sun_pos"]
    glow_strength_loc = glow_shader.constant_lookup["strength"]
    glow_time_loc     = glow_shader.constant_lookup["time"]
}

glow_update :: proc () {

    size := window_size
    if size != k2_rect_size(k2.get_texture_rect(glow_texture.texture)) {
        glow_texture = k2.create_render_texture(**Vec2i(size))
    }

    k2.set_shader_constant(glow_shader, glow_strength_loc, f32(0.4))
    k2.set_shader_constant(glow_shader, glow_sun_pos_loc,  Vec2{1.2, 1.0})
    k2.set_shader_constant(glow_shader, glow_time_loc,     f32(k2.get_time()))
}
