package first_battle

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
            slider_value = clamp((mouse_world.x - slider_rect.pos.x) / slider_rect.size.x, 0, 1)
        }

        if slider_dragging && k2.mouse_button_went_up(.Left) {
            slider_dragging = false
        }

        k2.draw_rect_vec(slider_rect.pos, slider_rect.size, k2.RED)
        k2.draw_rect_vec(slider_rect.pos, {slider_rect.size.x * slider_value, slider_rect.size.y}, k2.GREEN)
    }

}

