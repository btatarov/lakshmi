package renderer

import "core:fmt"
import "core:image/png"
import "core:runtime"

import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import Camera "camera"
import Shader "shader"
import Sprite "sprite"

import LuaRuntime "../lua"

@private camera         : Camera.Camera
@private main_shader    : Shader.Shader
@private render_list    : [dynamic]^Sprite.Sprite

Init :: proc(width, height : i32) {
    OpenGL.BlendFunc(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA)
    OpenGL.Enable(OpenGL.BLEND)

    // Testing: wireframe mode
    // OpenGL.PolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.LINE)

    // camera
    ratio := f32(width) / f32(height)
    camera = Camera.Init(-ratio, ratio, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // shader
    main_shader = Shader.Init()

    RefreshViewport(width, height)
    render_list = make([dynamic]^Sprite.Sprite)
}

Destroy :: proc() {
    Shader.Destroy(&main_shader)
    delete(render_list)
}

RefreshViewport :: proc(width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)

    ratio := f32(width) / f32(height)
    camera->set_projection_matrix(-ratio, ratio, -1, 1)
}

Render :: proc() {
    OpenGL.ClearColor(0.3, 0.3, 0.3, 1.0)
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    main_shader->bind()
    main_shader->apply_projection(camera->get_vp_matrix())

    for sprite in render_list {
        sprite->render()
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "add", _add },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiRenderer", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_add :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    // TODO: remove on __gc or __close?
    sprite := (^Sprite.Sprite)(lua.touserdata(L, -1))
    append(&render_list, sprite)

    return 0
}
