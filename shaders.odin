package first_battle

import k2 "./karl2d"

Post_Step :: enum {Grain, Sun, Vignette}

post_shaders: [Post_Step]k2.Shader

grain_size_loc:        k2.Shader_Constant_Location
grain_pixel_scale_loc: k2.Shader_Constant_Location
grain_strength_loc:    k2.Shader_Constant_Location
grain_time_loc:        k2.Shader_Constant_Location

sun_sun_pos_loc:       k2.Shader_Constant_Location
sun_strength_loc:      k2.Shader_Constant_Location
sun_time_loc:          k2.Shader_Constant_Location

post_last_size: Vec2
post_textures:  [2]k2.Render_Texture

post_init :: proc () {

    SHADER_SRC_VERT     :: #load("./shaders/base.vert")
    SHADER_SRC_GRAIN    :: #load("./shaders/grain.frag")
    SHADER_SRC_SUN      :: #load("./shaders/sun.frag")
    SHADER_SRC_VIGNETTE :: #load("./shaders/vignette.frag")

    post_shaders[.Grain] = k2.load_shader_from_bytes(SHADER_SRC_VERT, SHADER_SRC_GRAIN)

    grain_size_loc        = post_shaders[.Grain].constant_lookup["size"]
    grain_pixel_scale_loc = post_shaders[.Grain].constant_lookup["pixel_scale"]
    grain_strength_loc    = post_shaders[.Grain].constant_lookup["strength"]
    grain_time_loc        = post_shaders[.Grain].constant_lookup["time"]

    post_shaders[.Sun] = k2.load_shader_from_bytes(SHADER_SRC_VERT, SHADER_SRC_SUN)

    sun_sun_pos_loc  = post_shaders[.Sun].constant_lookup["sun_pos"]
    sun_strength_loc = post_shaders[.Sun].constant_lookup["strength"]
    sun_time_loc     = post_shaders[.Sun].constant_lookup["time"]

    post_shaders[.Vignette] = k2.load_shader_from_bytes(SHADER_SRC_VERT, SHADER_SRC_VIGNETTE)
}

post_start :: proc () {

    size := window_size
    if size != post_last_size do for &tex in post_textures {
        if tex != {} {
            k2.destroy_render_texture(tex)
        }
        post_last_size = size
        tex = k2.create_render_texture(**Vec2i(size))
    }

    time := k2.get_time()

    k2.set_shader_constant(post_shaders[.Grain], grain_size_loc,        size)
    k2.set_shader_constant(post_shaders[.Grain], grain_strength_loc,    f32(0.026))
    k2.set_shader_constant(post_shaders[.Grain], grain_pixel_scale_loc, f32(camera_board.zoom / TROOP_MAX_SIZE))
    k2.set_shader_constant(post_shaders[.Grain], grain_time_loc,        f32(time))

    k2.set_shader_constant(post_shaders[.Sun], sun_strength_loc, f32(0.4))
    k2.set_shader_constant(post_shaders[.Sun], sun_sun_pos_loc,  Vec2{1.2, 1.0})
    k2.set_shader_constant(post_shaders[.Sun], sun_time_loc,     f32(time))


    k2.set_render_texture(post_textures[0])
    k2.clear(COLOR_BG)
}

post_end :: proc () {
    i := 0
    for shader, step in post_shaders {

        tex_src := post_textures[i]
        i = (i+1) % 2 // ping-pong between two render textures
        tex_dst := post_textures[i]

        k2.set_render_texture(tex_dst if step != max(Post_Step) else nil)
        k2.clear(COLOR_BG)

        k2.set_shader(shader)

        k2.draw_texture_fit(tex_src.texture,
            source = k2.get_texture_rect(tex_src.texture),
            dest   = k2.rect_from_pos_size({}, window_size),
        )
    }

    k2.set_shader(nil)
}
