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
    pos:    Vec2,
    target: struct {
        pos:        Vec,
        left_steps: int,
    }
}

// Target :: union {Vec, Soldier_Handle}
//
// Soldier_Handle :: struct {
//     side: Army_Side,
//     idx:  int,
// }

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

        army_dim_n := army_count_dim(army_n)

        reserve(&army.soldiers, army_n)
        resize (&army.soldiers, army_n)

        for &s, i in army.soldiers {
            ix  := i%army_dim_n.x
            iy  := i/army_dim_n.x
            s.pos = army_pos + Vec2{f32(ix), f32(iy)} * UNIT_S + UNIT_M + UNIT_W/2
        }
    }
}

init :: proc () {
    k2.init(1280, 720, "Greetings from Karl2D!", {
        window_mode = .Windowed_Resizable,
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
    mouse_target: Maybe(Vec)

    mouse_pos := k2.get_mouse_position()
    draw_cross(mouse_pos, k2.GREEN)

    if k2.mouse_button_is_held(.Left) {
        mouse_target = mouse_pos
    }

    goal := Vec2{500, 500}
    if target, ok := mouse_target.?; ok {
        goal = target
    }
    draw_cross(goal, k2.ORANGE)

    for army in armies {
        op_army_side := side_opposite(army.side)
        op_army      := armies[op_army_side]

        op_army_points := op_army.soldiers.pos[:len(op_army.soldiers)]
        op_army_tree   := qt.build(op_army_points, context.temp_allocator)

        for &s, i in army.soldiers {

            // set target
            if s.target.left_steps == 0 {
                if army.side == .Player {
                    s.target.pos = goal
                    s.target.left_steps = rand.int_range(1, 10)
                } else {
                    p, found := qt.query_nearest(op_army_tree, s.pos)
                    if found {
                        s.target.pos = p.pos
                        s.target.left_steps = rand.int_range(1, 10)
                    }
                }
            }

            // update pos towards target
            update: if s.target.left_steps != 0 {
                s.target.left_steps -= 1
                d := s.pos - s.target.pos
                if d == 0 do break update
                n := s.pos - la.normalize(d)
                if !math.is_nan(n.x) &&
                   !math.is_nan(n.y) &&
                   !math.is_inf(n.x) &&
                   !math.is_inf(n.y) {
                    s.pos = n
                }
            }

            k2.draw_circle(s.pos, UNIT_W/2, army.color)
        }
        // k2.draw_text(army.name, army_pos - {0, 20}, 20, color)
    }

    fps := dt*60*1000
    k2.draw_text(fmt.tprint(int(fps)), 11, 20, k2.GREEN)

    k2.present()

    free_all(context.temp_allocator)

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

