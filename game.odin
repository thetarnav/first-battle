package first_battle

import "base:runtime"
import "core:slice"
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
Vec2i :: [2]int
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
    side:  Army_Side,
    units: []Company_Idx,
}

Unit_Kind :: enum u8 {
    Infantry,
    Heavy,
    Riders,
    Archers,
}
Company :: struct {
    side:        Army_Side,
    idx:         Company_Idx,
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

    shooting: struct {
        time:   f32,
        target: Troop_Idx,
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

Arrow :: struct {
    from:  Vec2,
    end:   Cell_Idx,
    pos:   Vec2,
    speed: f32,
}

Particle :: struct {
    kind:  enum {Dust},
    pos:   Vec2,
    rot:   f32,
    life:  f32,
    start: f64,
}

INIT_ARMY_UNITS :: [?]struct {kind: Unit_Kind, pos: Coord, count: int}{
    {.Riders,   {20,  40}, 50},
    {.Heavy,    {22,  18}, 50},
    {.Archers,  {54,  14}, 60},
    {.Infantry, {52,  40}, 80},
    {.Archers,  {86,  14}, 60},
    {.Infantry, {86,  40}, 80},
    {.Riders,   {120, 40}, 50},
    {.Heavy,    {118, 18}, 50},
}

Unit_Config :: struct {
    color:      color.RGB,
    accel:      f32,
    frict:      f32,
    dmg_move:   f32,
    dmg_static: f32,
    armor:      f32,
}
@rodata
unit_config := [Unit_Kind]Unit_Config{
    .Infantry = {color={230, 200, 190}, accel=0.000034, frict=0.992,  dmg_static=0.1,  dmg_move=16,  armor=0.7},
    .Heavy    = {color={110, 110, 100}, accel=0.000024, frict=0.99,   dmg_static=0.22, dmg_move=10,  armor=3},
    .Riders   = {color={150, 130,  20}, accel=0.000038, frict=0.9966, dmg_static=0.12, dmg_move=100, armor=1},
    .Archers  = {color={80,  250,  60}, accel=0.000034, frict=0.992,  dmg_static=0.04, dmg_move=6,   armor=0.4},
}

COLOR_BG           :: PALETTE_COLOR_3
COLOR_UI           :: PALETTE_COLOR_3
COLOR_UI_HOVER     :: PALETTE_COLOR_2
COLOR_BOARD        :: PALETTE_COLOR_4
COLOR_SHADOW       :: PALETTE_COLOR_10
COLOR_CORPSE       :: PALETTE_COLOR_6
COLOR_PLAYER_LIGHT :: PALETTE_COLOR_9
COLOR_PLAYER_DARK  :: PALETTE_COLOR_7
COLOR_ENEMY_LIGHT  :: PALETTE_COLOR_2
COLOR_ENEMY_DARK   :: PALETTE_COLOR_1
COLOR_ARROWS       :: PALETTE_COLOR_1

Army_Colors :: struct {
    light, dark: Color,
}
army_colors := [Army_Side]Army_Colors{
    .Player = {light=COLOR_PLAYER_LIGHT, dark=COLOR_PLAYER_DARK},
    .Enemy  = {light=COLOR_ENEMY_LIGHT,  dark=COLOR_ENEMY_DARK},
}

state_arena:     runtime.Arena
state_allocator: runtime.Allocator

armies: [Army_Side]Army = {}
army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

armies_ratio: f32 = 0.5 // player army size / enemy army size

automatic := [Army_Side]bool{
    .Player = false,
    .Enemy  = true,
}
is_automatic :: proc (side: Army_Side) -> bool {return automatic[side]}

troops:    Troop_Arr
companies: [dynamic; len(INIT_ARMY_UNITS) * 2]Company
arrows:    [dynamic; 600]Arrow
particles: [dynamic; 2000]Particle

hovered_troop:    Maybe(Troop_Idx)
selected_company: Maybe(Company_Idx)

board: grid.Grid(Cell)

// updated every fame
frame_time:   f64
window_size:  Vec2
board_rect:   Rect // board rectangle on the screen
mouse_pos:    Vec2
mouse_world:  Vec2
camera_board: k2.Camera

tex_atlas: k2.Texture

ARROW_RANGE      :: 58
ARROW_DAMPING    :: 0.996
ARROW_DAMAGE     :: 1
ARROW_SPEED_INIT :: 0.3
ARROW_SPEED_HIT  :: 0.03
ARROW_SPEED_MIN  :: 0.01

GOLDEN_RATIO  :: 1.618

BOARD_X           :: 140
BOARD_Y           :: 180
BOARD_N           :: BOARD_X*BOARD_Y
BOARD_SIZE        :: Vec2{BOARD_X, BOARD_Y}
BOARD_RECT_MARGIN :: 20

get_board_rect :: proc () -> (rect: Rect) {
    max := window_size - BOARD_RECT_MARGIN*2
    rect.size = fit_aspect_into(BOARD_SIZE, max)
    rect.pos = BOARD_RECT_MARGIN + (max - rect.size)/2
    return
}

check_winner :: proc () -> Maybe(Army_Side) {
    armies_loop: for army in armies {
        for compi in army.units {
            comp := company_get(compi)
            if len(comp.alive_units) > 0 do continue armies_loop
        }
        return side_opposite(army.side)
    }
    return nil
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
cell_idx :: proc (coord: Coord) -> (idx: Cell_Idx, ok: bool) #optional_ok {
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
cell_taken :: proc (idx: Cell_Idx, troopi: Troop_Idx) -> (is_taken: bool) {
    troop := cell_troop(idx) or_return
    return troop.info.si != troopi && troop_is_alive(troop.info.si)
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
    xy := [2]int{i%dim.x, i/dim.x}
    if xy.y % 2 == 1 {
        xy.x = dim.x - xy.x - 1
    }
    xy -= dim/2
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
troop_cell_idx :: proc (idx: Troop_Idx) -> Cell_Idx {
    coord := troop_get_coord(idx)
    return cell_idx(coord)
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
troop_company :: proc (idx: Troop_Idx) -> ^Company {
    return company_get(troop_company_idx(idx))
}
troop_config :: proc (idx: Troop_Idx) -> Unit_Config {
    return unit_config[company_get(troop_company_idx(idx)).kind]
}
troop_pos :: proc (idx: Troop_Idx) -> Vec2 {
    return troop_get(idx).pos
}
troop_update_time_left :: proc (t: Troop_Ptr) {
    t.movement.time_left = clamp(rand.float32_normal(500, 100), 200, 1000)
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
find_first_free_cell :: proc (origin: Vec2, troopi: Troop_Idx) -> Cell_Idx {

    for offset: Coord; /**/; offset = grid.next_surrounding_cell(offset) {

        celli := cell_idx(Coord(origin) + offset) or_continue
        if cell_taken(celli, troopi) do continue
        return celli
    }
}
troop_add_to_cell :: proc (s: Troop_Ptr, cell_idx: Cell_Idx) -> (ok: bool) {

    cell := grid.ptr_idx_safe(&board, cell_idx) or_return

    // cell taken
    if prev_troop, cell_has_prev_troop := cell.troop.?;
       cell_has_prev_troop && prev_troop != s.info.si {
        if troop_is_alive(prev_troop) {
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
troop_apply_force :: proc (troop: Troop_Ptr, e_idx: Cell_Idx, dt: f32) -> (moved: bool) {

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

    if troop.shooting.time > 0 {
        diff /= 2
    }

    // slower on corpses
    if cell_corpse(s_idx) {
        diff *= 0.75
    }

    if la.length(diff) < 0.01 && s_coord == e_coord {
        return true
    }

    config := unit_config[company_get(troop.info.compi).kind]

    troop.movement.velocity += diff * config.accel * dt // accelleration

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
        if troop.pos != pos {
            moved = true
            troop.pos = pos
        }
        if occupant, occupied := cell_troop(next_celli); occupied {
            troop_attack(troop, occupant)
        }
        return moved
    }

    return true
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
        for _, cell_idx in grid.slice(board) {
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
    coord: Coord
    for {
        coord = grid.next_surrounding_cell(coord)
        cell_idx = Cell_Idx(grid.idx(board, Coord(pos) + coord))

        if troop_add_to_cell(s, cell_idx) {
            s.pos = cell_center(cell_idx)
            return
        }
    }
}

game_initalized: bool

game_init :: proc () {

    if game_initalized do return
    game_initalized = true

    // clear previous state
    armies    = {}
    companies = {}
    arrows    = {}
    particles = {}

    // setup state arena
    if state_arena == {} {
        arena_init_err := runtime.arena_init(&state_arena, 0, context.allocator)
        assert(arena_init_err == nil, "Couldn't init state arena allocator")
    } else {
        runtime.arena_free_all(&state_arena)
    }

    state_allocator = runtime.arena_allocator(&state_arena)
    context.allocator = state_allocator

    update_frame_globals()

    board = grid.make(Cell, {BOARD_X, BOARD_Y})

    troops = make(Troop_Arr, 0, 10000)

    // each army
    for &army, side in armies {

        army.side  = side
        army.units = make([]Company_Idx, len(INIT_ARMY_UNITS))

        // each company
        for initial, ci in INIT_ARMY_UNITS {

            append_nothing(&companies)
            compi := Company_Idx(len(companies)-1)
            comp  := company_get(compi)

            army.units[ci] = compi

            comp.side   = side
            comp.idx    = compi
            comp.kind   = initial.kind

            units_count_ratio := armies_ratio if side == .Player else 1-armies_ratio
            units_count := int(f32(initial.count) / (units_count_ratio*2))
            comp.units = make([]Troop_Idx, units_count)

            comp_coord := initial.pos
            if side == .Player {
                comp_coord.y = BOARD_Y - comp_coord.y
            }

            comp_celli := cell_idx(comp_coord)
            comp.target = comp_celli

            // each troop
            for &si, i in comp.units {

                si = Troop_Idx(len(troops))
                comp.units[i] = si
                append_nothing_soa(&troops)

                s := troop_get(si)
                s.info.side  = side
                s.info.si    = si
                s.info.compi = compi

                rot: f32 = 0 if side == .Player else math.PI
                pos := each_army_goal_pos(cell_center(comp_celli), rot, i, units_count)
                troop_set_pos_force(s, pos)

                s.movement.path = make([dynamic]Cell_Idx)
                troop_update_time_left(s)
            }
        }
    }

    tex_atlas = k2.load_texture_from_bytes(#load(ATLAS_TEXTURE))
}

update_frame_globals :: proc () {
    frame_time   = k2.get_time()*1000
    window_size  = k2.get_screen_size()
    board_rect   = rect_fit_aspect_max(BOARD_SIZE, window_size, BOARD_RECT_MARGIN)
    camera_board = k2_camera_fit_aspect(BOARD_SIZE, BOARD_RECT_MARGIN)
    mouse_pos    = k2.get_mouse_position()
    mouse_world  = k2.screen_to_camera(mouse_pos, camera_board)
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

        celli := cell_idx(origin + coord) or_continue
        troopi := cell_get(celli).troop.? or_continue
        if troop_is_dead(troopi) do continue

        hovered_troop = troopi
        break
    }

    return true
}

update_companies :: proc () -> (ok: bool) {

    // update alive units array and average company position
    for &comp in companies {

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

    // don't target dead company
    for &comp in companies {
        target_idx := comp.target.(Company_Idx) or_continue
        target_company := company_get(target_idx)
        if len(target_company.alive_units) == 0 {
            comp.target = cell_idx_from_pos(comp.avg_pos)
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
                play_sfx(.Thud_Impact)
            }
        }
    }
    else if selected, is_selected := selected_company.?; is_selected {
        // cell target

        company_get(selected).target = cell_idx
        selected_company = nil // disselect after action
        play_sfx(.Thud_Impact)
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

troop_attack :: proc (troop, enemy: Troop_Ptr) -> (ok: bool) {

    if enemy.info.side == troop.info.side do return
    if troop_is_dead(enemy.info.si) do return

    tconfig := troop_config(troop.info.si)
    econfig := troop_config(enemy.info.si)

    dmg := tconfig.dmg_static + tconfig.dmg_move * la.length(troop.movement.velocity)
    dmg /= econfig.armor

    if econfig.armor > 1 && int(rand.uint64()) > 0 {
        play_sfx(.Shield_Impact)
    } else if int(rand.uint64()) > 0 {
        play_sfx(.Sword_Impact)
    } else {
        play_sfx(.Sword_Slash)
    }

    enemy.combat.in_fight += 0.8
    new_dmg := min(enemy.combat.dmg_taken + dmg, 1)
    if enemy.combat.dmg_taken < 1 && new_dmg >= 1 {
        play_sfx(.Thud_Impact)
    }
    enemy.combat.dmg_taken = new_dmg
    troop.combat.in_fight += 1

    return true
}

update_troop_target :: proc (troopi: Troop_Idx, dt: f32) -> (moved: bool) {

    troop_is_alive(troopi) or_return

    troop := troop_get(troopi)
    troop_coord := board_coord_from_pos(troop.pos)
    troop_celli := cell_idx(troop_coord)

    troop_comp := company_get(troop.info.compi)

    switch t in troop_comp.target {
    case Cell_Idx:
        // go to closest available cell to target cell

        // arrange only the alive troops
        alive_idx, _ := slice.binary_search(troop_comp.alive_units, troop.info.si)
        target_pos := cell_center(t)
        angle: f32
        if troop.info.side == .Enemy {
            angle = math.PI
        }
        if closest, found := company_find_closest(side_opposite(troop.info.side), target_pos); found {
            angle = vec2_angle(target_pos, company_get(closest).avg_pos) - math.PI/2
        }
        pos := each_army_goal_pos(target_pos, angle, alive_idx, len(troop_comp.alive_units))

        troop.movement.target = find_first_free_cell(pos, troopi)

    case Company_Idx:
        // go to closest available troop from target company

        // already next to an enemy
        for dir in grid.DIRECTION_VECTORS {

            cidx   := cell_idx(troop_coord + dir) or_continue
            ctroop := cell_troop(cidx) or_continue
            if ctroop.info.compi != t do continue

            troop_attack(troop, ctroop) or_continue
            troop.movement.target = cidx
            troop_apply_force(troop, troop_celli, dt)
            return true // moved
        }

        tcomp := company_get(t)

        if troop_comp.kind == .Archers {
            // Archers are ranged
            // - can move to closest cell that allows them to shoot
            // - do not require free spaces around the target
            // - can target any troop in range

            RANGE_MARGIN :: 6

            min_dist := math.inf_f32(1)
            min_troopi: Maybe(Troop_Idx)
            for etroopi in tcomp.alive_units {
                etroop := troop_get(etroopi)

                dist := la.length(etroop.pos - troop.pos)

                if dist < min_dist {
                    min_dist = dist
                    min_troopi = etroopi
                }
            }

            etroopi := min_troopi.? or_return
            etroop  := troop_get(etroopi)

            if min_dist < ARROW_RANGE {
                // no need to move
                troop.movement.target = troop_celli

                // begin shooting
                troop.shooting.time = rand.float32_range(2600, 4200)
                troop.shooting.target = etroopi
                troop.combat.in_fight += 1
                return
            }

            diff := etroop.pos - troop.pos
            diff -= la.normalize(diff) * (ARROW_RANGE-RANGE_MARGIN)

            pos := troop.pos + diff

            troop.movement.target = find_first_free_cell(pos, troopi)
            return
        }

        // find closest enemy troop
        context.user_index = int(troopi)
        closest_idx := util.slice_min_proc(tcomp.alive_units, proc (uidx: Troop_Idx) -> (val: f32, ok: bool) {

            troopi := Troop_Idx(context.user_index)
            pos := troop_pos(troopi)

            utroop := troop_get(uidx)
            ucoord := troop_get_coord(uidx)

            troop_is_alive(uidx) or_return

            is_accessable: {
                for dir in grid.DIRECTION_VECTORS {
                    cidx := cell_idx(ucoord + dir) or_continue
                    if cell_taken(cidx, troopi) do continue
                    break is_accessable
                }

                return 0, false
            }

            return la.distance(pos, utroop.pos), true
        }) or_break

        troop.movement.target = find_first_free_cell(troop_pos(closest_idx), troopi)
    }

    return false
}

update_troops :: proc (dt: f32) -> (ok: bool) {

    // clear in_fight for all troops
    // before update_troops sets it
    for _, i in troops {
        troop := &troops[i]
        troop.combat.in_fight = 0
    }

    update_troops:
    for _, troopi_int in troops {
        troopi := Troop_Idx(troopi_int)
        troop  := &troops[troopi]

        if troop_is_dead(troopi) do continue

        troop_coord := board_coord_from_pos(troop.pos)
        troop_cell_idx := cell_idx(troop_coord)

        troop_comp := company_get(troop.info.compi)
        troop_config := unit_config[troop_comp.kind]

        troop.movement.time_left -= dt
        time_to_update := troop.movement.time_left <= 0
        if time_to_update {
            troop_update_time_left(troop)
        }

        troop.movement.velocity *= math.pow(troop_config.frict, dt) // damping

        if time_to_update && la.length(troop.movement.velocity) > 0.002 {

            switch troop_company(troopi).kind {
            case .Infantry, .Heavy, .Archers: play_sfx(.Infantry_Run)
            case .Riders:                     play_sfx(.Horse_Run)
            }

            spawn_dust_cloud(troop.pos, la.length(troop.movement.velocity) * troop_config.armor)
        }

        // handle archers shooting before any movement
        shooting: if troop_comp.kind == .Archers && troop.shooting.time > 0 {

            troop.combat.in_fight += 1

            troop.shooting.time -= dt
            if troop.shooting.time > 0 {
                continue update_troops
            }
            troop.shooting.time = 0

            miss_by: Vec2
            miss_by.x = rand.float32_range(-2, 2)
            miss_by.y = rand.float32_range(-2, 2)

            target := troop_get(troop.shooting.target)
            target_pos := target.pos + target.movement.velocity + miss_by
            target_celli := cell_idx_from_pos(target_pos) or_break shooting

            dist := la.distance(troop.pos, target_pos)
            speed := dist * math.ln(f32(1) / ARROW_DAMPING) + rand.float32_range(0, 0.16)

            append(&arrows, Arrow{
                from  = troop.pos,
                pos   = troop.pos,
                end   = target_celli,
                speed = speed,
            })
            play_sfx(.Arrow_Swish)

            troop_apply_force(troop, troop_cell_idx, dt)

            continue update_troops
        }

        if time_to_update {
            if update_troop_target(troopi, dt) {
                continue update_troops // moved
            }

            // attack
            for dir in grid.DIRECTION_VECTORS {
                cidx := cell_idx(troop_coord + dir) or_continue
                ctroop := cell_troop(cidx) or_continue
                troop_attack(troop, ctroop) or_continue
                break
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
                break direct
            }

            troop.movement.prefer = .Target
            if !troop_apply_force(troop, target, dt) {
                troop.movement.prefer = .Path
            }
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
            if troop_cell_idx == next {
                pop_front(&troop.movement.path)
                if len(troop.movement.path) > 0 {
                    next = troop.movement.path[0]
                } else {
                    troop.movement.prefer = .Target
                    break by_path
                }
            }

            troop_apply_force(troop, next, dt)
            continue update_troops
        }

        // fallback: move to center of own cell
        troop_apply_force(troop, troop_cell_idx, dt)
    }

    return true
}

update_arrows :: proc (dt: f32) -> (ok: bool) {

    #reverse for &arrow, i in arrows {

        end_pos := cell_center(arrow.end)
        arrow.speed *= math.pow(ARROW_DAMPING, dt)
        arrow.pos   += la.normalize(end_pos-arrow.from) * arrow.speed * dt

        do_check_hit: bool
        do_remove_after: bool

        if cell_idx_from_pos(arrow.pos) == arrow.end || arrow.speed < ARROW_SPEED_MIN {
            do_check_hit = true
            do_remove_after = true
        }

        if arrow.speed < ARROW_SPEED_HIT {
            do_check_hit = true
        }

        end_coord := cell_coord(arrow.end)
        pos_coord, _ := board_coord_from_pos(arrow.pos)
        coord_diff := la.abs(end_coord - pos_coord)
        if coord_diff.x <= 1 && coord_diff.y <= 1 && Coord(arrow.from) != pos_coord {
            do_check_hit = true
        }

        check_hit: if do_check_hit {
            pos_celli := cell_idx(pos_coord) or_break check_hit
            pos_troop := cell_troop(pos_celli) or_break check_hit
            if troop_is_dead(pos_troop.info.si) do break check_hit

                pos_troop_config := troop_config(pos_troop.info.si)
                was_alive := pos_troop.combat.dmg_taken < 1
                pos_troop.combat.dmg_taken += 1 / pos_troop_config.armor
                play_sfx(.Arrow_Impact)
                if was_alive && pos_troop.combat.dmg_taken >= 1 {
                    play_sfx(.Thud_Impact)
                }
                do_remove_after = true
        }

        if do_remove_after {
            unordered_remove(&arrows, i)
        }
    }

    return true
}

update_particles :: proc (dt: f32) {
    #reverse for &p, i in particles {

        if frame_time - p.start >= f64(p.life) {
            unordered_remove(&particles, i)
            continue
        }

        r := rand.float32_laplace(0.002, 0.002)
        p.pos.y += r * dt
        p.pos.x += r * dt
        p.rot   += r/10 * dt
    }
}

spawn_dust_cloud :: proc (pos: Vec2, vel: f32) {
    life := vel * 100_000
    if life <= 1 do return
    life += rand.float32_range(0, 1600)
    append(&particles, Particle{
        kind  = .Dust,
        pos   = pos,
        rot   = rand.float32(),
        life  = life,
        start = frame_time,
    })
}

draw_board :: proc () {
    k2.draw_rect_vec(0, BOARD_SIZE, COLOR_BOARD)
}

draw_troop_shadows :: proc () {
    for troop, i in troops {
        si := Troop_Idx(i)
        troop_is_alive(si) or_continue
        k2.draw_circle(troop.pos, 3, COLOR_SHADOW, segments=8)
    }
}

draw_corpses :: proc () {
    for _, celli_int in grid.slice(board) {
        celli := Cell_Idx(celli_int)
        cell_corpse(celli) or_continue

        coord := cell_coord(celli)
        pos   := cell_center(celli)

        cell_hash :: proc(p: Coord) -> u32 {
            h := u32(p.x) * 73856093
            h ~= u32(p.y) * 19349663
            h ~= h >> 13
            h *= 1274126177
            h ~= h >> 16
            return h
        }
        h := cell_hash(coord)

        atlas_slice: Atlas_Slice
        MAX_SLICE :: 3
        switch h % MAX_SLICE {
        case 0: atlas_slice = .Corpse_1
        case 1: atlas_slice = .Corpse_2
        case 2: atlas_slice = .Corpse_3
        }

        rot := f32((h / MAX_SLICE) % 4) * (PI * 0.5)

        tex_rect := atlas_rects[atlas_slice]
        size := fit_aspect_into_min(tex_rect.size, 2)
        rect := Rect{pos-size/2, size}

        draw_texture(tex_atlas, rect, tex_rect, rot=rot)
    }
}

TROOP_MAX_SIZE :: f32(2.4) // in world pixels (cells)

draw_troops :: proc () {
    for troop, i in troops {
        si := Troop_Idx(i)
        troop_is_alive(si) or_continue

        pos := troop.pos

        rot: f32
        if la.length(troop.movement.velocity) > 0.01 {
            rot = vec2_angle(0, troop.movement.velocity) - HALF_PI
        } else if target, has_target := troop.movement.target.?;
                  has_target && la.distance(pos, cell_center(target)) > 0.1 {
            rot = vec2_angle(pos, cell_center(target)) - HALF_PI
        } else if troop.shooting.time > 0 {
            rot = vec2_angle(pos, troop_pos(troop.shooting.target)) - HALF_PI
        } else if troop.info.side == .Enemy {
            rot = PI
        }

        tint := color.lerp(k2.WHITE, k2.DARK_GRAY, troop.combat.dmg_taken/2)
        if htroopi, has_hovered := hovered_troop.?;
           has_hovered && troop_company_idx(htroopi) == troop_company_idx(si) {
            tint = k2.BLUE
        }

        tex_slice: Atlas_Slice
        switch troop_company(si).kind {
        case .Infantry: tex_slice = .Infantry_Player if troop.info.side == .Player else .Infantry_Enemy
        case .Archers:  tex_slice = .Archer_Player   if troop.info.side == .Player else .Archer_Enemy
        case .Heavy:    tex_slice = .Heavy_Player    if troop.info.side == .Player else .Heavy_Enemy
        case .Riders:   tex_slice = .Rider_Player    if troop.info.side == .Player else .Rider_Enemy
        }

        tex_rect := atlas_rects[tex_slice]
        size := fit_aspect_into_min(tex_rect.size, TROOP_MAX_SIZE)
        rect := Rect{pos-size/2, size}

        draw_texture(tex_atlas, rect, tex_rect, rot=rot, tint=tint)
    }
}

draw_arrows :: proc () {
    for arrow in arrows {
        end := cell_center(arrow.end)
        angle := vec2_angle(arrow.from, end)
        line := [2]Vec2{0, {2, 0}}
        line[1] = vec2_rotate(line[1], angle)
        line[0] += arrow.pos
        line[1] += arrow.pos
        k2.draw_line(line[0], line[1], 0.2, COLOR_ARROWS)
    }
}

pulse :: proc(t, peak: f32) -> f32 {
	if t < peak {
		return math.sin((t / peak) * (math.PI * 0.5))
	}

	return math.sin(((1 - t) / (1 - peak)) * (math.PI * 0.5))
}

draw_particles :: proc () {
    size := fit_aspect_into_min(atlas_rects[.Dust_Cloud].size, 3)
    for p in particles {
        t := f32(frame_time - p.start) / p.life
        alpha := u8(t * 200)
        size := size
        size *= pulse(t, 0.12)
        draw_texture(tex_atlas, {p.pos-size/2, size}, atlas_rects[.Dust_Cloud], tint={255,255,255,alpha}, rot=p.rot)
    }
}

draw_company_targets :: proc () {
    for comp in companies do if len(comp.alive_units) > 0 {

        start := comp.avg_pos
        end   := comp.avg_pos

        switch t in comp.target {
        case Cell_Idx:
            end = cell_center(t)
        case Company_Idx:
            tcomp := company_get(t)
            end = tcomp.avg_pos
        }

        if start == end {
            draw_cross(start, k2.YELLOW)
        } else {
            k2.draw_line(start, end, 0.5, k2.YELLOW)
        }
    }
}

draw_selected_company :: proc () {
    if compi, is_selected := selected_company.?; is_selected {
        comp := company_get(compi)
        army := armies[comp.side]

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
            k2.draw_line(a, b, 0.6, army_colors[army.side].dark)
        }
    }
}

frame :: proc (dt: f32) -> bool {

    update_frame_globals()

    game_init()
    context.allocator = state_allocator // state_arena

    if ui_view == .Game {
        update_companies()
        update_hover()
        update_click()
        update_automatic()
        update_troops(dt)
        update_arrows(dt)

        winner := check_winner()
        if winner != nil {
            ui_view = .End
        }
    }

    update_particles(dt) // Always update particles since they are only visual

    if k2.key_went_down(.Q) { // Quit
        return false
    }
    if k2.key_went_down(.R) { // Restart
        game_initalized = false
    }

    if k2.key_went_down(.Escape) { // Esc to main menu
        switch ui_view {
        case .Main_Menu: ui_view = .Game
        case .Game:      ui_view = .Main_Menu
        case .End:
        }
    }

    post_start()

    {
        k2.clear(COLOR_BG)

        k2.set_camera(camera_board)

        draw_board()
        draw_troop_shadows()
        draw_corpses()
        draw_troops()
        draw_arrows()
        draw_particles()
        draw_company_targets()
        draw_selected_company()

        k2.set_camera(nil)

        ui_frame()
    }

    post_end()

    return true
}

