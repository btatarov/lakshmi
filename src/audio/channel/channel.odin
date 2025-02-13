package audio_channel

import "core:fmt"
import "core:log"

import lua "vendor:lua/5.4"
import ma "vendor:miniaudio"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

Channel :: struct {
    engine:      ^ma.engine,
    group:       ma.sound_group,
    sounds:      map[string]ma.sound,
    is_streamed: bool,
    is_looping:  bool,
    is_active:   bool,
}

Init :: proc(channel: ^Channel, is_streamed: bool) {
    log.debugf("LakshmiAudioChannel: Init\n")

    channel.sounds = make(map[string]ma.sound)
    channel.is_streamed = is_streamed
}

Clear :: proc(channel: ^Channel) {
    if channel.is_active {
        for _, &sound in channel.sounds {
            ma.sound_uninit(&sound)
        }
    }
    clear(&channel.sounds)
}

Destroy :: proc(channel: ^Channel) {
    if channel.is_active {
        log.debugf("LakshmiAudioChannel: Destroy\n")

        Clear(channel)
        delete(channel.sounds)

        channel.is_active = false
    }
}

SetEngine :: proc(channel: ^Channel, engine: ^ma.engine) {
    channel.engine = engine

    result := ma.sound_group_init(channel.engine, {}, nil, &channel.group)
    assert(result == .SUCCESS, "Failed to initialize sound group")

    channel.is_active = true
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",       _new },
        { "add",       _add },
        { "play",      _play },
        { "pause",     _pause },
        { "stop",      _stop },
        { "setVolume", _setVolume },
        { "setPan",    _setPan },
        { "setLoop",   _setLoop },
        { "clear",     _clear },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiAudioChannel", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.newuserdata(L, size_of(Channel)))
    is_streamed := lua.toboolean(L, 1)

    Init(channel, bool(is_streamed))

    LuaRuntime.BindClassMetatable(L, "LakshmiAudioChannel")

    return 1
}

_add :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    name := lua.tostring(L, 2)
    path := lua.tostring(L, 3)

    assert(channel.is_active, "Channel is not active")
    assert(! (string(name) in channel.sounds), fmt.tprintf("Sound already exists: %s\n", name))

    flags: ma.sound_flags
    if channel.is_streamed {
        flags = {.STREAM}
    } else {
        flags = {.DECODE}
    }

    channel.sounds[string(name)] = ma.sound{}
    result := ma.sound_init_from_file(channel.engine, path, flags, &channel.group, nil, &channel.sounds[string(name)])
    assert(result == .SUCCESS, fmt.tprintf("Failed to load sound: %s\n", name))

    ma.sound_set_looping(&channel.sounds[string(name)], b32(channel.is_looping))

    return 0
}

_play :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    name := lua.tostring(L, 2)

    assert(channel.is_active, "Channel is not active")
    assert(string(name) in channel.sounds, fmt.tprintf("Sound does not exist: %s\n", name))

    result := ma.sound_group_start(&channel.group)
    assert(result == .SUCCESS, "Failed to start sounds\n")

    result = ma.sound_start(&channel.sounds[string(name)])
    assert(result == .SUCCESS, fmt.tprintf("Failed to play sound: %s\n", name))

    return 0
}

_pause :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))

    assert(channel.is_active, "Channel is not active")

    result := ma.sound_group_stop(&channel.group)
    assert(result == .SUCCESS, "Failed to stop sounds\n")

    return 0
}

_stop :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))

    assert(channel.is_active, "Channel is not active")

    result := ma.sound_group_stop(&channel.group)
    assert(result == .SUCCESS, "Failed to stop sounds\n")

    for _, &sound in channel.sounds {
        result = ma.sound_seek_to_pcm_frame(&sound, 0)
        assert(result == .SUCCESS, fmt.tprintf("Failed to rewind sound: %s\n"))
    }

    return 0
}

_setVolume :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    volume := lua.tonumber(L, 2)

    assert(channel.is_active, "Channel is not active")

    ma.sound_group_set_volume(&channel.group, f32(volume))

    return 0
}

_setPan :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    pan := lua.tonumber(L, 2)

    assert(channel.is_active, "Channel is not active")

    ma.sound_group_set_pan(&channel.group, f32(pan))

    return 0
}

_setLoop :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    loop := lua.toboolean(L, 2)

    for _, &sound in channel.sounds {
        ma.sound_set_looping(&sound, b32(loop))
    }

    assert(channel.is_active, "Channel is not active")

    channel.is_looping = bool(loop)

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    Clear(channel)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel)(lua.touserdata(L, 1))
    Destroy(channel)

    return 0
}
