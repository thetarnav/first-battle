package first_battle

import "core:slice"
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
    units:    []Company_Idx,
}

Unit_Kind :: enum u8 {
    Infantry,
    Heavy,
    Riders,
}
Company :: struct {
    side:        Army_Side,
    idx:         Company_Idx,
    name:        string,
    kind:        Unit_Kind,
    units:       []Troop_Idx,
    alive_units: []Troop_Idx,
    avg_pos:     Vec2,
    target:      union #no_nil {Cell_Idx, Company_Idx},
}
Company_Idx :: distinct u16

Troop :: struct {

    info: struct {
        si:    Troop_Idx,
        side:  Army_Side,
        compi: Company_Idx,
    },

    pos: Vec2,

    combat: struct {
        dmg_taken: f32,
        in_fight:  f32,
    },

    movement: struct {
        target:      Maybe(Cell_Idx),
        path:        [dynamic]Cell_Idx,
        prefer:      enum {Target, Path},
        time_left:   f32,
        velocity:    Vec2,
    },
}
Troop_Idx :: distinct u16
Troop_Arr :: #soa[dynamic]Troop
Troop_Ptr :: #soa^Troop_Arr

Cell :: struct {
    troop:  Maybe(Troop_Idx),
    corpse: bool,
}
Cell_Idx :: distinct u16

armies: [Army_Side]Army = {
    .Player = {side=.Player, name="Player", color=k2.ORANGE},
    .Enemy  = {side=.Enemy,  name="Enemy",  color=k2.RED},
}
army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

@rodata
initial_army_units: [Army_Side][]struct {name: string, kind: Unit_Kind, pos: Coord, rot: f32, count: int} = {
    .Player = {
        {"one", .Infantry, {23, 90}, -0.2, 200},
        {"two", .Heavy,    {60, 80}, -0.4, 120},
        {"thr", .Riders,   {100, 80}, -0.4, 120},
    },
    .Enemy  = {
        {"one", .Infantry, {23, 26}, math.PI,       200},
        {"two", .Heavy,    {60, 20}, math.PI - 0.2, 120},
        {"thr", .Riders,   {100, 30}, math.PI - 0.4, 120},
    },
}

Unit_Config :: struct {
    color:      color.RGB,
    accel:      f32,
    frict:      f32,
    dmg_move:   f32,
    dmg_static: f32,
}
unit_config := [Unit_Kind]Unit_Config{
    .Infantry = {color={220, 180, 160}, accel=0.000034,  frict=0.99,   dmg_static=0.1, dmg_move=0.16},
    .Heavy    = {color={120, 140, 120}, accel=0.000024,  frict=0.99,   dmg_static=0.2, dmg_move=0.1},
    .Riders   = {color={230, 120,  20}, accel=0.000038, frict=0.9966, dmg_static=0.1, dmg_move=0.4},
}

automatic := [Army_Side]bool{
    .Player = false,
    .Enemy  = false,
}
is_automatic :: proc (side: Army_Side) -> bool {return automatic[side]}

troops: Troop_Arr
companies: [dynamic]Company

hovered_troop: Maybe(Troop_Idx)
selected_company: Maybe(Company_Idx)

board: grid.Grid(Cell)

// updated every fame
window_size: Vec2
board_rect:  Rect
mouse_pos:   Vec2
mouse_world: Vec2

GOLDEN_RATIO  :: 1.618

BOARD_X           :: 128
BOARD_Y           :: 128
BOARD_N           :: BOARD_X*BOARD_Y
BOARD_SIZE        :: Vec2{BOARD_X, BOARD_Y}
BOARD_AR          :: f32(BOARD_X)/f32(BOARD_Y)
BOARD_RECT_MARGIN :: 10

TROOP_W :: 4
TROOP_M :: 3

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
cell_troop :: proc (idx: Cell_Idx) -> (troop: Troop_Ptr, ok: bool) {
    cell := cell_get(idx)
    troopi := cell.troop.? or_return
    return troop_get(troopi), true
}
cell_corpse :: proc (idx: Cell_Idx) -> (is_corpse: bool) {
    return cell_get(idx).corpse
}

army_count_dim :: proc (n: int) -> (res: [2]int) {
    res.y = int(math.sqrt(f32(n)/GOLDEN_RATIO))
    res.x = n/res.y
    return
}

each_army_goal_pos :: proc (origin: Vec2, rot: f32, i, n: int) -> (p: Vec2) {
    if n < 2 {
        return origin
    }
    dim := army_count_dim(n)
    xy := [2]int{i%dim.x, i/dim.x} - dim/2
    p = Vec2(xy) * 2
    p = vec2_rotate_angle(p, rot)
    p += origin
    p = la.floor(p)
    p += 0.5
    return
}

troop_get :: proc (idx: Troop_Idx) -> Troop_Ptr {
    return &troops[idx]
}
troop_get_coord :: proc (idx: Troop_Idx) -> Coord {
    return Coord(troops[idx].pos)
}
troop_cell :: proc (idx: Troop_Idx) -> (cell: ^Cell) {
    coord := troop_get_coord(idx)
    cidx  := cell_idx(coord)
    return cell_get(cidx)
}
troop_is_dead :: proc (idx: Troop_Idx) -> bool {
    return troop_get(idx).combat.dmg_taken >= 1
}
troop_is_alive :: proc (idx: Troop_Idx) -> bool {
    return !troop_is_dead(idx)
}
troop_company_idx :: proc (idx: Troop_Idx) -> Company_Idx {
    troop := troop_get(idx)
    return troop.info.compi
}
troop_config :: proc (idx: Troop_Idx) -> Unit_Config {
    return unit_config[company_get(troop_company_idx(idx)).kind]
}
company_get :: proc (idx: Company_Idx) -> ^Company {
    return &companies[idx]
}
company_find_closest :: proc (side: Army_Side, pos: Vec2) -> (compi: Company_Idx, found: bool) {
    pos := pos
    context.user_ptr = &pos
    return util.slice_min_proc(armies[side].units, proc (ecompi: Company_Idx) -> (val: f32, ok: bool) {
        ecomp := company_get(ecompi)
        if len(ecomp.alive_units) == 0 {
            return 0, false
        }
        return la.distance(ecomp.avg_pos, (^Vec2)(context.user_ptr)^), true
    })
}
troop_add_to_cell :: proc (s: Troop_Ptr, cell_idx: Cell_Idx) -> (ok: bool) {

    cell := grid.ptr_idx_safe(&board, cell_idx) or_return

    // cell taken
    if prev_troop, cell_has_prev_troop := cell.troop.?;
       cell_has_prev_troop && prev_troop != s.info.si {
        if  troop_is_alive(prev_troop) {
            return false
        } else {
            cell.corpse = true
        }
    }

    // remove troop from it's current cell
    if prev_cell, has_prev_cell := cell_from_pos(s.pos);
       has_prev_cell && prev_cell.troop == s.info.si {
        prev_cell.troop = nil
    }

    cell.troop = s.info.si
    return true
}
calc_intention :: proc (troop: Troop_Ptr, e_idx: Cell_Idx) -> (intention: Vec2, at_target: bool) {

    s_idx := cell_idx_from_pos(troop.pos)

    s_coord := cell_coord(s_idx)
    e_coord := cell_coord(e_idx)

    s_pos := troop.pos
    e_pos := cell_center(e_idx)

    diff := la.clamp(e_pos-s_pos, 0, la.normalize(e_pos-s_pos))

    // in fight is slower
    diff /= Vec2(troop.combat.in_fight+1)

    // slow down damaged troops
    diff *= Vec2((1-troop.combat.dmg_taken)*0.6 + 0.4)

    // slower on corpses
    if cell_corpse(s_idx) {
        diff *= 0.75
    }

    return diff, la.length(diff) < 0.01 && s_coord == e_coord
}
troop_apply_force :: proc (troop: Troop_Ptr, intention: Vec2, dt: f32) -> (collision: Maybe(Cell_Idx), moved: bool) {

    config := unit_config[company_get(troop.info.compi).kind]

    troop.movement.velocity += intention * config.accel * dt // accelleration

    velocity := troop.movement.velocity * dt
    next_pos := troop.pos + velocity

    next_celli := cell_idx_from_pos(next_pos) or_return

    if troop_add_to_cell(troop, next_celli) {
        // added to next cell (or same)
        troop.pos = next_pos
    } else {
        // move in current cell up to the cell border
        next_celli = cell_idx_from_pos(troop.pos)
        pos := rect_clamp_point_exclusive(cell_rect(next_celli), next_pos)
        assert(next_celli == cell_idx_from_pos(pos))
        if troop.pos == pos {
            return next_celli, false // cannot move further
        }
        troop.pos = pos
        return next_celli, true
    }

    return nil, true
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

        army.units = make([]Company_Idx, len(initials))

        // each company
        for initial, ci in initials {

            append_nothing(&companies)
            compi := Company_Idx(len(companies)-1)
            comp  := company_get(compi)

            army.units[ci] = compi

            comp.side   = army.side
            comp.idx    = compi
            comp.kind   = initial.kind
            comp.name   = initial.name
            comp.units  = make([]Troop_Idx, initial.count)

            comp_celli := cell_idx(initial.pos)
            comp.target = comp_celli

            // each troop
            for &si, i in comp.units {

                si = Troop_Idx(len(troops))
                comp.units[i] = si
                append_nothing_soa(&troops)

                s := troop_get(si)
                s.info.side  = army.side
                s.info.si    = si
                s.info.compi = compi

                pos := each_army_goal_pos(cell_center(comp_celli), initial.rot, i, initial.count)
                troop_set_pos_force(s, pos)

                s.movement.path = make(type_of(s.movement.path))
            }
        }
    }
}

update_frame_globals :: proc () {
    window_size = k2.get_screen_size()
    board_rect  = get_board_rect()
    mouse_pos   = k2.get_mouse_position()
    mouse_world = world_pos_from_screen(mouse_pos)
}

update_hover :: proc () -> (ok: bool) {
    hovered_troop = nil

    coord: Coord
    origin := board_coord_from_pos(mouse_world) or_return
    r := 2
    d := r*2
    w := d+1
    steps := w*w - 4
    for _ in 0..<steps {
        defer coord = grid.next_surrounding_cell(coord)

        celli := cell_idx_safe(origin + coord) or_continue
        troopi := cell_get(celli).troop.? or_continue
        if troop_is_dead(troopi) do continue

        hovered_troop = troopi
        break
    }

    return true
}

update_companies :: proc () -> (ok: bool) {

    // update alive units array and average company position
    for army in armies {
        for compi in army.units {
            comp := company_get(compi)

            alive_units := make([dynamic]Troop_Idx, 0, len(comp.units), allocator=context.temp_allocator)

            sum_pos: Vec2

            for uidx in comp.units {
                ucell := troop_cell(uidx)

                if troop_is_alive(uidx) {
                    append(&alive_units, uidx)
                    sum_pos += troop_get(uidx).pos
                } else if ucell.troop == uidx {
                    ucell.troop  = nil
                    ucell.corpse = true
                }
            }

            shrink(&alive_units)
            comp.alive_units = alive_units[:]
            comp.avg_pos     = sum_pos/f32(len(alive_units))
        }
    }

    // don't target dead company
    for army in armies {
        for compi in army.units {
            comp := company_get(compi)

            if target_idx, has_target := comp.target.(Company_Idx); has_target {
                target_company := company_get(target_idx)
                if len(target_company.alive_units) == 0 {
                    comp.target = cell_idx_from_pos(comp.avg_pos)
                }
            }
        }
    }

    // disselect dead company
    if selected, is_selected := selected_company.?; is_selected {
        company := company_get(selected)
        if len(company.alive_units) == 0 {
            selected_company = nil
        }
    }

    return true
}

update_click :: proc () -> (ok: bool) {

    if !k2.mouse_button_went_down(.Left) do return

    // ignore clicks outside of the grid
    cell_idx := cell_idx_from_pos(mouse_world) or_return

    if troopi, hovering_troop := hovered_troop.?; hovering_troop {
        // company target

        compi := troop_company_idx(troopi)
        comp  := company_get(compi)

        switch selected_company {
        case nil:
            if is_automatic(comp.side) {
                // cannot select automatic side
            } else {
                // select
                selected_company = compi
            }
        case compi:
            // dissellect
            selected_company = nil
        case:
            selected_compi := selected_company.(Company_Idx)
            selected_comp  := company_get(selected_compi)

            if selected_comp.side == comp.side {
                // select same side
                selected_company = compi
            } else {
                // attack opposite side
                selected_comp.target = compi
                selected_company = nil // disselect after action
            }
        }
    }
    else if selected, is_selected := selected_company.?; is_selected {
        // cell target

        company_get(selected).target = cell_idx
        selected_company = nil // disselect after action
    }

    return true
}

update_automatic :: proc () -> (ok: bool) {

    for army in armies {
        is_automatic(army.side) or_continue

        for compi in army.units {
            comp := company_get(compi)
            comp.target = company_find_closest(side_opposite(army.side), comp.avg_pos) or_continue
        }
    }

    return true
}

update_troops :: proc (dt: f32) -> (ok: bool) {

    for _, i in troops {
        si := Troop_Idx(i)
        troop := &troops[si]

        if troop_is_dead(si) do continue

        troop.combat.in_fight = 0
    }

    update_troops:
    for _, i in troops {
        si := Troop_Idx(i)
        troop := &troops[si]

        if troop_is_dead(si) do continue

        troop_coord := board_coord_from_pos(troop.pos)
        troop_cell_idx := cell_idx(troop_coord)

        troop_comp := company_get(troop.info.compi)
        troop_config := unit_config[troop_comp.kind]

        troop.movement.time_left -= dt
        time_to_update := troop.movement.time_left <= 0
        if time_to_update {
            troop.movement.time_left = rand.float32_range(200, 600)
        }

        troop.movement.velocity *= math.pow(troop_config.frict, dt) // damping

        attack :: proc (troop, enemy: Troop_Ptr) -> (ok: bool) {
            if enemy.info.side == troop.info.side do return
            if troop_is_dead(enemy.info.si) do return

            config := troop_config(troop.info.si)

            dmg := config.dmg_static + config.dmg_move * la.length(troop.movement.velocity)

            enemy.combat.in_fight  += 0.8
            enemy.combat.dmg_taken = min(enemy.combat.dmg_taken + dmg, 1)
            troop.combat.in_fight  += 1

            return true
        }

        update_target: if time_to_update {
            // update troop's target based on the current company target

            switch t in troop_comp.target {
            case Cell_Idx:
                // go to closest available cell to target cell
 
                // arrange only the alive troops
                alive_idx, _ := slice.binary_search(troop_comp.alive_units, troop.info.si)
                pos := cell_center(t)
                angle: f32
                if troop.info.side == .Enemy {
                    angle = math.PI
                }
                if closest, found := company_find_closest(side_opposite(troop.info.side), pos); found {
                    angle = vec2_angle(pos, company_get(closest).avg_pos) - math.PI/2
                }
                target_pos := each_army_goal_pos(pos, angle, alive_idx, len(troop_comp.alive_units))

                for offset: Coord; /**/; offset = grid.next_surrounding_cell(offset) {

                    coord := Coord(target_pos) + offset
                    troop.movement.target = cell_idx_safe(coord) or_continue
                    break
                }
            case Company_Idx:
                // go to closest available troop from target company

                // already next to an enemy
                for dir in grid.DIRECTION_VECTORS {

                    cidx   := cell_idx_safe(troop_coord + dir) or_continue
                    ctroop := cell_troop(cidx) or_continue
                    if ctroop.info.compi != t do continue

                    attack(troop, ctroop) or_continue
                    troop.movement.target = cidx
                    intention, _ := calc_intention(troop, troop_cell_idx)
                    troop_apply_force(troop, intention, dt)
                    continue update_troops
                }

                tcomp := company_get(t)

                // find closest enemy troop
                context.user_ptr = &troop.pos
                closest_idx := util.slice_min_proc(tcomp.units, proc (uidx: Troop_Idx) -> (val: f32, ok: bool) {
                    troop_pos := (^Vec2)(context.user_ptr)^

                    utroop := troop_get(uidx)
                    ucoord := troop_get_coord(uidx)

                    troop_is_alive(uidx) or_return

                    is_accessable: {
                        for dir in grid.DIRECTION_VECTORS {
                            cidx := cell_idx_safe(ucoord + dir) or_continue
                            ctroop, has_troop := cell_troop(cidx)
                            if !has_troop || troop_is_dead(ctroop.info.si) {
                                break is_accessable
                            }
                        }

                        return 0, false
                    }

                    return la.distance(troop_pos, utroop.pos), true
                }) or_break

                closest_coord := troop_get_coord(closest_idx)

                // set the target as one of the adjacent cells
                for dir in grid.DIRECTION_VECTORS {
                    cidx := cell_idx_safe(closest_coord + dir) or_continue
                    ctroop, has_troop := cell_troop(cidx)
                    if !has_troop || troop_is_dead(ctroop.info.si) {
                        troop.movement.target = cidx
                        break
                    }
                }
            }
        }

        target, has_target := troop.movement.target.(Cell_Idx)
        target_coord := cell_coord(target)

        direct:
        if has_target && target_coord != troop_coord &&
           (time_to_update || troop.movement.prefer == .Target) {
            // try moving towards the target directly

            next := troop_coord + la.sign(target_coord-troop_coord)
            next_idx  := cell_idx(next)
            next_cell := cell_get(next_idx)
            if next_cell.troop != nil {
                // troop.movement.prefer = .Path
                break direct
            }

            troop.movement.prefer = .Target
            intention, at_target := calc_intention(troop, target)
            if at_target {
                troop.pos = cell_center(target)
                // troop.movement.velocity = 0
                continue update_troops
            }
            collision, moved := troop_apply_force(troop, intention, dt)
            if moved {
                continue update_troops
            }
            if collision_idx, collided := collision.?; collided {
                // collision with enemy - apply speed-based damage
                intended_pos := troop.pos + troop.movement.velocity
                if cidx, ok := cell_idx_from_pos(intended_pos); ok {
                    if occupant_idx, occupied := cell_get(cidx).troop.?; occupied && troop_is_alive(occupant_idx) {
                        attack(troop, troop_get(occupant_idx))
                    }
                }
            }
            troop.movement.prefer = .Path
            continue update_troops
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
            slice_rect  = rect_int_extend(slice_rect, 12)
            slice_rect  = rect_int_clamp(slice_rect, {0, board.size})

            walls := grid.make_empty(bool, slice_rect.size, allocator=context.temp_allocator)
            for &w, i in grid.slice(walls) {
                board_coord := grid.coord(walls, i) + slice_rect
                board_idx   := cell_idx(board_coord)
                board_troop, cell_has_troop := cell_troop(board_idx)
                if cell_has_troop && !troop_is_dead(board_troop.info.si) {
                    w = true
                }
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

            intention, at_target := calc_intention(troop, next)
            if at_target {
                pop_front(&troop.movement.path)
                if len(troop.movement.path) == 0 {
                    troop.movement.prefer = .Target
                }
                continue update_troops
            }
            collision, moved := troop_apply_force(troop, intention, dt)
            if moved {
                continue update_troops
            }
            if collision_idx, collided := collision.?; collided {
                // collision with enemy - apply speed-based damage
                intended_pos := troop.pos + troop.movement.velocity
                if cidx, ok := cell_idx_from_pos(intended_pos); ok {
                    if occupant_idx, occupied := cell_get(cidx).troop.?; occupied && troop_is_alive(occupant_idx) {
                        attack(troop, troop_get(occupant_idx))
                    }
                }
            }
            continue update_troops
        }

        if time_to_update {
            for dir in grid.DIRECTION_VECTORS {
                cidx := cell_idx_safe(troop_coord + dir) or_continue
                ctroop := cell_troop(cidx) or_continue
                attack(troop, ctroop) or_continue
                break
            }
        }

        // fallback: move to center of own cell
        intention, at_target := calc_intention(troop, troop_cell_idx)
        if at_target {
            troop.pos = cell_center(troop_cell_idx)
        } else {
            troop_apply_force(troop, intention, dt)
        }
    }

    return true
}

update :: proc (dt: f32) -> bool {

    update_frame_globals()
    update_companies()
    update_hover()
    update_click()
    update_automatic()
    update_troops(dt)

    if k2.key_went_down(.Q) {
        return false
    }
    return true
}

frame :: proc (dt: f32) -> bool {

    k2.clear({12, 10, 9, 255})

    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)

    // draw corpses
    for cell, i in grid.slice(board) {
        if cell_corpse(Cell_Idx(i)) {
            p := cell_center(Cell_Idx(i))
            p = world_pos_to_screen(p)
            k2.draw_circle(p, f32(TROOP_W), k2.DARK_GRAY)
        }
    }

    // draw lines
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

    // draw troops
    for troop, i in troops {
        si := Troop_Idx(i)

        troop_is_alive(si) or_continue

        // color := army_player.color
        size := f32(TROOP_W)
        army_color := armies[troop.info.side].color
        kind_color := troop_config(si).color
        c := color.lerp(army_color, color.rgba(kind_color), 0.5)
        c  = color.lerp(c, k2.DARK_GRAY, troop.combat.dmg_taken/2)
        pos := world_pos_to_screen(troop.pos)
        if hovered_troop == si {
            c = k2.BLUE
            size *= 2
        }
        k2.draw_circle(pos, size, c)
    }

    // draw company targets
    for army in armies {
        for compi in army.units {
            comp := company_get(compi)

            if len(comp.alive_units) == 0 do continue

            start := comp.avg_pos
            end   := comp.avg_pos

            switch t in comp.target {
            case Cell_Idx:
                end = cell_center(t)
            case Company_Idx:
                tcomp := company_get(t)
                end = tcomp.avg_pos
            }

            start = world_pos_to_screen(start)
            end   = world_pos_to_screen(end)

            if start == end {
                draw_cross(start, k2.YELLOW)
            } else {
                k2.draw_line(start, end, 2, k2.YELLOW)
            }
        }
    }

    // selected company outline
    if compi, is_selected := selected_company.?; is_selected {
        comp := company_get(compi)

        points := make([dynamic]Vec2, 0, len(comp.units), allocator=context.temp_allocator)
        for si in comp.alive_units {
            append(&points, troop_get(si).pos)
        }

        outline := convex_hull(points[:], allocator=context.temp_allocator)

        if len(outline) < 3 && len(comp.alive_units) > 0 {
            s := troop_get(comp.alive_units[0])
            p := s.pos
            outline = {
                p + {+4, +2},
                p + {-4, +2},
                p + { 0, -2},
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

    draw_cross(window_size/2, k2.GRAY)

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

