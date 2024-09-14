package audio_system

import "core:log"

import lua "vendor:lua/5.4"
import ma "vendor:miniaudio"

import Channel "../channel"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

MAX_CHANNELS :: 32

AudioContext :: struct {
    engine:    ma.engine,
    channels:  [dynamic]^Channel.Channel,
    is_active: bool,
}

@private audio_context: AudioContext

Init :: proc() {
    if ! audio_context.is_active {
        log.debugf("LakshmiAudioSystem: Init\n")

        result := ma.engine_init(nil, &audio_context.engine)
        assert(result == .SUCCESS, "Failed to initialize audio engine")

        audio_context.channels  = make([dynamic]^Channel.Channel)
        audio_context.is_active = true
    }
}

Clear :: proc() {
    if audio_context.is_active {
        for channel in audio_context.channels {
            Channel.Destroy(channel)
        }
    }
}

Destroy :: proc() {
    if audio_context.is_active {
        log.debugf("LakshmiAudioSystem: Destroy\n")

        Clear()
        delete(audio_context.channels)

        audio_context.is_active = false
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "init",    _init },
        { "destroy", _destroy },
        { "add",     _add },
        { "clear",   _clear },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiAudioSystem", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    Destroy()
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    Init()

    return 0
}

_destroy :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    Destroy()

    return 0
}

_add :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    channel := (^Channel.Channel)(lua.touserdata(L, 1))
    Channel.SetEngine(channel, &audio_context.engine)

    append(&audio_context.channels, channel)

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    Clear()

    return 0
}
