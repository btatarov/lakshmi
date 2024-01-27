package sprite

import "core:fmt"
import "core:runtime"

import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import VertexArray "../buffers/array"
import IndexBuffer "../buffers/index"
import VertexBuffer "../buffers/vertex"
import Texture "../texture"

import LuaRuntime "../../lua"

Sprite :: struct {
    pos_x:          i32,
    pos_y:          i32,
    width:          u32,
    height:         u32,
    quad:           [4 * 9] f32,
    indecies:       [2 * 3] u32,
    texture:        Texture.Texture, // TODO: texture cache?
    index_buffer:   IndexBuffer.IndexBuffer,
    vertex_array:   VertexArray.VertexArray,
    vertex_buffer:  VertexBuffer.VertexBuffer,

    get_position:   proc(img: ^Sprite) -> (i32, i32),
    set_position:   proc(img: ^Sprite, x, y: i32),
    render:         proc(img: ^Sprite),
}

Init :: proc(img: ^Sprite, path: string) {
    fmt.println("LakshmiSprite: Init")
    img.texture = Texture.Init(path)

    // TODO: those should be different in the future
    img.width, img.height = img.texture.width, img.texture.height

    // TODO: convert x and y coords
    img.quad = {
        // positions        // colors               // uv coords
         0.5,  0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     1.0, 0.0, // top right
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,     1.0, 1.0, // bottom right
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     0.0, 1.0, // bottom left
        -0.5,  0.5, 0.0,    0.0, 0.0, 1.0, 1.0,     0.0, 0.0, // top left
    }
    // sprite_set_pos(&img, 0, 0)

    img.indecies = {
        0, 1, 3,
        1, 2, 3,
    }

    img.vertex_buffer = VertexBuffer.Init()
    img.vertex_buffer->bind(img.quad[:], size_of(img.quad))

    img.vertex_array = VertexArray.Init()

    img.index_buffer = IndexBuffer.Init()
    img.index_buffer->bind(img.indecies[:], len(img.indecies))

    img.get_position = sprite_get_pos
    img.set_position = sprite_set_pos
    img.render = sprite_render

    return
}

Destroy :: proc(img: ^Sprite) {
    fmt.println("LakshmiSprite: Destroy")
    Texture.Destroy(&img.texture)
    VertexBuffer.Destroy(&img.vertex_buffer)
    VertexArray.Destroy(&img.vertex_array)
    IndexBuffer.Destroy(&img.index_buffer)
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _new },
        { "setPos", _set_pos },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiSprite", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

sprite_get_pos :: proc(img: ^Sprite) -> (i32, i32) {
    return img.pos_x, img.pos_y
}

sprite_set_pos :: proc(img: ^Sprite, x, y: i32) {
    img.pos_x, img.pos_y = x, y

    // TODO: test only, convert coordinates and update quad
    img.quad[0] = 1.0
    img.quad[1] = 1.0
    img.quad[9] = 1.0
    img.quad[10] = 0.0
    img.quad[18] = 0.0
    img.quad[19] = 0.0
    img.quad[27] = 0.0
    img.quad[28] = 1.0

    img.vertex_buffer->bind(img.quad[:], size_of(img.quad))
}

sprite_render :: proc(img: ^Sprite) {
    img.texture->bind()
    img.vertex_array->bind()
    OpenGL.DrawElements(OpenGL.TRIANGLES, img.index_buffer.count, OpenGL.UNSIGNED_INT, nil)
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    sprite := (^Sprite)(lua.newuserdata(L, size_of(Sprite)))
    Init(sprite, "test/lakshmi.png")

    LuaRuntime.BindClassMetatable(L, "LakshmiSprite")

    return 1
}


_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    x := i32(lua.tointeger(L, -2))
    y := i32(lua.tointeger(L, -1))
    sprite.set_position(sprite, x, y)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    Destroy(sprite)

    return 0
}
