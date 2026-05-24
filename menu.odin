package first_battle

import "core:fmt"
import k2 "./karl2d"


should_display_menu: bool = true

menu_frame :: proc () {
    if !should_display_menu do return

    UI_WORLD_SIZE :: Vec2{1000, 1000}
    camera := k2_camera_fit_aspect(UI_WORLD_SIZE, 10)
    k2.set_camera(camera)

    k2.draw_rect_vec(
        {0, UI_WORLD_SIZE.y} - {0, 60},
        {100, 40},
        k2.ORANGE,
    )

    p: Vec2 = {0, UI_WORLD_SIZE.y} - {0, 60}
    r: Rect = {p, 40}

    mouse_world := k2.screen_to_world(mouse_pos, camera)
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

