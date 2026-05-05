package first_battle

import "core:fmt"
import k2 "./karl2d"

main :: proc () {
    init()
    for step() {}
    shutdown()
}

init :: proc () {
    k2.init(1280, 720, "Greetings from Karl2D!", {
        window_mode = .Windowed_Resizable,
        // window_mode = .Borderless_Fullscreen,
    })
    game_init()
}

MAX_FPS :: 60.0
MIN_FPS :: 12.0

MAX_DT :: 1000.0 / MAX_FPS
MIN_DT :: 1000.0 / MIN_FPS

step :: proc () -> bool {

    k2.update() or_return

    @static time_last: f32
    time_now := f32(k2.get_time() * 1000)

    dt := time_now - time_last

    @static time_missed: f32
    elapsed := dt + time_missed

    capped_dt := min(dt, MAX_DT*2)

    update(capped_dt) or_return

    if elapsed < MAX_DT {
        return true
    }

    time_last = time_now
    time_missed = max(0, elapsed - MAX_DT) // Carry over extra time

    frame(capped_dt) or_return

    fps := 1000.0/dt
    k2.draw_text(fmt.tprint(int(fps)), 11, 20, k2.GREEN)

    k2.present()

    free_all(context.temp_allocator)

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

