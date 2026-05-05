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

armies: [Army_Side]Army = {
    .Player = {side=.Player, name="Player", color=k2.GREEN},
    .Enemy  = {side=.Enemy,  name="Enemy",  color=k2.RED},
}
army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

soldiers: #soa[dynamic]Soldier

GOLDEN_RATIO  :: 1.618

GRID_SIZE        :: 128
GRID_RECT_MARGIN :: 10

UNIT_W :: 4
UNIT_M :: 3
UNIT_S :: UNIT_W + UNIT_M*2

get_grid_rect :: proc () -> Rect {
    ws := k2.get_screen_size()
    rect := Rect{GRID_RECT_MARGIN, min(ws.x, ws.y) - GRID_RECT_MARGIN*2}
    rect.pos += (ws - GRID_RECT_MARGIN*2 - rect.size)/2
    return rect
}

soldier_get :: proc (idx: Soldier_Idx) -> #soa^#soa[dynamic]Soldier {
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
    }
}

update :: proc (dt: f32) -> bool {
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
        for xi in 0..=GRID_SIZE {
            xp := f32(xi)/GRID_SIZE
            x  := grid_rect.size.x * xp
            s  := grid_rect.pos + {x, 0}
            e  := grid_rect.pos + {x, grid_rect.size.y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
        for yi in 0..=GRID_SIZE {
            yp := f32(yi)/GRID_SIZE
            y  := grid_rect.size.y * yp
            s  := grid_rect.pos + {0, y}
            e  := grid_rect.pos + {grid_rect.size.x, y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
    }

    for s in soldiers {

        color := army_player.color
        // color := army.color
        // if is_dead(s) {
        //     color = k2.DARK_GRAY
        // }
        pos := s.pos * (grid_rect.size/GRID_SIZE)
        pos += grid_rect.pos
        k2.draw_circle(pos, UNIT_W/2, color)
    }

    return true
}

