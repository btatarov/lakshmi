package sprite

import "core:log"
import "core:math"
import "core:math/linalg"

import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import LakshmiContext "../../base/context"

import VertexArray "../buffers/array"
import IndexBuffer "../buffers/index"
import VertexBuffer "../buffers/vertex"
import Texture "../texture"

import LuaRuntime "../../lua"

Sprite :: struct {
    width:          u32,
    height:         u32,
    texture:        Texture.Texture, // TODO: texture cache?

    quad:           [4 * 9] f32,
    indecies:       [2 * 3] u32,
    index_buffer:   IndexBuffer.IndexBuffer,
    vertex_array:   VertexArray.VertexArray,
    vertex_buffer:  VertexBuffer.VertexBuffer,

    // TODO: implement scale and rotation
    // position:       linalg.Vector3f32,
    // scale:          linalg.Vector3f32,
    // rotation:       f32,
    // model_matrix:   linalg.Matrix4f32,
    position:       linalg.Vector3f32,
    scale:          linalg.Vector3f32,
    rotation:       f32,
    model_matrix:   matrix[4, 4] f32,

    get_position:   proc(img: ^Sprite) -> (f32, f32),
    get_scale:      proc(img: ^Sprite) -> (f32, f32),
    set_position:   proc(img: ^Sprite, x, y: f32),
    set_scale:      proc(img: ^Sprite, x, y: f32),
    update_model:   proc(img: ^Sprite),
    render:         proc(img: ^Sprite),
}

Init :: proc(img: ^Sprite, path: string) {
    log.debugf("LakshmiSprite: Init: %s\n", path)

    img.texture = Texture.Init(path)

    // TODO: those should be different in the future
    img.width, img.height = img.texture.width, img.texture.height

    img.quad = {
        // positions        // colors               // uv coords
         0.5,  0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     1.0, 0.0, // top right
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,     1.0, 1.0, // bottom right
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     0.0, 1.0, // bottom left
        -0.5,  0.5, 0.0,    0.0, 0.0, 1.0, 1.0,     0.0, 0.0, // top left
    }

    img.indecies = {
        0, 1, 3,
        1, 2, 3,
    }

    img.vertex_buffer = VertexBuffer.Init()
    img.vertex_buffer->bind(img.quad[:], size_of(img.quad))

    img.vertex_array = VertexArray.Init()

    img.index_buffer = IndexBuffer.Init()
    img.index_buffer->bind(img.indecies[:], len(img.indecies))

    img.scale = 1
    img.model_matrix = f32(1)

    img.get_position = sprite_get_position
    img.get_scale    = sprite_get_scale
    img.set_position = sprite_set_position
    img.set_scale    = sprite_set_scale
    img.update_model = sprite_update_model
    img.render       = sprite_render

    return
}

Destroy :: proc(img: ^Sprite) {
    log.debugf("LakshmiSprite: Destroy\n")

    Texture.Destroy(&img.texture)
    VertexBuffer.Destroy(&img.vertex_buffer)
    VertexArray.Destroy(&img.vertex_array)
    IndexBuffer.Destroy(&img.index_buffer)
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _new },
        { "getPos", _get_pos },
        { "getScl", _get_scl },
        { "setPos", _set_pos },
        { "setScl", _set_scl },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiSprite", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

sprite_get_position :: proc(img: ^Sprite) -> (f32, f32) {
    return img.position.x, img.position.y
}

sprite_get_scale :: proc(img: ^Sprite) -> (f32, f32) {
    return img.scale.x, img.scale.y
}

sprite_set_position :: proc(img: ^Sprite, x, y: f32) {
    img.position = {f32(x), f32(y), 0}  // TODO: convert using viewport size
    img.vertex_buffer->bind(img.quad[:], size_of(img.quad))
}

sprite_set_scale :: proc(img: ^Sprite, x, y: f32) {
    img.scale = {f32(x), f32(y), 1}
    img.vertex_buffer->bind(img.quad[:], size_of(img.quad))
}

sprite_update_model :: proc(img: ^Sprite) {
    _ = math.sin_f32(0)  // TODO: remove
    transform: linalg.Matrix4f32 = 1
    transform *= linalg.matrix4_translate(img.position)
    transform *= linalg.matrix4_scale(img.scale)
    img.model_matrix = transform
}

sprite_render :: proc(img: ^Sprite) {
    img->update_model()
    img.texture->bind()
    img.vertex_array->bind()
    OpenGL.DrawElements(OpenGL.TRIANGLES, img.index_buffer.count, OpenGL.UNSIGNED_INT, nil)
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.newuserdata(L, size_of(Sprite)))
    Init(sprite, "test/lakshmi.png")

    LuaRuntime.BindClassMetatable(L, "LakshmiSprite")

    return 1
}

_get_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    x, y := sprite.get_position(sprite)

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    x, y := sprite.get_scale(sprite)

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))
    sprite.set_position(sprite, x, y)

    return 0
}

_set_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))
    sprite.set_scale(sprite, x, y)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    Destroy(sprite)

    return 0
}
