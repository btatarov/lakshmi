package renderer

import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import LakshmiContext "../base/context"

import Camera "camera"
import Shader "shader"
import Layer "layer"

import LuaRuntime "../lua"

BATCH_SIZE :: 1000

Renderer :: struct {
    width:  i32,
    height: i32,
    ratio:  f32,

    camera:         Camera.Camera,
    main_shader:    Shader.Shader,
    layer_list:    [dynamic]^Layer.Layer,
}

@private renderer: Renderer

Init :: proc(width, height : i32) {
    OpenGL.BlendFunc(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA)
    OpenGL.Enable(OpenGL.BLEND)
    OpenGL.ClearColor(0.0, 0.0, 0.0, 1.0)

    renderer = Renderer{}
    renderer.width  = width
    renderer.height = height
    renderer.ratio  = f32(width) / f32(height)

    // Testing: wireframe mode
    // OpenGL.PolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.LINE)

    // camera
    renderer.camera = Camera.Init(-renderer.ratio, renderer.ratio, -1, 1)
    // TODO: from lua
    // renderer.camera->set_position({0.5, 0.5, 0})
    // renderer.camera->set_rotation(30)

    // shader
    renderer.main_shader = Shader.Init()

    RefreshViewport(width, height)
    renderer.layer_list = make([dynamic]^Layer.Layer)
}

Destroy :: proc() {
    Shader.Destroy(&renderer.main_shader)
    delete(renderer.layer_list)
}

RefreshViewport :: proc(width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)

    renderer.width  = width
    renderer.height = height
    renderer.ratio  = f32(width) / f32(height)

    renderer.camera->set_projection_matrix(-renderer.ratio, renderer.ratio, -1, 1)
}

Render :: proc() {
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    renderer.main_shader->bind()
    renderer.main_shader->apply_projection(renderer.camera->get_vp_matrix())

    for layer in renderer.layer_list {
        layer->render(renderer.width, renderer.height, renderer.ratio)
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

    OpenGL.ClearColor(r, g, b, a)

    return 0
}
