package first_battle

import k2 "./karl2d"

song_bytes_1 := #load("audio/montogoronto-dark-orchestral-battle-tension-395613.ogg")
song_bytes_2 := #load("audio/rolandomat-epic-battle-song-182915.ogg")

stream: k2.Audio_Stream
g_mute: bool

audio_init :: proc () {
    stream = k2.load_audio_stream_from_bytes(song_bytes_1)
    k2.play_audio_stream(stream)

}

audio_frame :: proc () {
    k2.update_audio_stream(stream)
}

audio_toggle_mute :: proc (mute: Maybe(bool) = nil) {

    new_mute := mute.? or_else !g_mute

    if g_mute == new_mute do return
    g_mute = new_mute

    if g_mute {
        k2.pause_audio_stream(stream)
    } else {
        k2.play_audio_stream(stream)
    }
}

