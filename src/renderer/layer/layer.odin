package renderer_layer

import "core:log"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import Sprite "../sprite"

Layer :: struct {
    visible:        bool,
    sprite_list:    [dynamic]^Sprite.Sprite,

    render:         proc(img: ^Layer, screen_width, screen_height: i32, screen_ratio: f32),
    set_visible:    proc(img: ^Layer, visible: bool),
}

Init :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Init\n")

    layer.visible = true
    layer.sprite_list = make([dynamic]^Sprite.Sprite)

    layer.render      = layer_render
    layer.set_visible = layer_set_visible
}

Destroy :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Destroy\n")

    delete(layer.sprite_list)
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",        _new },
        { "add",        _add },
        { "clear",      _clear },
        { "setVisible", _set_visible },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiLayer", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

layer_render :: proc(layer: ^Layer, screen_width, screen_height: i32, screen_ratio: f32) {
    if ! layer.visible {
        return
    }

    for sprite in layer.sprite_list {
        sprite->render(screen_width, screen_height, screen_ratio)
    }
}

layer_set_visible :: proc(layer: ^Layer, visible: bool) {
    layer.visible = visible
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.newuserdata(L, size_of(Layer)))
    Init(layer)

    LuaRuntime.BindClassMetatable(L, "LakshmiLayer")

    return 1
}

_add :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer  := (^Layer)(lua.touserdata(L, -2))
    sprite := (^Sprite.Sprite)(lua.touserdata(L, -1))
    append(&layer.sprite_list, sprite)

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, -1))
    delete(layer.sprite_list)
    layer.sprite_list = make([dynamic]^Sprite.Sprite)

    return 0
}

_set_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, -2))
    visible := bool(lua.toboolean(L, -1))
    layer.set_visible(layer, visible)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, -1))
    Destroy(layer)

    return 0
}
