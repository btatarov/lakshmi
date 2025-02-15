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

BATCH_SIZE :: 1000 // TODO: in the future we should render in batches

Renderer :: struct {
    width:  i32,
    height: i32,
    ratio:  f32,

    camera:     ^Camera.Camera,
    shaders:    map[string]Shader.Shader,
    layer_list: [dynamic]^Layer.Layer,
}

@private renderer: Renderer
@private draw_count: u32

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

GetDrawCount :: proc() -> u32 {
    return draw_count
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
    draw_count = 0

    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    for layer in renderer.layer_list {
        if ! layer.visible || layer.is_gone {
            continue
        }

        for renderable in layer.renderables {
            renderable_union := (Layer.Renderable_Union)(renderable)
            switch renderable_type in renderable_union {
            case ^Sprite.Sprite:
                sprite := renderable_union.(^Sprite.Sprite)
                if ! sprite.is_gone && sprite.visible {
                    shader := renderer.shaders["sprite"]
                    shader->bind()
                    shader->apply_projection(renderer.camera->get_vp_matrix())

                    sprite->render(renderer.width, renderer.height, renderer.ratio)
                    draw_count += 1  // TODO: in the future we should render in batches
                }

            case ^Text.Text:
                text := renderable_union.(^Text.Text)
                if ! text.is_gone && text.visible {
                    shader := renderer.shaders["text"]
                    shader->bind()
                    shader->apply_projection(renderer.camera->get_vp_matrix())

                    for &sprite in text.sprites {
                        sprite->render(renderer.width, renderer.height, renderer.ratio)
                        draw_count += 1  // TODO: in the future we should render in batches
                    }
                }
            }
        }
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "add",            _add },
        { "clear",          _clear },
        { "getSpriteCount", _getSpriteCount },
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

_getSpriteCount :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    count := Sprite.GetSpriteCount()
    lua.pushinteger(L, lua.Integer(count))

    return 1
}

_setClearColor :: proc "c" (L: ^lua.State) -> i32 {
    r := f32(lua.tonumber(L, 1))
    g := f32(lua.tonumber(L, 2))
    b := f32(lua.tonumber(L, 3))
    a := f32(lua.tonumber(L, 4))

    gl.ClearColor(r, g, b, a)

    return 0
}
