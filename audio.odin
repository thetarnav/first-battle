package first_battle

import "core:math/rand"

import k2 "./karl2d"

SFX_Kind :: enum {
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

SFX_GLOBAL_CAP :: 32

sfx_config := [SFX_Kind]SFX_Config{
    .Sword_Slash   = {volume=0.42, pitch_var=0.15, cooldown=100, cap=4},
    .Sword_Impact  = {volume=0.5,  pitch_var=0.15, cooldown=100, cap=4},
    .Arrow_Swish   = {volume=0.3,  pitch_var=0.2,  cooldown=80,  cap=5},
    .Arrow_Impact  = {volume=0.24, pitch_var=0.2,  cooldown=200, cap=3},
    .Shield_Impact = {volume=0.44, pitch_var=0.1,  cooldown=150, cap=2},
    .Thud_Impact   = {volume=0.4,  pitch_var=0.15, cooldown=200, cap=3},
    .Infantry_Run  = {volume=0.5,  pitch_var=0.25, cooldown=60,  cap=20},
    .Horse_Run     = {volume=0.4,  pitch_var=0.05, cooldown=200, cap=2},
}

songs_bytes := [][]byte{
    #load("audio/montogoronto-dark-orchestral-battle-tension-395613.ogg"),
    #load("audio/rolandomat-epic-battle-song-182915.ogg"),
}

sfx_bytes := [SFX_Kind][][]byte{
    .Sword_Slash = {
        #load("audio/54427377-sword-slash-476148.ogg"),
        #load("audio/dragon-studio-sword-slice-393847.ogg"),
        #load("audio/freesound_community-sword-sound-2-36274.ogg"),
        #load("audio/musicholder-sword-sound-260274.ogg"),
        #load("audio/universfield-sword-blade-slicing-flesh-352708.ogg"),
    },
    .Sword_Impact = {
        #load("audio/dragon-studio-sword-fight-393849-1.ogg"),
        #load("audio/dragon-studio-sword-fight-393849-2.ogg"),
        #load("audio/dragon-studio-sword-fight-393849-3.ogg"),
        #load("audio/dragon-studio-sword-fight-393849-4.ogg"),
        #load("audio/dragon-studio-sword-fight-393849-5.ogg"),
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
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-1.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-2.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-3.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-4.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-5.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-6.ogg"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-7.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-1.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-2.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-3.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-4.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-5.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-6.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-7.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-8.ogg"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-9.ogg"),
    },
    .Horse_Run = {
        #load("audio/pwlpl-horses-galloping-sound-effect-359257.ogg"),
    },
}

sfx_streams:   [SFX_Kind][]k2.Audio_Stream
sfx_to_play:   [SFX_Kind]bool
sfx_cooldowns: [SFX_Kind]f32

songs_streams: []k2.Audio_Stream
active_song: int

g_mute: bool

play_sfx :: proc (kind: SFX_Kind) {
    sfx_to_play[kind] = true
}

audio_init :: proc () {
    // create streams for all songs
    songs_streams = make([]k2.Audio_Stream, len(songs_bytes))
    for bytes, i in songs_bytes {
        songs_streams[i] = k2.load_audio_stream_from_bytes(bytes)
    }
    // create streams for all sfx (twice for each sfx so they can be played at the same time)
    for &kind_streams, kind in sfx_streams {
        kind_streams = make([]k2.Audio_Stream, len(sfx_bytes[kind]) * 2)
        for &s, i in kind_streams {
            s = k2.load_audio_stream_from_bytes(sfx_bytes[kind][i / 2])
        }
    }
}

get_sfx_playing_by_kind :: proc (playing: ^[SFX_Kind]int) {

    for kind_streams, kind in sfx_streams {

        count: int
        for stream in kind_streams {
            if k2.is_audio_stream_playing(stream) {
                count += 1
            }
        }

        playing[kind] = count
    }
}

audio_frame :: proc (dt: f32) {
    if g_mute do return

    // reduce cooldoowns
    for &c in sfx_cooldowns {
        c -= dt
    }

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
        for stream in streams_by_sfx {
            k2.update_audio_stream(stream)
            if k2.is_audio_stream_playing(stream) {
                sfx_playing_count_all += 1
            } else {
                k2.pause_audio_stream(stream)
            }
        }
    }


    sfx_playing_count: [SFX_Kind]int
    get_sfx_playing_by_kind(&sfx_playing_count)

    // play new sfx
    defer sfx_to_play = {}
    for kind_requested, kind in sfx_to_play do if kind_requested {

        kind_cfg     := sfx_config[kind]
        kind_streams := sfx_streams[kind]
        assert(len(kind_streams) > 0)

        if sfx_cooldowns[kind] > 0 do break
        if sfx_playing_count_all   >= SFX_GLOBAL_CAP do break
        if sfx_playing_count[kind] >= kind_cfg.cap do break
        if sfx_playing_count[kind] >= len(kind_streams) do break

        sfx_idx := rand.int_max(len(kind_streams))
        stream: k2.Audio_Stream
        for {
            stream = kind_streams[sfx_idx]
            k2.is_audio_stream_playing(stream) or_break
            sfx_idx = (sfx_idx+1) % len(kind_streams)
        }

        k2.set_audio_stream_pitch(stream, 1 + rand.float32_range(-kind_cfg.pitch_var, kind_cfg.pitch_var))
        k2.set_audio_stream_volume(stream, kind_cfg.volume * (1 + rand.float32_range(-0.2, 0.2)))
        k2.play_audio_stream(stream)
        sfx_playing_count_all += 1
        sfx_cooldowns[kind] = kind_cfg.cooldown
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

