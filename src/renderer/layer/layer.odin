package renderer_layer

import "core:log"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import Sprite "../sprite"
import Text "../text"

Layer :: struct {
    visible:     bool,
    is_gone:     bool,
    renderables: [dynamic]Renderable,

    set_visible: proc(layer: ^Layer, visible: bool),
}

// TODO: in the future this should be as a separate module
RenderableType :: enum {
    Sprite,
    Text,
}

Renderable :: struct {
    data: union {
        ^Sprite.Sprite,
        ^Text.Text,
    },
    type: RenderableType,
}

Init :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Init\n")

    layer.visible = true
    layer.is_gone = false
    layer.renderables = make([dynamic]Renderable)

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

    constants: map[string]u32 = {
        "RENDERABLE_TYPE_SPRITE" = u32(RenderableType.Sprite),
        "RENDERABLE_TYPE_TEXT"   = u32(RenderableType.Text),
    }
    defer delete(constants)

    LuaRuntime.BindClass(L, "LakshmiLayer", &reg_table, &constants, __gc)
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

    layer  := (^Layer)(lua.touserdata(L, 1))
    type   := RenderableType((lua.tonumber(L, 3)))

    // TODO: in the future these should have some type of inheritance instead
    switch type {
    case RenderableType.Sprite:
        renderable: Renderable = {
            data = (^Sprite.Sprite)(lua.touserdata(L, 2)),
            type = .Sprite,
        }
        append(&layer.renderables, renderable)

    case RenderableType.Text:
        renderable: Renderable = {
            data = (^Text.Text)(lua.touserdata(L, 2)),
            type = .Text,
        }
        append(&layer.renderables, renderable)
    }

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    layer := (^Layer)(lua.touserdata(L, 1))
    delete(layer.renderables)
    layer.renderables = make([dynamic]Renderable)

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
