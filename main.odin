package first_battle

import "core:time"
import "core:fmt"
import k2 "./karl2d"

_ :: fmt

main :: proc () {
    init()
    for step() {}
    shutdown()
}

init :: proc () {
    k2.init(1280, 720, "Greetings from Karl2D!", {
        window_mode = .Windowed_Resizable,
    })
    audio_init()
    post_init()
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

    @static time_last: f32
    @static time_miss: f32

    time_now   := time_now()
    dt         := time_now - time_last
    elapsed    := dt + time_miss
    capped_dt  := min(dt, MAX_DT*2)

    if elapsed < MAX_DT {
        return true
    }

    time_last = time_now
    time_miss = max(0, elapsed - MAX_DT) // Carry over extra time

    k2.update() or_return
    frame(capped_dt) or_return
    audio_frame(capped_dt)

    when ODIN_DEBUG {
        fps := 1000.0/dt
        k2.draw_text(fmt.tprint(int(fps)), 11, 20, k2.WHITE)
    }

    when ODIN_DEBUG {
        y: f32
        sfx_playing_count: [SFX_Kind]int
        get_sfx_playing_by_kind(&sfx_playing_count)
        for count, kind in sfx_playing_count {
            if count == 0 do continue
            k2.draw_text(fmt.tprintf("%v = %v", kind, count), {20, 50} + {0, y}, 26, k2.WHITE)
            y += 26
        }
    }

    k2.present()

    free_all(context.temp_allocator)

    return true
}

shutdown :: proc() {
    k2.shutdown()
}

