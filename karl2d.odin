package first_battle

import k2 "./karl2d"

k2_rect :: proc (rect: Rect) -> k2.Rect {
    return {
        x = rect.pos.x,
        y = rect.pos.y,
        w = rect.size.x,
        h = rect.size.y,
    }
}

k2_camera_fit_aspect :: proc (aspect: Vec2, margin: Vec2 = 0) -> k2.Camera {
    rect := rect_fit_aspect_max(aspect, window_size, margin)
    return {
        offset = rect.pos,
        zoom   = rect.size.x / aspect.x, // same as y because rect preserves aspect
    }
}

draw_texture :: proc (
    tex: k2.Texture,
    world_rect: Rect,
    tex_rect: Maybe(Rect) = nil,
    rot: f32 = 0,
    tint: Color = k2.WHITE,
) {
    center := world_rect.size * 0.5
    world_rect := world_rect
    world_rect.pos += center
    k2.draw_texture_fit(
        texture  = tex,
        source   = k2_rect(tex_rect.? or_else {0, {f32(tex.width), f32(tex.width)}}),
        dest     = k2_rect(world_rect),
        origin   = center,
        rotation = rot,
        tint     = tint,
    )
}
