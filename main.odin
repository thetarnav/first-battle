package first_battle

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import k2 "./karl2d"
import qt "./quadtree"

Vec2  :: k2.Vec2
Color :: k2.Color
Vec   :: Vec2

main :: proc () {
    init()
    for step() {}
    shutdown()
}

Army_Side :: enum {Player, Enemy}

Army :: struct {
    side:     Army_Side,
    name:     string,
    color:    Color,
    soldiers: #soa[dynamic]Soldier,
}

Soldier :: struct {
    pos:       Vec2,
    in_fight:  f32,
    dmg_taken: f32,
    target:    struct {
        idx:        Maybe(int),
        pos:        Vec,
        left_steps: int,
    }
}

armies: [Army_Side]Army = {
    .Player = {side=.Player, name="Player", color=k2.GREEN},
    .Enemy  = {side=.Enemy,  name="Enemy",  color=k2.RED},
}

army_player := &armies[.Player]
army_enemy  := &armies[.Enemy]

army_count_dim :: proc (n: int) -> (res: [2]int) {
    res.y = int(math.sqrt(f32(n)/RATIO))
    res.x = int(f32(n)/f32(res.y))
    return
}

side_opposite :: proc (side: Army_Side) -> Army_Side {
    return Army_Side((int(side)+1) % (int(max(Army_Side))+1))
}

each_army_goal_pos :: proc (origin: Vec, i: int, n: int) -> (p: Vec) {
    dim := army_count_dim(n)
    ix  := i%dim.x
    iy  := i/dim.x
    return origin + Vec2{f32(ix), f32(iy)} * UNIT_S + UNIT_M + UNIT_W/2
}

is_dead :: proc (s: Soldier) -> bool {
    return s.dmg_taken >= 1
}

init_armies :: proc () {

    for &army in armies {
        army_pos: Vec2
        army_n:   int
        switch army.side {
        case .Player: army_pos = {40, 40}
                      army_n   = 321
        case .Enemy:  army_pos = {50, 400}
                      army_n   = 420
        }

        reserve(&army.soldiers, army_n)
        resize (&army.soldiers, army_n)

        for &s, i in army.soldiers {
            s.pos = each_army_goal_pos(army_pos, i, army_n)
        }
    }
}

init :: proc () {
    k2.init(1280, 720, "Greetings from Karl2D!", {
        // window_mode = .Windowed_Resizable,
    })

    init_armies()
}

RATIO  :: 1.618
UNIT_W :: 4
UNIT_M :: 3
UNIT_S :: UNIT_W + UNIT_M*2

draw_cross :: proc (pos: Vec, color: Color) {
    k2.draw_line(pos - {20, 0}, pos + {20, 0}, 3, color)
    k2.draw_line(pos - {0, 20}, pos + {0, 20}, 3, color)
}

step :: proc () -> bool {
 
    k2.update() or_return

    dt := k2.get_frame_time()

    k2.clear({12, 10, 9, 255})

    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)

    ws := k2.get_screen_size()
    wc := ws/2

    draw_cross(wc, k2.DARK_GRAY)

    @static
    mouse_target: union{vec2, Army_Side}

    mouse_pos := k2.get_mouse_position()
    draw_cross(mouse_pos, k2.GREEN)

    @static
    prev_outlines: [Army_Side]Maybe([]vec2)

    check_mouse: if k2.mouse_button_is_held(.Left) {
        for outline, side in prev_outlines {
            o := outline.? or_continue
            if point_in_polygon(mouse_pos, o) {
                mouse_target = side
                break check_mouse
            }
        }
        mouse_target = mouse_pos
    }

    if target, ok := mouse_target.(vec2); ok {
        draw_cross(target, k2.ORANGE)
    }

    non_dead_soldiers: [Army_Side][]int
    for army in armies {
        array := make([dynamic]int, 0, len(army.soldiers), allocator=context.temp_allocator)
        for s, i in army.soldiers {
            if is_dead(s) do continue
            append(&array, i)
        }
        non_dead_soldiers[army.side] = array[:]
    }

    army_trees: [Army_Side]qt.Quadtree
    for army in armies {

        army_points := make([]qt.Point, len(non_dead_soldiers[army.side]), allocator=context.temp_allocator)
        for si, i in non_dead_soldiers[army.side] {
            army_points[i] = qt.Point{
                pos = army.soldiers[si].pos,
                idx = si,
            }
        }
        army_trees[army.side] = qt.build(army_points, context.temp_allocator)
    }

    // set target
    for army in armies {
        op_army := armies[side_opposite(army.side)]
        op_army_tree := army_trees[op_army.side]

        for si, i in non_dead_soldiers[army.side] {
            s := &army.soldiers[si]

            if s.target.left_steps > 0 do continue

            goal_loc, has_goal := mouse_target.(vec2)

            if army.side == .Player {
                switch t in mouse_target {
                case nil:
                    s.target = {}
                    continue
                case vec2:
                    s.target.pos = each_army_goal_pos(t, i, len(non_dead_soldiers[army.side]))
                    s.target.left_steps = rand.int_range(6, 16)
                    continue
                case Army_Side:
                    if t == army.side {
                        s.target = {}
                        continue
                    } else {
                        break // attack
                    }
                }
            }

            // attack
            p, found := qt.query_nearest(op_army_tree, s.pos)
            if found {
                s.target.idx        = p.idx
                s.target.pos        = p.pos
                s.target.left_steps = rand.int_range(10, 24)

                enemy := &op_army.soldiers[p.idx]
                if distance(enemy.pos, s.pos) < 10 {
                    enemy.in_fight  += 0.8
                    enemy.dmg_taken += 0.05
                    s.in_fight      += 1
                    s.dmg_taken     += 0.04
                    continue
                }
            }
        }
    }

    for army in armies {
        for &s, i in army.soldiers {
            // update pos towards target
            update: {

                if is_dead(s) do break update

                if s.target.left_steps == 0 do break update
                s.target.left_steps -= 1

                d := s.pos - s.target.pos
                if d == 0 do break update
                d = la.normalize(d)

                // in fight is slower
                if s.in_fight > 0 {
                    d /= Vec(s.in_fight+1)
                    s.in_fight = 0
                }

                // slow down damaged individuals
                d *= Vec((1-s.dmg_taken)/2+0.5)

                n := s.pos - d
                if !math.is_nan(n.x) &&
                   !math.is_nan(n.y) &&
                   !math.is_inf(n.x) &&
                   !math.is_inf(n.y) {
                    s.pos = n
                }
            }

            color := army.color
            if is_dead(s) {
                color = k2.DARK_GRAY
            }
            k2.draw_circle(s.pos, UNIT_W/2, color)
        }
    }

    for army, side in non_dead_soldiers {
        points := make([dynamic]vec2, 0, len(army), allocator=context.temp_allocator)
        for si in army {
            s := armies[side].soldiers[si]
            append(&points, s.pos)
        }
        outline := convex_hull(points[:], allocator=context.temp_allocator)
        if len(outline) < 3 && len(army) > 0 {
            p := armies[side].soldiers[army[0]].pos
            outline = {
                p + {+6, +3},
                p + {-6, +3},
                p + { 0, -3},
            }
        }

        outline = expand_convex_polygon(outline, 10, allocator=context.allocator)
        for i in 0..<len(outline) {
            a, b := outline[i], outline[(i+1)%len(outline)]
            k2.draw_line(a, b, 3, k2.GRAY)
        }

        if o, ok := prev_outlines[side].?; ok {
            delete(o)
        }
        prev_outlines[side] = outline
    }

    fps := dt*60*1000
    k2.draw_text(fmt.tprint(int(fps)), 11, 20, k2.GREEN)

    k2.draw_text(fmt.tprintf("player army = %d", len(non_dead_soldiers[.Player])), {10, 30}, 20, k2.WHITE)
    k2.draw_text(fmt.tprintf("enemy  army = %d", len(non_dead_soldiers[.Enemy])),  {10, 50}, 20, k2.WHITE)

    k2.present()

    free_all(context.temp_allocator)

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

