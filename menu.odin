package first_battle

import "core:math"
import k2 "./karl2d"


should_display_menu: bool = true

slider_value: f32 = 0.5
slider_dragging: bool = false

draw_border :: proc (rect: Rect) {

    tex_tl := atlas_rects[.Border_TL]
    tex_tr := atlas_rects[.Border_TR]
    tex_bl := atlas_rects[.Border_BL]
    tex_br := atlas_rects[.Border_BR]
    tex_t  := atlas_rects[.Border_T]
    tex_b  := atlas_rects[.Border_B]
    tex_l  := atlas_rects[.Border_L]
    tex_r  := atlas_rects[.Border_R]

    // fill background
    k2.draw_rect_vec(rect.pos + tex_tl.size, rect.size - tex_tl.size - tex_br.size, COLOR_BG)

    // corners
    draw_texture(tex_atlas, {rect.pos, tex_tl.size}, tex_tl)
    draw_texture(tex_atlas, {rect.pos + {rect.size.x - tex_tr.size.x, 0}, tex_tr.size}, tex_tr)
    draw_texture(tex_atlas, {rect.pos + {0, rect.size.y - tex_bl.size.y}, tex_bl.size}, tex_bl)
    draw_texture(tex_atlas, {rect.pos + rect.size - tex_br.size, tex_br.size}, tex_br)

    // top border
    top_rect := Rect{
        rect.pos + {tex_tl.size.x, 0},
        {rect.size.x - tex_tl.size.x - tex_tr.size.x, tex_t.size.y},
    }
    if top_rect.size.x > 0 {
        draw_texture(tex_atlas, top_rect, tex_t)
    }

    // bottom border
    bottom_rect := Rect{
        rect.pos + {tex_bl.size.x, rect.size.y - tex_b.size.y},
        {rect.size.x - tex_bl.size.x - tex_br.size.x, tex_b.size.y},
    }
    if bottom_rect.size.x > 0 {
        draw_texture(tex_atlas, bottom_rect, tex_b)
    }

    // left border
    left_rect := Rect{
        rect.pos + {0, tex_tl.size.y},
        {tex_l.size.x, rect.size.y - tex_tl.size.y - tex_bl.size.y},
    }
    if left_rect.size.y > 0 {
        draw_texture(tex_atlas, left_rect, tex_l)
    }

    // right border
    right_rect := Rect{
        rect.pos + {rect.size.x - tex_r.size.x, tex_tr.size.y},
        {tex_l.size.x, rect.size.y - tex_tr.size.y - tex_br.size.y},
    }
    if right_rect.size.y > 0 {
        draw_texture(tex_atlas, right_rect, tex_r)
    }
}

menu_frame :: proc () {
    if !should_display_menu do return

    UI_PIXEL_SCALE :: 6.0
    camera := k2.Camera{zoom = UI_PIXEL_SCALE}
    k2.set_camera(camera)
    defer k2.set_camera(nil)

    mouse_world := k2.screen_to_world(mouse_pos, camera)
    ui_world_size := window_size / UI_PIXEL_SCALE

    // automatic
    for side in Army_Side {
        enabled := is_automatic(side)

        tex_rect := atlas_rects[.Automatic_On if enabled else .Automatic_Off]

        MARGIN  :: 10
        PADDING :: 4

        button_rect: Rect = {{MARGIN, ui_world_size.y - 60}, tex_rect.size + PADDING*2}
        button_rect.pos.y -= button_rect.size.y
        if side == .Enemy {
            button_rect.pos.x = ui_world_size.x - button_rect.size.x - button_rect.pos.x
        }
        draw_border(button_rect)

        if point_in_rect(mouse_world, button_rect) && k2.mouse_button_went_down(.Left) {
            automatic[side] = !enabled
        }

        draw_texture(
            tex_atlas,
            {button_rect.pos + PADDING, button_rect.size - PADDING*2},
            atlas_rects[.Automatic_On if enabled else .Automatic_Off],
        )
    }

    // balance
    {
        MARGIN :: 10
        H :: 20
        slider_rect: Rect = {
            {MARGIN, ui_world_size.y - MARGIN - H},
            {ui_world_size.x - MARGIN*2, H},
        }

        if point_in_rect(mouse_world, slider_rect) && k2.mouse_button_went_down(.Left) {
            slider_dragging = true
        }

        if slider_dragging {

            // 1. clamps the value to min_v and max_v
            // 2. rounds the value to number of steps—discrete positions
            //
            // example:
            //
            //     stepped_range_value(value, 0, 1, 7) // 0, 1/6, 1/3, ..., 1
            stepped_range_value :: proc(value, min_v, max_v: f32, steps: int) -> f32 {
                if steps <= 1 {
                    return min_v
                }

                step_size := (max_v - min_v) / f32(steps - 1)
                i := math.round((value - min_v) / step_size)
                return clamp(min_v + i * step_size, min_v, max_v)
            }

            new_value := (mouse_world.x - slider_rect.pos.x) / slider_rect.size.x
            new_value = stepped_range_value(new_value, 0.3, 0.7, 7)

            if new_value != slider_value {
                slider_value = new_value
                game_initalized = false
            }
        }

        if slider_dragging && k2.mouse_button_went_up(.Left) {
            slider_dragging = false
        }

        draw_border(slider_rect)
        k2.draw_rect_vec(slider_rect.pos, {slider_rect.size.x * slider_value, slider_rect.size.y}, k2.GREEN)
    }

    {
        size: Vec2 = {60, 40}
        rect: Rect = {
            ui_world_size/2 - size/2,
            size,
        }

        if point_in_rect(mouse_world, rect) && k2.mouse_button_went_down(.Left) {
            should_display_menu = false
        }

        k2.draw_rect_vec(rect.pos, rect.size, k2.GREEN)
    }

    if k2.key_went_down(.Enter) {
        should_display_menu = false
    }
}

