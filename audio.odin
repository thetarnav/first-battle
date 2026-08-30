package first_battle

import k2 "./karl2d"
import "core:math/rand"

Sound_Effect_Kind :: enum {
    Sword_Slash,
    Sword_Impact,
    Arrow_Swish,
    Arrow_Impact,
    Shield_Impact,
    Thud_Impact,
    Infantry_Run,
    Horse_Run,
}

SFX_Config :: struct {
    volume:    f32,
    pitch_var: f32,
    cooldown:  f32,
    cap:       int,
}

SFX_GLOBAL_CAP :: 12

sfx_config := [Sound_Effect_Kind]SFX_Config{
    .Sword_Slash   = {volume=0.45, pitch_var=0.1,  cooldown=100, cap=3},
    .Sword_Impact  = {volume=0.5,  pitch_var=0.15, cooldown=100, cap=3},
    .Arrow_Swish   = {volume=0.3,  pitch_var=0.2,  cooldown=80,  cap=4},
    .Arrow_Impact  = {volume=0.24, pitch_var=0.2,  cooldown=200, cap=3},
    .Shield_Impact = {volume=0.44, pitch_var=0.1,  cooldown=100, cap=3},
    .Thud_Impact   = {volume=0.4,  pitch_var=0.15, cooldown=200, cap=3},
    .Infantry_Run  = {volume=0.25, pitch_var=0.05, cooldown=0,   cap=2},
    .Horse_Run     = {volume=0.3,  pitch_var=0.05, cooldown=200, cap=2},
}

songs_bytes := [][]byte{
    #load("audio/montogoronto-dark-orchestral-battle-tension-395613.ogg"),
    #load("audio/rolandomat-epic-battle-song-182915.ogg"),
}

sfx_bytes := [Sound_Effect_Kind][][]byte{
    .Sword_Slash = {
        #load("audio/54427377-sword-slash-476148.ogg"),
        #load("audio/dragon-studio-sword-slice-393847.ogg"),
        #load("audio/freesound_community-sword-sound-2-36274.ogg"),
        #load("audio/musicholder-sword-sound-260274.ogg"),
    },
    .Sword_Impact = {
        #load("audio/dragon-studio-sword-fight-393849.ogg"),
        #load("audio/universfield-sword-blade-slicing-flesh-352708.ogg"),
    },
    .Arrow_Swish = {
        #load("audio/djartmusic-arrow-swish_03-306040.ogg"),
    },
    .Arrow_Impact = {
        #load("audio/dennish18-arrow-body-impact-146419.ogg"),
        #load("audio/dennish18-arrow-wood-impact-146418.ogg"),
    },
    .Thud_Impact = {
        #load("audio/virtual_vibes-thud-impact-sound-sfx-379990.ogg"),
    },
    .Shield_Impact = {
        #load("audio/yodguard-shield_impact-1-382410.ogg"),
        #load("audio/yodguard-shield_impact-5-382415.ogg"),
    },
    .Infantry_Run = {
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486.ogg"),
    },
    .Horse_Run = {
        #load("audio/pwlpl-horses-galloping-sound-effect-359257.ogg"),
    },
}

SFX_Stream :: struct {
    stream:   k2.Audio_Stream,
    cooldown: f32,
}
sfx_streams: [Sound_Effect_Kind][][dynamic]SFX_Stream
sfx_to_play: [Sound_Effect_Kind]bool

songs_streams: []k2.Audio_Stream
active_song: int

g_mute: bool

play_sfx :: proc (kind: Sound_Effect_Kind) {
    sfx_to_play[kind] = true
}

audio_init :: proc () {
    // create streams for all songs
    songs_streams = make([]k2.Audio_Stream, len(songs_bytes))
    for bytes, i in songs_bytes {
        songs_streams[i] = k2.load_audio_stream_from_bytes(bytes)
    }
    // create arrays for sfx
    for &streams_by_sfx, kind in sfx_streams {
        streams_by_sfx = make(type_of(streams_by_sfx), len(sfx_bytes[kind]))
        for &streams in streams_by_sfx {
            streams = make(type_of(streams))
        }
    }
}

audio_frame :: proc (dt: f32) {
    if g_mute do return

    // update music songs
    k2.update_audio_stream(songs_streams[active_song])
    if !k2.is_audio_stream_playing(songs_streams[active_song]) {
        k2.pause_audio_stream(songs_streams[active_song])
        active_song = (active_song+1) % len(songs_streams)
        k2.play_audio_stream(songs_streams[active_song])
    }

    // update all sfx
    sfx_playing_count_all: int
    for streams_by_sfx in sfx_streams {
        for streams in streams_by_sfx {
            for &s in streams {
                k2.update_audio_stream(s.stream)
                if k2.is_audio_stream_playing(s.stream) {
                    sfx_playing_count_all += 1
                } else {
                    s.cooldown += dt
                }
            }
        }
    }

    // play new sfx
    defer sfx_to_play = {}
    for kind_requested, kind in sfx_to_play do if kind_requested {

        kind_cfg     := sfx_config[kind]
        kind_streams := sfx_streams[kind]
        assert(len(kind_streams) > 0)

        sfx_playing_count_kind: int
        for streams in kind_streams {
            for s in streams {
                if k2.is_audio_stream_playing(s.stream) ||
                   s.cooldown < sfx_config[kind].cooldown {
                    sfx_playing_count_kind += 1
                }
            }
        }

        if sfx_playing_count_all  >= SFX_GLOBAL_CAP do break
        if sfx_playing_count_kind >= kind_cfg.cap do break

        sfx_idx := rand.int_max(len(kind_streams))
        streams := &kind_streams[sfx_idx]

        stream: ^SFX_Stream
        get_stream: {
            for &s in streams {
                if !k2.is_audio_stream_playing(s.stream) {
                    // reuse finished stream
                    stream = &s
                    break get_stream
                }
            }
            // add new stream for this sfx
            append_nothing(streams)
            stream = &streams[len(streams)-1]
            stream.stream = k2.load_audio_stream_from_bytes(sfx_bytes[kind][sfx_idx])
        }

        k2.set_audio_stream_pitch(stream.stream, 1 + rand.float32_range(-kind_cfg.pitch_var, kind_cfg.pitch_var))
        k2.set_audio_stream_volume(stream.stream, kind_cfg.volume * rand.float32_range(-0.2, 0.2))
        k2.play_audio_stream(stream.stream)
        sfx_playing_count_all += 1
        sfx_playing_count_kind += 1
        stream.cooldown = 0
    }
}

audio_toggle_mute :: proc (mute: Maybe(bool) = nil) {

    new_mute := mute.? or_else !g_mute

    if g_mute == new_mute do return
    g_mute = new_mute

    if g_mute {
        k2.pause_audio_stream(songs_streams[active_song])
    } else {
        k2.play_audio_stream(songs_streams[active_song])
    }
}

