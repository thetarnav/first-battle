package first_battle

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import k2 "./karl2d"
import qt "./quadtree"
import color "./color"
import "base:runtime"

Vec2  :: k2.Vec2
Color :: k2.Color

draw_cross :: proc (pos: Vec2, color: Color) {
    k2.draw_line(pos - {20, 0}, pos + {20, 0}, 3, color)
    k2.draw_line(pos - {0, 20}, pos + {0, 20}, 3, color)
}

Army_Side :: enum {Player, Enemy}

side_opposite :: proc (side: Army_Side) -> Army_Side {
    return Army_Side((int(side)+1) % (int(max(Army_Side))+1))
}

Army :: struct {
    side:     Army_Side,
    name:     string,
    color:    Color,
    soldiers: []Soldier_Idx,
    target:   union {vec2},
}

Soldier :: struct {
    idx:    Soldier_Idx,
    side:   Army_Side,
    pos:    Vec2,
    cell:   Maybe(int),
    target: union {Vec2},
}
Soldier_Idx :: distinct u16
Soldier_Arr :: #soa[dynamic]Soldier
Soldier_Ptr :: #soa^Soldier_Arr

armies: [Army_Side]Army = {
    .Player = {side=.Player, name="Player", color=k2.ORANGE},
    .Enemy  = {side=.Enemy,  name="Enemy",  color=k2.RED},
}
army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

soldiers: Soldier_Arr

selected_soldier: Maybe(Soldier_Idx)

Cell :: struct {
    soldier: Maybe(Soldier_Idx),
}

grid: [GRID_N]Cell

// updated every fame
window_size: Vec2
grid_rect:   Rect

GOLDEN_RATIO  :: 1.618

GRID_X           :: 128
GRID_Y           :: 100
GRID_N           :: GRID_X*GRID_Y
GRID_SIZE        :: Vec2{GRID_X, GRID_Y}
GRID_AR          :: f32(GRID_X)/f32(GRID_Y)
GRID_RECT_MARGIN :: 10

UNIT_W :: 4
UNIT_M :: 3
UNIT_S :: UNIT_W + UNIT_M*2

screen_pos_to_world :: proc (pos: Vec2) -> Vec2 {
    return (pos - grid_rect.pos)/grid_rect.size * GRID_SIZE
}
world_pos_from_screen :: screen_pos_to_world
world_pos_to_screen :: proc (pos: Vec2) -> Vec2 {
    return grid_rect.pos + pos * (grid_rect.size/GRID_SIZE)
}
screen_pos_from_world :: world_pos_to_screen

get_grid_rect :: proc () -> (rect: Rect) {
    max := window_size - GRID_RECT_MARGIN*2
    rect.size = max
    rect.size.x = min(rect.size.x, rect.size.y * GRID_AR)
    rect.size.y = min(rect.size.y, rect.size.x / GRID_AR)
    rect.pos = GRID_RECT_MARGIN + (max - rect.size)/2
    return
}

grid_idx_from_coord :: proc (coord: [2]int, loc := #caller_location) -> int {
    runtime.bounds_check_error_loc(loc, coord.x, GRID_X)
    runtime.bounds_check_error_loc(loc, coord.y, GRID_Y)
    return coord.x + coord.y*GRID_X
}
grid_idx_from_coord_safe :: proc (coord: [2]int) -> (idx: int, ok: bool) {
    return coord.x + coord.y*GRID_X,
        coord.x >= 0 && coord.y >= 0 && coord.x < GRID_X && coord.y < GRID_Y
}
grid_coord_from_idx :: proc (idx: int) -> (coord: [2]int) {
    return {idx%GRID_X, idx/GRID_X}
}
grid_idx_from_pos :: proc (pos: Vec2) -> (idx: int, ok: bool) {
    return grid_idx_from_coord_safe(([2]int)(pos))
}
grid_cell_from_pos :: proc (pos: Vec2) -> (cell: ^Cell, ok: bool) {
    return &grid[grid_idx_from_pos(pos) or_return], true
}
grid_cell_get :: proc (idx: int, loc := #caller_location) -> (cell: Cell) #no_bounds_check {
    runtime.bounds_check_error_loc(loc, idx, len(grid))
    return grid[idx]
}
grid_cell_get_safe :: proc (idx: int) -> (cell: Cell, ok: bool) {
    if in_bounds(grid, idx) {
        return grid[idx], true
    }
    return
}
cell_center :: proc (idx: int) -> (pos: Vec2) {
    return Vec2(grid_coord_from_idx(idx)) + Vec2(0.5)
}

soldier_get :: proc (idx: Soldier_Idx) -> Soldier_Ptr {
    return &soldiers[idx]
}

army_count_dim :: proc (n: int) -> (res: [2]int) {
    res.y = int(math.sqrt(f32(n)/GOLDEN_RATIO))
    res.x = n/res.y
    return
}

each_army_goal_pos :: proc (origin: Vec2, rot: f32, i, n: int) -> (p: Vec2) {
    dim := army_count_dim(n)
    p = Vec2{f32(i%dim.x), f32(i/dim.x)} * 2
    p = vec2_rotate_angle(p, rot)
    p += origin
    p = la.floor(p)
    p += 0.5
    return
}

soldier_add_to_cell :: proc (s: Soldier_Ptr, cell_idx: int) -> (ok: bool) {

    if !in_bounds(grid, cell_idx) do return
    cell := &grid[cell_idx]

    prev_soldier, has_prev_soldier := cell.soldier.?
    if has_prev_soldier && prev_soldier != s.idx do return

    if prev_idx, has_prev_idx := s.cell.?; has_prev_idx {
        grid[prev_idx].soldier = nil
    }

    cell.soldier = s.idx
    s.cell = cell_idx

    return true
}
soldier_set_pos :: proc (s: Soldier_Ptr, pos: Vec2) -> (ok: bool) {
    cell_idx := grid_idx_from_pos(pos) or_return
    soldier_add_to_cell(s, cell_idx) or_return
    s.pos = pos
    return true
}
soldier_set_pos_force :: proc (s: Soldier_Ptr, pos: Vec2) {

    cell_idx, pos_in_grid := grid_idx_from_pos(pos)

    // pos outside of the grid - pick any cell
    if !pos_in_grid {
        fmt.printfln("tried to set position outside of the grid: %v", pos)
        if s.cell != nil do return
        // add to any cell
        for cell, cell_idx in grid {
            if soldier_add_to_cell(s, cell_idx) {
                s.pos = cell_center(cell_idx)
                return
            }
        }
        fmt.printfln("No cells left")
    }

    // try adding to the cell on pos
    if soldier_add_to_cell(s, cell_idx) {
        s.pos = pos
        return
    }

    // if taken, try adding to surrounding cells until found a spot
    origin := ([2]int)(pos)
    coord: [2]int
    for {
        coord = next_surrounding_cell(coord)
        cell_idx = grid_idx_from_coord(origin + coord)

        if soldier_add_to_cell(s, cell_idx) {
            s.pos = cell_center(cell_idx)
            return
        }
    }
}

@require_results
next_surrounding_cell :: proc "contextless" (p: [2]int) -> [2]int {

    l := max(abs(p.x), abs(p.y))
    f := abs(abs(p.x) - abs(p.y))
    d := l-f

    switch p {
    case { d,  l}: return {-l, -d-1} if f > 0 else {-l-1, 0}
    case { d, -l}: return { d,  l}
    case {-d,  l}: return { d, -l}
    case {-d, -l}: return {-d,  l}
    case { l,  d}: return {-d, -l}
    case { l, -d}: return { l,  d}
    case {-l,  d}: return { l, -d}
    case {-l, -d}: return {-l,  d}
    }

    unreachable()
}

game_init :: proc () {

    update_frame_globals()

    soldiers = make(type_of(soldiers), 0, 10000, allocator=context.allocator)

    army_pos  := [2]f32{10, 20}
    army_size := 500

    army := army_player

    army.soldiers = make([]Soldier_Idx, army_size, allocator=context.allocator)

    for i in 0..<army_size {

        si := Soldier_Idx(len(soldiers))
        army.soldiers[i] = si
        append_nothing_soa(&soldiers)

        s := soldier_get(si)
        s.idx = si
        pos := each_army_goal_pos(army_pos + Vec2(0.5), -0.2, i, army_size)

        soldier_set_pos_force(s, pos)
    }
}

update_frame_globals :: proc () {
    window_size = k2.get_screen_size()
    grid_rect   = get_grid_rect()
}

update :: proc (dt: f32) -> bool {

    update_frame_globals()

    mouse_pos := k2.get_mouse_position()
    mouse_world := world_pos_from_screen(mouse_pos)

    selected_soldier = nil
    check_mouse_hover: {
        cell_idx := grid_idx_from_pos(mouse_world) or_break check_mouse_hover
        coord: [2]int
        origin := grid_coord_from_idx(cell_idx)
        r := 2
        d := r*2
        w := d+1
        steps := w*w - 4
        for _ in 0..<steps {
            defer coord = next_surrounding_cell(coord)

            cell_idx = grid_idx_from_coord_safe(origin + coord) or_continue
            cell := grid_cell_get(cell_idx)
            si := cell.soldier.? or_continue

            selected_soldier = si
            break
        }
    }

    check_click: if k2.mouse_button_is_held(.Left) {

        // ignore clicks outside of the grid
        _ = grid_idx_from_pos(mouse_world) or_break check_click

        army_player.target = mouse_world

        for si, i in army_player.soldiers {
            s := soldier_get(si)
            pos := each_army_goal_pos(mouse_world, -0.2, i, len(army_player.soldiers))
            coord: [2]int
            origin := ([2]int)(pos)
            for {
                defer coord = next_surrounding_cell(coord)

                cell_idx := grid_idx_from_coord_safe(origin + coord) or_continue

                s.target = cell_center(cell_idx)
                break
            }
        }
    }

    move_soldiers: {
        for army in armies {
            for si in army.soldiers {
                s := soldier_get(si)
                if target, ok := s.target.(vec2); ok {
                    d := la.normalize(target - s.pos) * dt * 0.02
                    n := s.pos + d
                    if !math.is_nan(n.x) &&
                       !math.is_nan(n.y) &&
                       !math.is_inf(n.x) &&
                       !math.is_inf(n.y) {
                        soldier_set_pos(s, n)
                    }
                }
            }
        }
    }

    if k2.key_went_down(.Q) {
        return false
    }
    return true
}

frame :: proc (dt: f32) -> bool {

    k2.clear({12, 10, 9, 255})

    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)

    wc := window_size/2

    draw_cross(wc, k2.DARK_GRAY)

    {
        for xi in 0..=GRID_X {
            xp := f32(xi)/GRID_X
            x  := grid_rect.size.x * xp
            s  := grid_rect.pos + {x, 0}
            e  := grid_rect.pos + {x, grid_rect.size.y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
        for yi in 0..=GRID_Y {
            yp := f32(yi)/GRID_Y
            y  := grid_rect.size.y * yp
            s  := grid_rect.pos + {0, y}
            e  := grid_rect.pos + {grid_rect.size.x, y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
    }

    for s, i in soldiers {
        si := Soldier_Idx(i)

        color := army_player.color
        size := f32(UNIT_W)
        // color := army.color
        // if is_dead(s) {
        //     color = k2.DARK_GRAY
        // }
        pos := world_pos_to_screen(s.pos)
        if selected_soldier == si {
            color = k2.BLUE
            size *= 2
        }
        k2.draw_circle(pos, size, color)
    }

    mouse_pos := k2.get_mouse_position()
    draw_cross(mouse_pos, k2.GREEN)

    p: [2]int
    N :: 1000
    for i in 0..<N {
        p = next_surrounding_cell(p)
        c1 := color.FRGB{1, 1, 0}
        c2 := color.FRGB{1, 0, 0}
        c3 := color.FRGB{1, 0, 1}
        c: color.FRGB
        cp := f32(i)*2/N
        if cp < 1 {
            c = color.lerp(c1, c2, cp)
        } else {
            c = color.lerp(c2, c3, cp-1)
        }
        k2.draw_circle(grid_rect.pos + Vec2(p + {40, 40}) * (grid_rect.size/GRID_SIZE), 3, k2.Color(color.urgba(c)))
    }

    return true
}

