package first_battle

import "base:runtime"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import k2 "./karl2d"
import "./color"
import "./grid"
import astar "./grid/path"

Vec2  :: k2.Vec2
Color :: k2.Color
Coord :: grid.Coord

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
    units:    []Company,
}

Company :: struct {
    name:     string,
    units:    []Troop_Idx,
    // target:   union {vec2},
}
Company_Idx :: distinct u16

Company_Handle :: struct {
    side: Army_Side,
    idx:  Company_Idx,
}

Troop :: struct {
    side:     Army_Side,
    si:       Troop_Idx,
    ci:       Company_Idx,
    pos:      Vec2,
    cell:     Maybe(Cell_Idx),
    target:   union {Cell_Idx},
}
Troop_Idx :: distinct u16
Troop_Arr :: #soa[dynamic]Troop
Troop_Ptr :: #soa^Troop_Arr

Cell :: struct {
    troop: Maybe(Troop_Idx),
}
Cell_Idx :: distinct u16

armies: [Army_Side]Army = {
    .Player = {side=.Player, name="Player", color=k2.ORANGE},
    .Enemy  = {side=.Enemy,  name="Enemy",  color=k2.RED},
}
army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

initial_army_units: [Army_Side][]struct {name: string, pos: Coord, rot: f32, count: int} = {
    .Player = {
        {"one", {30, 40}, -0.2, 200},
        {"two", {80, 60},  0.2, 120},
    },
    .Enemy  = {},
}

troops: Troop_Arr

hovered_troop: Maybe(Troop_Idx)
selected_company: Maybe(Company_Handle)

board: grid.Grid(Cell)

// updated every fame
window_size: Vec2
board_rect:  Rect

GOLDEN_RATIO  :: 1.618

BOARD_X           :: 128
BOARD_Y           :: 100
BOARD_N           :: BOARD_X*BOARD_Y
BOARD_SIZE        :: Vec2{BOARD_X, BOARD_Y}
BOARD_AR          :: f32(BOARD_X)/f32(BOARD_Y)
BOARD_RECT_MARGIN :: 10

troop_W :: 4
troop_M :: 3
troop_S :: troop_W + troop_M*2

screen_pos_to_world :: proc (pos: Vec2) -> Vec2 {
    return (pos - board_rect.pos)/board_rect.size * BOARD_SIZE
}
world_pos_from_screen :: screen_pos_to_world
world_pos_to_screen :: proc (pos: Vec2) -> Vec2 {
    return board_rect.pos + pos * (board_rect.size/BOARD_SIZE)
}
screen_pos_from_world :: world_pos_to_screen

get_board_rect :: proc () -> (rect: Rect) {
    max := window_size - BOARD_RECT_MARGIN*2
    rect.size = max
    rect.size.x = min(rect.size.x, rect.size.y * BOARD_AR)
    rect.size.y = min(rect.size.y, rect.size.x / BOARD_AR)
    rect.pos = BOARD_RECT_MARGIN + (max - rect.size)/2
    return
}

board_coord_from_pos :: proc (pos: Vec2) -> (coord: Coord, ok: bool) {
    return Coord(pos), grid.inside(board, Coord(pos))
}
grid_idx_from_pos :: proc (pos: Vec2) -> (idx: Cell_Idx, ok: bool) {
    c := Coord(pos)
    return Cell_Idx(grid.idx(board, c)), grid.inside(board, c)
}
grid_cell_from_pos :: proc (pos: Vec2) -> (cell: ^Cell, ok: bool) {
    return grid.ptr_safe(&board, Coord(pos))
}
cell_center :: proc (idx: Cell_Idx) -> (pos: Vec2) {
    return Vec2(grid.coord(board, idx)) + Vec2(0.5)
}

troop_get :: proc (idx: Troop_Idx) -> Troop_Ptr {
    return &troops[idx]
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

troop_add_to_cell :: proc (s: Troop_Ptr, cell_idx: Cell_Idx) -> (ok: bool) {

    cell := grid.ptr_idx_safe(&board, cell_idx) or_return

    prev_troop, has_prev_troop := cell.troop.?
    if has_prev_troop && prev_troop != s.si do return

    if prev_idx, has_prev_idx := s.cell.?; has_prev_idx {
        prev := grid.ptr_idx(&board, prev_idx)
        prev.troop = nil
    }

    cell.troop = s.si
    s.cell = cell_idx

    return true
}
troop_set_pos :: proc (s: Troop_Ptr, pos: Vec2) -> (ok: bool) {
    cell_idx := grid_idx_from_pos(pos) or_return
    troop_add_to_cell(s, cell_idx) or_return
    s.pos = pos
    return true
}
troop_set_pos_force :: proc (s: Troop_Ptr, pos: Vec2) {

    cell_idx, pos_in_grid := grid_idx_from_pos(pos)

    // pos outside of the grid - pick any cell
    if !pos_in_grid {
        fmt.printfln("tried to set position outside of the grid: %v", pos)
        if s.cell != nil do return
        // add to any cell
        for cell, cell_idx in grid.slice(&board) {
            if troop_add_to_cell(s, Cell_Idx(cell_idx)) {
                s.pos = cell_center(Cell_Idx(cell_idx))
                return
            }
        }
        fmt.printfln("No cells left")
    }

    // try adding to the cell on pos
    if troop_add_to_cell(s, cell_idx) {
        s.pos = pos
        return
    }

    // if taken, try adding to surrounding cells until found a spot
    origin := Coord(pos)
    coord: Coord
    for {
        coord = grid.next_surrounding_cell(coord)
        cell_idx = Cell_Idx(grid.idx(board, origin + coord))

        if troop_add_to_cell(s, cell_idx) {
            s.pos = cell_center(cell_idx)
            return
        }
    }
}

game_init :: proc () {

    update_frame_globals()

    board = grid.make(Cell, {BOARD_X, BOARD_Y})

    troops = make(type_of(troops), 0, 10000, allocator=context.allocator)

    for &army in armies {
        initials := initial_army_units[army.side]

        army.units = make([]Company, len(initials))

        for initial, ci_int in initials {
            ci := Company_Idx(ci_int)
            company := &army.units[ci]

            company.name  = initial.name
            company.units = make([]Troop_Idx, initial.count)

            for &si, i in company.units {

                si = Troop_Idx(len(troops))
                company.units[i] = si
                append_nothing_soa(&troops)

                s := troop_get(si)
                s.si = si
                s.ci = ci

                pos := each_army_goal_pos(Vec2(initial.pos) + Vec2(0.5), initial.rot, i, initial.count)
                troop_set_pos_force(s, pos)
            }
        }
    }
}

update_frame_globals :: proc () {
    window_size = k2.get_screen_size()
    board_rect   = get_board_rect()
}

update :: proc (dt: f32) -> bool {

    update_frame_globals()

    mouse_pos := k2.get_mouse_position()
    mouse_world := world_pos_from_screen(mouse_pos)

    hovered_troop = nil
    check_mouse_hover: {
        coord: Coord
        origin := board_coord_from_pos(mouse_world) or_break check_mouse_hover
        r := 2
        d := r*2
        w := d+1
        steps := w*w - 4
        for _ in 0..<steps {
            defer coord = grid.next_surrounding_cell(coord)

            cell := grid.get_safe(board, origin + coord) or_continue
            si := cell.troop.? or_continue

            hovered_troop = si
            break
        }
    }

    check_click: if k2.mouse_button_is_held(.Left) {

        // ignore clicks outside of the grid
        _ = grid_idx_from_pos(mouse_world) or_break check_click

        if si, hovering_troop := hovered_troop.?; hovering_troop {
            // select company

            troop := troop_get(si)
            selected_company = Company_Handle{
                side = troop.side,
                idx  = troop.ci,
            }
        }
        else if selected, is_selected := selected_company.?; is_selected {
            // set selected company's target

            company := armies[selected.side].units[selected.idx]

            for si, i in company.units {
                s := troop_get(si)
                pos := each_army_goal_pos(mouse_world, -0.2, i, len(company.units))
                coord: Coord
                origin := Coord(pos)
                for {
                    defer coord = grid.next_surrounding_cell(coord)

                    s.target = Cell_Idx(grid.idx_safe(board, origin + coord) or_continue)
                    break
                }
            }
        }
    }

    move_troops: {

        walls := grid.make_empty(bool, board.size, allocator=context.temp_allocator)
        for cell, i in grid.slice(&board) {
            walls.data[i] = cell.troop != nil
        }

        for _, i in troops {
            troop := &troops[i]

            path := make([dynamic]grid.Coord, allocator=context.temp_allocator)

            if target, ok := troop.target.(Cell_Idx); ok {

                start := board_coord_from_pos(troop.pos) or_continue
                end   := grid.coord(board, target)

                clear(&path)
                astar.astar(&path, walls,  start, end, allocator=context.temp_allocator)

                if len(path) == 0 do continue

                coord := path[0]
                assert(coord != start)

                d := la.normalize(Vec2(coord) + Vec2(0.5) - troop.pos) * dt * 0.02
                n := troop.pos + d
                if !math.is_nan(n.x) &&
                   !math.is_nan(n.y) &&
                   !math.is_inf(n.x) &&
                   !math.is_inf(n.y) {
                    troop_set_pos(troop, n)
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
        for xi in 0..=BOARD_X {
            xp := f32(xi)/BOARD_X
            x  := board_rect.size.x * xp
            s  := board_rect.pos + {x, 0}
            e  := board_rect.pos + {x, board_rect.size.y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
        for yi in 0..=BOARD_Y {
            yp := f32(yi)/BOARD_Y
            y  := board_rect.size.y * yp
            s  := board_rect.pos + {0, y}
            e  := board_rect.pos + {board_rect.size.x, y}
            k2.draw_line(s, e, 1, k2.DARK_GRAY)
        }
    }

    for s, i in troops {
        si := Troop_Idx(i)

        color := army_player.color
        size := f32(troop_W)
        // color := army.color
        // if is_dead(s) {
        //     color = k2.DARK_GRAY
        // }
        pos := world_pos_to_screen(s.pos)
        if hovered_troop == si {
            color = k2.BLUE
            size *= 2
        }
        k2.draw_circle(pos, size, color)
    }

    // selected company outline
    if selected, is_selected := selected_company.?; is_selected {

        company := armies[selected.side].units[selected.idx]

        points := make([dynamic]Vec2, 0, len(company.units), allocator=context.temp_allocator)
        for si in company.units {
            s := troop_get(si)
            append(&points, s.pos)
        }

        outline := convex_hull(points[:], allocator=context.temp_allocator)

        if len(outline) < 3 && len(company.units) > 0 {
            s := troop_get(company.units[0])
            p := s.pos
            outline = {
                p + {+6, +3},
                p + {-6, +3},
                p + { 0, -3},
            }
        }

        outline = expand_convex_polygon(outline, 2, allocator=context.allocator)
        for i in 0..<len(outline) {
            a, b := outline[i], outline[(i+1)%len(outline)]
            a = world_pos_to_screen(a)
            b = world_pos_to_screen(b)
            k2.draw_line(a, b, 3, k2.GRAY)
        }
    }

    mouse_pos := k2.get_mouse_position()
    draw_cross(mouse_pos, k2.GREEN)

    // p: Coord
    // N :: 1000
    // for i in 0..<N {
    //     p = grid.next_surrounding_cell(p)
    //     c1 := color.FRGB{1, 1, 0}
    //     c2 := color.FRGB{1, 0, 0}
    //     c3 := color.FRGB{1, 0, 1}
    //     c: color.FRGB
    //     cp := f32(i)*2/N
    //     if cp < 1 {
    //         c = color.lerp(c1, c2, cp)
    //     } else {
    //         c = color.lerp(c2, c3, cp-1)
    //     }
    //     k2.draw_circle(board_rect.pos + Vec2(p + {40, 40}) * (board_rect.size/BOARD_SIZE), 3, k2.Color(color.urgba(c)))
    // }

    return true
}

