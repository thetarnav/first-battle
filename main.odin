package first_battle

import "core:time"
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

time_now :: proc () -> f32 {
    @static start: time.Time
    if start == {} {
        start = time.now()
    }
    return f32(time.duration_milliseconds(time.since(start)))
}

step :: proc () -> bool {

    k2.update() or_return

    @static time_last_update: f32

    time_now_update  := time_now()
    dt_update        := time_now_update - time_last_update
    capped_dt_update := min(dt_update, MAX_DT*2)

    time_last_update = time_now_update
    update(capped_dt_update) or_return

    @static time_last_frame: f32
    @static time_miss_frame: f32

    time_now_frame   := time_now()
    dt_frame         := time_now_frame - time_last_frame
    elapsed_frame    := dt_frame  + time_miss_frame
    capped_dt_frame  := min(dt_frame, MAX_DT*2)

    if elapsed_frame < MAX_DT {
        return true
    }

    time_last_frame = time_now_frame
    time_miss_frame = max(0, elapsed_frame - MAX_DT) // Carry over extra time
    frame(capped_dt_frame) or_return

    fps := 1000.0/dt_frame
    k2.draw_text(fmt.tprint(int(fps)), 11, 20, k2.GREEN)

    k2.present()

    free_all(context.temp_allocator)

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

