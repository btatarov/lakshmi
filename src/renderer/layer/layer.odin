package renderer_layer

import "core:log"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import Camera "../camera"
import Shader "../shader"
import Sprite "../sprite"
import Text "../text"

Layer :: struct {
    visible:        bool,
    renderables:    [dynamic]Renderable,

    render:         proc(layer: ^Layer, camera: ^Camera.Camera, shaders: ^map[string]Shader.Shader, screen_width, screen_height: i32, screen_ratio: f32),
    set_visible:    proc(layer: ^Layer, visible: bool),
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
    layer.renderables = make([dynamic]Renderable)

    layer.render      = layer_render
    layer.set_visible = layer_set_visible
}

Destroy :: proc(layer: ^Layer) {
    log.debugf("LakshmiLayer: Destroy\n")

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

layer_render :: proc(layer: ^Layer, camera: ^Camera.Camera, shaders: ^map[string]Shader.Shader, screen_width, screen_height: i32, screen_ratio: f32) {
    if ! layer.visible {
        return
    }

    for renderable in layer.renderables {
        switch renderable.type {
            case .Sprite:
                shader := shaders["sprite"]
                shader->bind()
                shader->apply_projection(camera->get_vp_matrix())

                renderable.data.(^Sprite.Sprite)->render(screen_width, screen_height, screen_ratio)

            case .Text:
                shader := shaders["text"]
                shader->bind()
                shader->apply_projection(camera->get_vp_matrix())

                for &sprite in renderable.data.(^Text.Text).sprites {
                    sprite->render(screen_width, screen_height, screen_ratio)
                }
        }
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
