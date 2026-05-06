package first_battle

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import k2 "./karl2d"
import qt "./quadtree"

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
    idx:   Soldier_Idx,
    side:  Army_Side,
    pos:   Vec2,
    cell:  Maybe(int),
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

get_grid_rect :: proc () -> (rect: Rect) {
    max := window_size - GRID_RECT_MARGIN*2
    rect.size = max
    rect.size.x = min(rect.size.x, rect.size.y * GRID_AR)
    rect.size.y = min(rect.size.y, rect.size.x / GRID_AR)
    rect.pos = GRID_RECT_MARGIN + (max - rect.size)/2
    return
}

grid_idx_from_pos :: proc (pos: Vec2) -> (idx: int, ok: bool) {
    if pos.x < 0 ||
       pos.y < 0 ||
       pos.x >= grid_rect.size.x ||
       pos.y >= grid_rect.size.y {
        return 0, false
    }
    return int(pos.x) + int(pos.y)*GRID_X, true
}
grid_cell_from_pos :: proc (pos: Vec2) -> (cell: ^Cell, ok: bool) {
    return &grid[grid_idx_from_pos(pos) or_return], true
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

    prev_idx, has_prev_idx := s.cell.?
    if has_prev_idx {
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

    cell_idx, pos_in_cell := grid_idx_from_pos(pos)
    if !pos_in_cell {
        fmt.printfln("tried to set position outside of the grid: %v", pos)
        if s.cell != nil do return
        // add to any cell
        for cell, cell_idx in grid {
            if soldier_add_to_cell(s, cell_idx) {
                return
            }
        }
        fmt.printfln("No cells left")
    }

    for {
        if soldier_add_to_cell(s, cell_idx) {
            return
        }


    }
}

next_surrounding_cell :: proc (p: [2]int) -> [2]int {

    l := max(abs(p.x), abs(p.y))
    f := abs(abs(p.x) - abs(p.y))
    d := l-f

    s: int
    switch p {
    case { d,  l}: s = 7
    case { d, -l}: s = 6
    case {-d,  l}: s = 5
    case {-d, -l}: s = 4
    case { l,  d}: s = 3
    case { l, -d}: s = 2
    case {-l,  d}: s = 1
    case {-l, -d}: s = 0
    }

    if s == 7 || p == 0 {
        s = 0
        if f == 0 {
            l += 1
            f = l
        } else {
            f -= 1
        }
    } else {
        s += 1
    }

    d = l-f

    p := p
    switch s {
    case 7: p = { d,  l}
    case 6: p = { d, -l}
    case 5: p = {-d,  l}
    case 4: p = {-d, -l}
    case 3: p = { l,  d}
    case 2: p = { l, -d}
    case 1: p = {-l,  d}
    case 0: p = {-l, -d}
    }

    return p
}

game_init :: proc () {

    update(0) // set initial globals

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

    p: [2]int
    for i in 0..<52 {
        p = next_surrounding_cell(p)
        fmt.println(p)
    }
}

update :: proc (dt: f32) -> bool {

    window_size = k2.get_screen_size()
    grid_rect   = get_grid_rect()

    mouse_pos := k2.get_mouse_position()
    mouse_world := world_pos_from_screen(mouse_pos)

    selected_soldier = nil
    check_mouse_hover: {
        cell := grid_cell_from_pos(mouse_world) or_break check_mouse_hover
        if si, ok := cell.soldier.?; ok {
            selected_soldier = si
        }
    }

    check_click: if k2.mouse_button_is_held(.Left) {
        army_player.target = mouse_world
    }

    move_soldiers: {
        for army in armies {
            for si in army.soldiers {
                s := soldier_get(si)
                if target, ok := army.target.(vec2); ok {
                    s.pos = exp_decay(s.pos, target, 0.00000001, dt)
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
        pos := s.pos * (grid_rect.size/GRID_SIZE)
        pos += grid_rect.pos
        if selected_soldier == si {
            color = k2.BLUE
            size *= 2
        }
        k2.draw_circle(pos, size, color)
    }

    mouse_pos := k2.get_mouse_position()
    draw_cross(mouse_pos, k2.GREEN)

    p: [2]int
    for i in 0..<164 {
        p = next_surrounding_cell(p)
        k2.draw_circle(grid_rect.pos + Vec2(p + {40, 40}) * (grid_rect.size/GRID_SIZE), 3, k2.GREEN)
    }

    return true
}

