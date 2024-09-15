package renderer

import lua "vendor:lua/5.4"
import gl "vendor:OpenGL"

import LakshmiContext "../base/context"

import Camera "camera"
import Shader "shader"
import Layer "layer"
import Sprite "sprite"
import Text "text"

import LuaRuntime "../lua"

BATCH_SIZE :: 1000

Renderer :: struct {
    width:  i32,
    height: i32,
    ratio:  f32,

    camera:     ^Camera.Camera,
    shaders:    map[string]Shader.Shader,
    layer_list: [dynamic]^Layer.Layer,
}

@private renderer: Renderer

Init :: proc(width, height : i32) {
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Enable(gl.BLEND)
    gl.ClearColor(0.0, 0.0, 0.0, 1.0)

    renderer = Renderer{}
    renderer.width  = width
    renderer.height = height
    renderer.ratio  = f32(width) / f32(height)

    // Testing: wireframe mode
    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

    renderer.shaders = make(map[string]Shader.Shader)
    renderer.shaders["sprite"] = Shader.Init(.Sprite)
    renderer.shaders["text"] = Shader.Init(.Text)

    renderer.camera = Camera.Init(-renderer.ratio, renderer.ratio, -1, 1)
    renderer.layer_list = make([dynamic]^Layer.Layer)

    RefreshViewport(width, height)
}

Destroy :: proc() {
    Shader.Destroy(&renderer.shaders["sprite"])
    Shader.Destroy(&renderer.shaders["text"])
    delete(renderer.layer_list)
}

RefreshViewport :: proc(width, height : i32) {
    gl.Viewport(0, 0, width, height)

    renderer.width  = width
    renderer.height = height
    renderer.ratio  = f32(width) / f32(height)

    renderer.camera->set_screen_size(width, height)
    renderer.camera->set_projection_matrix(-renderer.ratio, renderer.ratio, -1, 1)
}

Render :: proc() {
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    for layer in renderer.layer_list {
        if ! layer.visible {
            continue
        }

        for renderable in layer.renderables {
            switch renderable.type {
                case .Sprite:
                    shader := renderer.shaders["sprite"]
                    shader->bind()
                    shader->apply_projection(renderer.camera->get_vp_matrix())

                renderable.data.(^Sprite.Sprite)->render(renderer.width, renderer.height, renderer.ratio)

                case .Text:
                    shader := renderer.shaders["text"]
                    shader->bind()
                    shader->apply_projection(renderer.camera->get_vp_matrix())

                    for &sprite in renderable.data.(^Text.Text).sprites {
                        sprite->render(renderer.width, renderer.height, renderer.ratio)
                    }
            }
        }
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "add",            _add },
        { "clear",          _clear },
        { "setClearColor",  _setClearColor},
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiRenderer", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_add :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    // TODO: remove on __gc or __close?
    layer := (^Layer.Layer)(lua.touserdata(L, -1))
    append(&renderer.layer_list, layer)

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    delete(renderer.layer_list)
    renderer.layer_list = make([dynamic]^Layer.Layer)

    return 0
}

_setClearColor :: proc "c" (L: ^lua.State) -> i32 {
    r := f32(lua.tonumber(L, 1))
    g := f32(lua.tonumber(L, 2))
    b := f32(lua.tonumber(L, 3))
    a := f32(lua.tonumber(L, 4))

    gl.ClearColor(r, g, b, a)

    return 0
}
