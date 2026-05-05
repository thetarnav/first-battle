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
}

Soldier :: struct {
    side: Army_Side,
    pos:  Vec2,
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
    rect := get_grid_rect()
    pos := pos
    pos -= rect.pos
    pos = pos/rect.size * GRID_SIZE
    return pos
}
world_pos_from_screen :: screen_pos_to_world

get_grid_rect :: proc () -> (rect: Rect) {
    max := k2.get_screen_size() - GRID_RECT_MARGIN*2
    rect.size = max
    rect.size.x = min(rect.size.x, rect.size.y * GRID_AR)
    rect.size.y = min(rect.size.y, rect.size.x / GRID_AR)
    rect.pos = GRID_RECT_MARGIN + (max - rect.size)/2
    return
}

grid_idx_from_pos :: proc (pos: Vec2) -> (idx: int, ok: bool) {
    rect := get_grid_rect()
    if pos.x < 0 ||
       pos.y < 0 ||
       pos.x > rect.size.x ||
       pos.y > rect.size.y {
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

game_init :: proc () {

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
        s.pos = each_army_goal_pos(army_pos + Vec2(0.5), -0.2, i, army_size)

        cell := grid_cell_from_pos(s.pos) or_continue
        cell.soldier = si // TODO: collision checks
    }
}

update :: proc (dt: f32) -> bool {

    mouse_pos := k2.get_mouse_position()

    selected_soldier = nil
    check_mouse: if true || k2.mouse_button_is_held(.Left) {
        mouse_world := world_pos_from_screen(mouse_pos)
        cell := grid_cell_from_pos(mouse_world) or_break check_mouse
        if si, ok := cell.soldier.?; ok {
            selected_soldier = si
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

    ws := k2.get_screen_size()
    wc := ws/2

    draw_cross(wc, k2.DARK_GRAY)

    grid_rect := get_grid_rect()
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

    return true
}

