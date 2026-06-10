package first_battle

import k2 "./karl2d"

songs_bytes := [][]byte{
    #load("audio/montogoronto-dark-orchestral-battle-tension-395613.ogg"),
    #load("audio/rolandomat-epic-battle-song-182915.ogg"),
}
songs_streams: []k2.Audio_Stream
active_song: int

g_mute: bool

audio_init :: proc () {
    songs_streams = make([]k2.Audio_Stream, len(songs_bytes))
    for bytes, i in songs_bytes {
        songs_streams[i] = k2.load_audio_stream_from_bytes(bytes)
    }
}

audio_frame :: proc () {
    if g_mute do return
    k2.update_audio_stream(songs_streams[active_song])
    if !k2.audio_stream_is_playing(songs_streams[active_song]) {
        k2.pause_audio_stream(songs_streams[active_song])
        active_song = (active_song+1) % len(songs_streams)
        k2.play_audio_stream(songs_streams[active_song])
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

