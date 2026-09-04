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

SFX_GLOBAL_CAP :: 14

sfx_config := [SFX_Kind]SFX_Config{
    .Sword_Slash   = {volume=0.30, pitch_var=0.15, cooldown=350, cap=2},
    .Sword_Impact  = {volume=0.28, pitch_var=0.15, cooldown=390, cap=2},
    .Arrow_Swish   = {volume=0.12, pitch_var=0.25, cooldown=270, cap=2},
    .Arrow_Impact  = {volume=0.16, pitch_var=0.20, cooldown=310, cap=2},
    .Shield_Impact = {volume=0.38, pitch_var=0.10, cooldown=330, cap=1},
    .Thud_Impact   = {volume=0.32, pitch_var=0.15, cooldown=350, cap=1},
    .Infantry_Run  = {volume=0.36, pitch_var=0.25, cooldown=240, cap=10},
    .Horse_Run     = {volume=0.37, pitch_var=0.20, cooldown=280, cap=8},
}

songs_bytes := [?][]byte{
    #load("audio/montogoronto-dark-orchestral-battle-tension-395613.ogg"),
    #load("audio/rolandomat-epic-battle-song-182915.ogg"),
}

sfx_bytes := [SFX_Kind][][]byte{
    .Sword_Slash = {
        #load("audio/54427377-sword-slash-476148.wav"),
        #load("audio/dragon-studio-sword-slice-393847.wav"),
        #load("audio/freesound_community-sword-sound-2-36274.wav"),
        #load("audio/musicholder-sword-sound-260274.wav"),
        #load("audio/universfield-sword-blade-slicing-flesh-352708.wav"),
    },
    .Sword_Impact = {
        #load("audio/dragon-studio-sword-fight-393849-1.wav"),
        #load("audio/dragon-studio-sword-fight-393849-2.wav"),
        #load("audio/dragon-studio-sword-fight-393849-3.wav"),
        #load("audio/dragon-studio-sword-fight-393849-4.wav"),
        #load("audio/dragon-studio-sword-fight-393849-5.wav"),
    },
    .Arrow_Swish = {
        #load("audio/djartmusic-arrow-swish_03-306040.wav"),
    },
    .Arrow_Impact = {
        #load("audio/dennish18-arrow-body-impact-146419.wav"),
        #load("audio/dennish18-arrow-wood-impact-146418.wav"),
    },
    .Thud_Impact = {
        #load("audio/virtual_vibes-thud-impact-sound-sfx-379990.wav"),
    },
    .Shield_Impact = {
        #load("audio/yodguard-shield_impact-1-382410.wav"),
        #load("audio/yodguard-shield_impact-5-382415.wav"),
    },
    .Infantry_Run = {
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-1.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-2.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-3.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-4.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-5.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-6.wav"),
        #load("audio/freesound_community-180904-woodland04-run-steps-skip-jump-clip-47486-7.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-1.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-2.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-3.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-4.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-5.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-6.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-7.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-8.wav"),
        #load("audio/freesound_community-footsteps-in-thin-snow-46199-9.wav"),
    },
    .Horse_Run = {
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-1.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-2.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-3.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-4.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-5.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-6.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-7.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-8.wav"),
        #load("audio/pwlpl-horses-galloping-sound-effect-359257-9.wav"),
    },
}

sfx_audio_clips: [SFX_Kind][]k2.Audio_Clip
sfx_to_play:     [SFX_Kind]bool
sfx_cooldowns:   [SFX_Kind]f32

songs_streams:     [len(songs_bytes)]k2.Audio_Stream
active_song_sound: k2.Sound
active_song:       int

g_mute: bool

play_sfx :: proc (kind: SFX_Kind) {
    if !g_mute {
        sfx_to_play[kind] = true
    }
}

audio_init :: proc () {
    loaded: bool
    // create streams for all songs
    for bytes, i in songs_bytes {
        songs_streams[i], loaded = k2.load_audio_stream_from_bytes(bytes)
        assert(loaded, "Failed to load music audio stream")
    }
    // create audio clips for all sfx
    for &kind_clips, kind in sfx_audio_clips {
        kind_clips = make([]k2.Audio_Clip, len(sfx_bytes[kind]))
        for &clip, i in kind_clips {
            clip, loaded = k2.load_audio_clip_from_bytes(sfx_bytes[kind][i])
            assert(loaded, "Failed to load sfx audio clip")
        }
    }
}

get_sfx_playing_by_kind :: proc (playing: ^[SFX_Kind]int) {
    playing^ = {}
    for kind_clips, kind in sfx_audio_clips {
        for clip in kind_clips {
            playing[kind] += k2.get_num_sounds_playing_clip(clip)
        }
    }
}

audio_frame :: proc (dt: f32) {

    // reduce cooldoowns
    for &c in sfx_cooldowns {
        c -= dt
    }

    // update music songs
    if g_mute {
        k2.stop_sound(active_song_sound)
    } else if k2.sound_is_valid(active_song_sound) {
        k2.update_audio_stream(songs_streams[active_song])
    } else {
        k2.stop_sound(active_song_sound)
        active_song = (active_song+1) % len(songs_streams)
        active_song_sound = k2.play_audio_stream(songs_streams[active_song])
    }

    if g_mute do return

    sfx_playing_count: [SFX_Kind]int
    get_sfx_playing_by_kind(&sfx_playing_count)

    sfx_playing_count_all: int
    for count in sfx_playing_count {
        sfx_playing_count_all += count
    }

    // play new sfx
    defer sfx_to_play = {}
    for kind_requested, kind in sfx_to_play do if kind_requested {

        kind_config := sfx_config[kind]
        kind_clips  := sfx_audio_clips[kind]
        assert(len(kind_clips) > 0)

        if sfx_cooldowns[kind] > 0 do break
        if sfx_playing_count_all   >= SFX_GLOBAL_CAP do break
        if sfx_playing_count[kind] >= kind_config.cap do break

        sfx_idx := rand.int_max(len(kind_clips))
        clip := kind_clips[sfx_idx]

        k2.play_audio_clip(clip,
            volume = kind_config.volume * (1 + rand.float32_range(-0.2, 0.2)),
            pitch  = 1 + rand.float32_range(-kind_config.pitch_var, kind_config.pitch_var),
        )
        sfx_playing_count_all += 1
        sfx_cooldowns[kind] = kind_config.cooldown * rand.float32_range(-0.2, 0.2)
    }
}

audio_toggle_mute :: proc (mute: Maybe(bool) = nil) {
    g_mute = mute.? or_else !g_mute
}

