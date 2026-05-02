package first_battle

import "core:math"
import la "core:math/linalg"
import "core:fmt"
import k2 "./karl2d"

Vec2  :: k2.Vec2
Color :: k2.Color

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
    soldiers: [dynamic]Soldier,
}

Soldier :: struct {
    pos:    Vec2,
    target: Maybe(Soldier_Handle),
}

Soldier_Handle :: struct {
    side: Army_Side,
    idx:  int,
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
    k2.init(1280, 720, "Greetings from Karl2D!")

    init_armies()
}

RATIO  :: 1.618
UNIT_W :: 4
UNIT_M :: 3
UNIT_S :: UNIT_W + UNIT_M*2

step :: proc () -> bool {
 
    k2.update() or_return

    k2.clear(k2.LIGHT_BLUE)

    k2.draw_text("Hellope!", {50, 50}, 100, k2.DARK_BLUE)

    ws     := k2.get_screen_size()
    wscale := k2.get_window_scale()
    wc     := ws/wscale/2

    for army in armies {
        op_army_side := side_opposite(army.side)
        op_army      := armies[op_army_side]
        for &s, i in army.soldiers {

            // set target
            if _, has_target := s.target.?; !has_target {
                s.target = Soldier_Handle{
                    side = op_army_side,
                    idx  = 0,
                }
            }

            // update pos towards target
            if target, has_target := s.target.?; has_target {
                c := la.normalize(s.pos - op_army.soldiers[target.idx].pos)
                if !math.is_nan(c.x) ||
                   !math.is_nan(c.y) {
                    s.pos -= c
                }
            }

            k2.draw_circle(s.pos, UNIT_W/2, army.color)
        }
        // k2.draw_text(army.name, army_pos - {0, 20}, 20, color)
    }

    k2.present()

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

