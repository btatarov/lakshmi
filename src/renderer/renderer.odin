package renderer

import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import LakshmiContext "../base/context"

import Camera "camera"
import Shader "shader"
import Sprite "sprite"

import LuaRuntime "../lua"

BATCH_SIZE :: 1000

Renderer :: struct {
    width:  i32,
    height: i32,
    ratio:  f32,

    camera:         Camera.Camera,
    main_shader:    Shader.Shader,
    render_list:    [dynamic]^Sprite.Sprite,
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
    renderer.render_list = make([dynamic]^Sprite.Sprite)
}

Destroy :: proc() {
    Shader.Destroy(&renderer.main_shader)
    delete(renderer.render_list)
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

    for sprite in renderer.render_list {
        if ! sprite.visible {
            continue
        }
        sprite->render(renderer.width, renderer.height, renderer.ratio)
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
    sprite := (^Sprite.Sprite)(lua.touserdata(L, -1))
    append(&renderer.render_list, sprite)

    return 0
}

_clear :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    delete(renderer.render_list)
    renderer.render_list = make([dynamic]^Sprite.Sprite)

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
