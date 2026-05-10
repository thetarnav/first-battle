package first_battle

import "base:runtime"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import k2 "./karl2d"
import "./color"
import "./grid"
import "./util"
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
    target:   union {Cell_Idx, Company_Handle},
}
Company_Idx :: distinct u16

Company_Handle :: struct {
    side: Army_Side,
    idx:  Company_Idx,
}

Troop :: struct {

    info: struct {
        si:       Troop_Idx,
        side:     Army_Side,
        ci:       Company_Idx,
        ui:       int,
    },

    pos:      Vec2,

    movement: struct {
        target:      Maybe(Cell_Idx),
        path:        [dynamic]Cell_Idx,
        prefer:      enum {Target, Path},
        time_left:   f32,
    },
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
        {"one", {40, 80}, -0.2, 200},
        {"two", {80, 60}, -0.4, 120},
    },
    .Enemy  = {
        {"one", {40, 36}, math.PI, 200},
        {"two", {80, 30}, math.PI - 0.2, 120},
    },
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
BOARD_Y           :: 128
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

board_coord_from_pos :: proc (pos: Vec2) -> (coord: Coord, ok: bool) #optional_ok {
    return Coord(pos), grid.inside(board, Coord(pos))
}
cell_idx_from_pos :: proc (pos: Vec2) -> (idx: Cell_Idx, ok: bool) #optional_ok {
    return cell_idx(Coord(pos)), grid.inside(board, Coord(pos))
}
cell_from_pos :: proc (pos: Vec2) -> (cell: ^Cell, ok: bool) {
    return grid.ptr_safe(&board, Coord(pos))
}
cell_get :: proc (idx: Cell_Idx) -> (cell: ^Cell) {
    return grid.ptr_idx(&board, idx)
}
cell_coord :: proc (idx: Cell_Idx) -> (coord: Coord) {
    return grid.coord(board, idx)
}
cell_idx :: proc (coord: Coord) -> (idx: Cell_Idx) {
    return Cell_Idx(grid.idx(board, coord))
}
cell_idx_safe :: proc (coord: Coord) -> (idx: Cell_Idx, ok: bool) {
    return Cell_Idx(grid.idx_safe(board, coord) or_return), true
}
cell_center :: proc (idx: Cell_Idx) -> (pos: Vec2) {
    return Vec2(grid.coord(board, idx)) + Vec2(0.5)
}
cell_rect :: proc (idx: Cell_Idx) -> (rect: Rect) {
    return {Vec2(grid.coord(board, idx)), 1}
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

troop_get :: proc (idx: Troop_Idx) -> Troop_Ptr {
    return &troops[idx]
}
troop_coord :: proc (idx: Troop_Idx) -> Coord {
    return Coord(troops[idx].pos)
}
troop_company_handle :: proc (idx: Troop_Idx) -> Company_Handle {
    troop := troop_get(idx)
    return Company_Handle{
        side = troop.info.side,
        idx  = troop.info.ci,
    }
}
company_from_handle :: proc (handle: Company_Handle) -> ^Company {
    return &armies[handle.side].units[handle.idx]
}
troop_add_to_cell :: proc (s: Troop_Ptr, cell_idx: Cell_Idx) -> (ok: bool) {

    cell := grid.ptr_idx_safe(&board, cell_idx) or_return

    // cell taken
    if prev_troop, cell_has_prev_troop := cell.troop.?;
       cell_has_prev_troop && prev_troop != s.info.si {
        return false
    }

    // remove troop from it's current cell
    if prev_cell, has_prev_cell := cell_from_pos(s.pos);
       has_prev_cell && prev_cell.troop == s.info.si {
        prev_cell.troop = nil
    }

    cell.troop = s.info.si
    return true
}
troop_set_pos :: proc (troop: Troop_Ptr, pos: Vec2) -> (ok: bool) {

    cell_idx := cell_idx_from_pos(pos) or_return

    if troop_add_to_cell(troop, cell_idx) {
        // added to next cell (or same)
        troop.pos = pos
    } else {
        // move in current cell up to the cell border
        cell_idx = cell_idx_from_pos(troop.pos)
        pos := rect_clamp_point_exclusive(cell_rect(cell_idx), pos)
        assert(cell_idx == cell_idx_from_pos(pos))
        if troop.pos == pos {
            return false // cannot move further
        }
        troop.pos = pos
    }

    return true
}
troop_move_towards :: proc (troop: Troop_Ptr, e_idx: Cell_Idx, dt: f32) -> (ok: bool) {

    s_idx, _ := cell_idx_from_pos(troop.pos)

    s_coord := cell_coord(s_idx)
    e_coord := cell_coord(e_idx)

    s_pos := troop.pos
    e_pos := Vec2(e_coord) + Vec2(0.5)

    // end
    if distance(s_pos, e_pos) < 0.01 && s_coord == e_coord {
        troop.pos = e_pos
        return true
    }

    d := la.clamp(e_pos-s_pos, 0, la.normalize(e_pos-s_pos))
    n := troop.pos + (d * dt * 0.02)
    if la.is_nan(n) != false {
        return false
    }

    return troop_set_pos(troop, n)
}
troop_set_pos_force :: proc (s: Troop_Ptr, pos: Vec2) {

    cell_idx, pos_in_grid := cell_idx_from_pos(pos)

    // pos outside of the grid - pick any cell
    if !pos_in_grid {
        fmt.printfln("tried to set position outside of the grid: %v", pos)

        if prev_cell, has_prev_cell := cell_from_pos(s.pos);
           has_prev_cell && prev_cell.troop == s.info.si {
            return // already in a cell
        }

        // add to any cell
        for cell, cell_idx in grid.slice(board) {
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

    // each army
    for &army in armies {
        initials := initial_army_units[army.side]

        army.units = make([]Company, len(initials))

        // each company
        for initial, ci_int in initials {
            ci := Company_Idx(ci_int)
            company := &army.units[ci]

            company.name  = initial.name
            company.units = make([]Troop_Idx, initial.count)

            // each troop
            for &si, i in company.units {

                si = Troop_Idx(len(troops))
                company.units[i] = si
                append_nothing_soa(&troops)

                s := troop_get(si)
                s.info.side = army.side
                s.info.si   = si
                s.info.ci   = ci
                s.info.ui   = i
                s.info.ui   = i

                pos := each_army_goal_pos(Vec2(initial.pos) + Vec2(0.5), initial.rot, i, initial.count)
                troop_set_pos_force(s, pos)

                s.movement.path = make(type_of(s.movement.path))
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

    check_click: if k2.mouse_button_went_down(.Left) {

        // ignore clicks outside of the grid
        cell_idx := cell_idx_from_pos(mouse_world) or_break check_click

        if si, hovering_troop := hovered_troop.?; hovering_troop {
            // company target

            company_handle := troop_company_handle(si)

            switch selected_company {
            case nil:
                // select
                selected_company = company_handle
            case company_handle:
                // dissellect
                selected_company = nil
            case:
                selected := selected_company.(Company_Handle)
                if selected.side == company_handle.side {
                    // select same side
                    selected_company = company_handle
                } else {
                    // attack opposite side
                    company_from_handle(selected).target = company_handle
                }
            }
        }
        else if selected, is_selected := selected_company.?; is_selected {
            // cell target

            company_from_handle(selected).target = cell_idx
        }
    }

    move_troops:
    for _, i in troops {
        si := Troop_Idx(i)
        troop := &troops[si]

        troop.movement.time_left -= dt
        time_to_update := troop.movement.time_left <= 0
        if time_to_update {
            troop.movement.time_left = rand.float32_range(200, 600)
        }

        if time_to_update {

            company := company_from_handle(troop_company_handle(si))

            switch t in company.target {
            case nil:
                // drop target
                troop.movement.target = nil
            case Cell_Idx:
                // go to closest available cell to target cell
 
                target_pos := each_army_goal_pos(cell_center(t), -0.2, troop.info.ui, len(company.units))

                for offset: Coord; /**/; offset = grid.next_surrounding_cell(offset) {

                    coord := Coord(target_pos) + offset
                    troop.movement.target = cell_idx_safe(coord) or_continue
                    break
                }
            case Company_Handle:
                // go to closest available troop from target company

                target_company := company_from_handle(t)

                context.user_ptr = &troop.pos
                closest_idx := util.slice_min_proc(target_company.units, proc (idx: Troop_Idx) -> f32 {
                    troop_pos := (^Vec2)(context.user_ptr)^
                    return la.distance(troop_pos, troop_get(idx).pos)
                }) or_break
                closest_coord := troop_coord(closest_idx)

                for offset: Coord; /**/; offset = grid.next_surrounding_cell(offset) {

                    coord := closest_coord + offset
                    troop.movement.target = cell_idx_safe(coord) or_continue
                    break
                }
            }
        }

        target, has_target := troop.movement.target.(Cell_Idx)
        target_coord := cell_coord(target)
        troop_coord := board_coord_from_pos(troop.pos)
        troop_cell_idx := cell_idx(troop_coord)

        direct:
        if has_target && target_coord != troop_coord &&
           (time_to_update || troop.movement.prefer == .Target) {
            // try moving towards the target directly

            next := troop_coord + la.sign(target_coord-troop_coord)
            next_idx := cell_idx(next)
            next_cell := cell_get(next_idx)
            if next_cell.troop != nil do break direct

            troop.movement.prefer = .Target
            if troop_move_towards(troop, target, dt) do continue
        }

        pathfind:
        if has_target && target_coord != troop_coord && time_to_update {
            // find a path to the target id cannot move directly

            target_cell := cell_get(target)
            if target_cell.troop != nil do break pathfind

            troop.movement.prefer = .Target
            clear(&troop.movement.path)

            // pathfind in a limited fragment of the board
            slice_rect := rect_int_from_points({troop_coord, target_coord})
            slice_rect  = rect_int_extend(slice_rect, 10)
            slice_rect  = rect_int_clamp(slice_rect, {0, board.size})

            walls := grid.make_empty(bool, slice_rect.size)
            for &w, i in grid.slice(walls) {
                board_coord := grid.coord(walls, i) + slice_rect
                cell := grid.get(board, board_coord)
                w = cell.troop != nil
            }

            path := make([dynamic]Coord, allocator=context.temp_allocator)
            if astar.astar(&path, walls, troop_coord-slice_rect, target_coord-slice_rect, allocator=context.temp_allocator) {
                resize(&troop.movement.path, len(path))
                for &p, i in troop.movement.path {
                    p = cell_idx(path[i] + slice_rect)
                }
                troop.movement.prefer = .Path
            }
        }

        by_path:
        if troop.movement.prefer == .Path {
            // try moving using the path

            if len(troop.movement.path) == 0 {
                troop.movement.prefer = .Target
                break by_path
            }

            next := troop.movement.path[0]

            if troop_cell_idx == next {
                pop_front(&troop.movement.path)
            }

            if troop_move_towards(troop, next, dt) do continue
        }

        troop_move_towards(troop, troop_cell_idx, dt)
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

    // for c, i in grid.slice(board) {
    //     if c.troop != nil {
    //         s := world_pos_to_screen(Vec2(grid.coord(board, i)))
    //         w := board_rect.size/BOARD_SIZE
    //         k2.draw_rect({x=s.x, y=s.y, w=w.x, h=w.y}, k2.LIGHT_GRAY)
    //     }
    // }

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

    for troop, i in troops {
        si := Troop_Idx(i)

        // color := army_player.color
        size := f32(troop_W)
        color := armies[troop.info.side].color
        // if is_dead(s) {
        //     color = k2.DARK_GRAY
        // }
        pos := world_pos_to_screen(troop.pos)
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

