package first_battle

import "core:math"
import la "core:math/linalg"
import k2 "./karl2d"

ui_view:         UI_View
slider_dragging: bool
camera_ui:       k2.Camera
ui_mouse:        Vec2
ui_world_size:   Vec2
ui_center:       Vec2

UI_View :: enum {
    Main_Menu,
    Game,
    End,
}

UI_PIXEL_SCALE :: 4.0

ui_frame :: proc () {

    // debug ui
    draw_cross(mouse_pos, k2.GREEN)
    draw_cross(window_size/2, k2.GRAY)

    // cover
    if ui_view != .Game {
        k2.draw_rect_vec(0, k2.get_screen_size(), {expand_values(COLOR_BOARD.rgb), 120})
    }

    camera_ui = k2.Camera{zoom = UI_PIXEL_SCALE}
    k2.set_camera(camera_ui)
    defer k2.set_camera(nil)

    ui_mouse      = k2.screen_to_camera(mouse_pos, camera_ui)
    ui_world_size = la.floor(window_size / UI_PIXEL_SCALE)
    ui_center     = ui_world_size/2

    // board border
    draw_border({board_rect.pos / UI_PIXEL_SCALE, board_rect.size / UI_PIXEL_SCALE}, 0)

    switch ui_view {
    case .Main_Menu: draw_menu_ui()
    case .End:       draw_end_ui()
    case .Game:
    }
}

draw_menu_ui :: proc () {

    // Play button
    play_tex_rect := atlas_rects[.Play]
    play_text_rect: Rect = {
        {ui_center.x - play_tex_rect.size.x/2, ui_center.y},
        play_tex_rect.size,
    }
    play_text_rect.y -= play_text_rect.size.y/2
    play_rect := rect_extend(play_text_rect, {5, 3})

    if point_in_rect(ui_mouse, play_text_rect) && k2.mouse_button_went_down(.Left) {
        ui_view = .Game
    }

    draw_border(play_rect)
    draw_texture(tex_atlas, play_text_rect, play_tex_rect)

    // Title
    title_tex_rect := atlas_rects[.Title]
    title_rect: Rect = {
        {ui_center.x - title_tex_rect.size.x/2, play_rect.pos.y - title_tex_rect.size.y - 12},
        title_tex_rect.size,
    }

    draw_texture(tex_atlas, title_rect, title_tex_rect)

    // automatic
    for side in Army_Side {
        enabled := is_automatic(side)

        tex_slice: Atlas_Slice
        switch side {
        case .Player: tex_slice = .Automatic_On_Player if enabled else .Automatic_Off_Player
        case .Enemy:  tex_slice = .Automatic_On_Enemy  if enabled else .Automatic_Off_Enemy
        }
        tex_rect := atlas_rects[tex_slice]

        PADDING :: 2

        button_rect: Rect = {
            {play_rect.pos.x - tex_rect.size.x - 16, ui_center.y},
            tex_rect.size + PADDING*2,
        }
        button_rect.pos.y -= button_rect.size.y/2
        if side == .Enemy {
            button_rect.pos.x = ui_center.x - (button_rect.pos.x + button_rect.size.x - ui_center.x)
        }
        draw_border(button_rect)

        if point_in_rect(ui_mouse, button_rect) && k2.mouse_button_went_down(.Left) {
            automatic[side] = !enabled
        }

        draw_texture(tex_atlas, {button_rect.pos + PADDING, button_rect.size - PADDING*2}, tex_rect)
    }

    // balance
    slider_size := Vec2{128, 12}

    slider_rect: Rect = {
        {ui_center.x - slider_size.x/2, play_rect.pos.y + play_rect.size.y + 14},
        slider_size,
    }

    if point_in_rect(ui_mouse, slider_rect) && k2.mouse_button_went_down(.Left) {
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

        new_value := (ui_mouse.x - slider_rect.pos.x) / slider_rect.size.x
        new_value = stepped_range_value(new_value, 0.3, 0.7, 7)

        if new_value != armies_ratio {
            armies_ratio = new_value
            game_initalized = false
        }
    }

    if slider_dragging && k2.mouse_button_went_up(.Left) {
        slider_dragging = false
    }

    slider_bg := COLOR_UI
    if point_in_rect(ui_mouse, slider_rect) {
        slider_bg = COLOR_UI_HOVER
    }
    k2.draw_rect_vec(slider_rect.pos, slider_rect.size, slider_bg)
    k2.draw_rect_vec(slider_rect.pos, {slider_rect.size.x * armies_ratio, slider_rect.size.y}, COLOR_PLAYER_LIGHT)
    k2.draw_rect_vec(slider_rect.pos + {armies_ratio * slider_rect.size.x - 1, 0}, {2, slider_rect.size.y}, COLOR_PLAYER_DARK)
    draw_border(slider_rect, 0)

    // mute sounds
    {
        tex_rect := atlas_rects[.Sound_Off if g_mute else .Sound_On]

        PADDING :: 2

        mute_rect: Rect
        mute_rect.size = tex_rect.size + PADDING*2
        mute_rect.pos.x = ui_center.x - mute_rect.size.x/2
        mute_rect.pos.y = slider_rect.y + slider_rect.size.y + 14

        draw_border(mute_rect)

        if point_in_rect(ui_mouse, mute_rect) && k2.mouse_button_went_down(.Left) {
            audio_toggle_mute()
        }

        draw_texture(tex_atlas, {mute_rect.pos + PADDING, mute_rect.size - PADDING*2}, tex_rect)
    }

    if k2.key_went_down(.Enter) {
        ui_view = .Game
    }
}

draw_end_ui :: proc () {

    // Play button
    play_tex_rect := atlas_rects[.Reset]
    play_text_rect: Rect = {
        {ui_center.x - play_tex_rect.size.x/2, ui_center.y + 20},
        play_tex_rect.size,
    }
    play_text_rect.y -= play_text_rect.size.y/2
    play_rect := rect_extend(play_text_rect, {5, 3})

    if point_in_rect(ui_mouse, play_text_rect) && k2.mouse_button_went_down(.Left) {
        ui_view = .Main_Menu
        game_initalized = false
    }

    draw_border(play_rect)
    draw_texture(tex_atlas, play_text_rect, play_tex_rect)

    // Winner image
    winner := check_winner()

    win_tex_rect: Rect
    switch winner.? {
    case .Player: win_tex_rect = atlas_rects[.Win_Player]
    case .Enemy:  win_tex_rect = atlas_rects[.Win_Enemy]
    }

    win_rect: Rect = {
        {ui_center.x - win_tex_rect.size.x/2, ui_center.y - win_tex_rect.size.y},
        win_tex_rect.size,
    }

    draw_texture(tex_atlas, win_rect, win_tex_rect)

}

draw_border :: proc (rect: Rect, bg: Color = COLOR_UI) {

    rect := rect
    rect = rect_extend(rect, 2)

    tex_tl := atlas_rects[.Border_TL]
    tex_tr := atlas_rects[.Border_TR]
    tex_bl := atlas_rects[.Border_BL]
    tex_br := atlas_rects[.Border_BR]
    tex_t  := atlas_rects[.Border_T]
    tex_b  := atlas_rects[.Border_B]
    tex_l  := atlas_rects[.Border_L]
    tex_r  := atlas_rects[.Border_R]

    // fill background
    if bg.a > 0 {
        bg_rect := Rect{rect.pos + tex_tl.size, rect.size - tex_tl.size - tex_br.size}
        bg_rect = rect_extend(bg_rect, 4)

        bg := bg
        if point_in_rect(ui_mouse, rect) {
            bg = COLOR_UI_HOVER
        }
        k2.draw_rect_vec(bg_rect.pos, bg_rect.size, bg)
    }

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
