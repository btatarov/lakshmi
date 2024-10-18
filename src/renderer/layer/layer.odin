package renderer_layer

import "core:log"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import Renderable "../renderable"
import Sprite "../sprite"
import Text "../text"

Renderable_Union :: union {
    ^Sprite.Sprite,
    ^Text.Text,
}

Layer :: struct {
    visible:     bool,
    is_gone:     bool,
    renderables: [dynamic]Renderable_Union,

    set_visible: proc(layer: ^Layer, visible: bool),
}

Init :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Init\n")

    layer.visible = true
    layer.is_gone = false
    layer.renderables = make([dynamic]Renderable_Union)

    layer.set_visible = layer_set_visible
}

Destroy :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Destroy\n")

    layer.is_gone = true

    delete(layer.renderables)
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

    layer      := (^Layer)(lua.touserdata(L, 1))
    renderable := (^Renderable.Renderable)((lua.touserdata(L, 2)))

    switch renderable.renderable_type {
    case .Sprite:
        sprite := (^Sprite.Sprite)((lua.touserdata(L, 2)))
        sprite.id = len(layer.renderables)
        append(&layer.renderables, sprite)

    case .Text:
        text := (^Text.Text)((lua.touserdata(L, 2)))
        append(&layer.renderables, text)
    }

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, 1))
    delete(layer.renderables)
    layer.renderables = make([dynamic]Renderable_Union)

    return 0
}

_set_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, 1))
    visible := bool(lua.toboolean(L, 2))
    layer.set_visible(layer, visible)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, 1))
    Destroy(layer)

    return 0
}
