package first_battle

import "core:math"
import "core:fmt"
import k2 "./karl2d"


should_display_menu: bool = true

slider_value: f32 = 0.5
slider_dragging: bool = false

menu_frame :: proc () {
    if !should_display_menu do return

    UI_WORLD_SIZE :: Vec2{1000, 1000}
    camera := k2_camera_fit_aspect(UI_WORLD_SIZE, 10)
    k2.set_camera(camera)

    mouse_world := k2.screen_to_world(mouse_pos, camera)

    k2.draw_rect_vec(
        {0, UI_WORLD_SIZE.y} - {0, 60},
        {100, 40},
        k2.ORANGE,
    )

    {
        p: Vec2 = {0, UI_WORLD_SIZE.y} - {0, 60}
        r: Rect = {p, 40}

        hovers := point_in_rect(mouse_world, r)

        if hovers && k2.mouse_button_went_down(.Left) {
            fmt.println("Hello")
        }

        draw_texture(
            tex_atlas,
            r,
            atlas_rects[.Automatic_On if hovers else .Automatic_Off],
        )
    }

    {
        slider_rect: Rect = {
            {10, UI_WORLD_SIZE.y - 10},
            {UI_WORLD_SIZE.x - 20, 20},
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

        k2.draw_rect_vec(slider_rect.pos, slider_rect.size, k2.RED)
        k2.draw_rect_vec(slider_rect.pos, {slider_rect.size.x * slider_value, slider_rect.size.y}, k2.GREEN)
    }

    {
        size: Vec2 = {60, 40}
        rect: Rect = {
            UI_WORLD_SIZE/2 - size/2,
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

