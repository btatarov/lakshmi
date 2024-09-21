package renderer_sprite

import "core:log"
import "core:math"
import "core:math/linalg"

import lua "vendor:lua/5.4"
import gl "vendor:OpenGL"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import VertexArray "../buffers/array"
import IndexBuffer "../buffers/index"
import VertexBuffer "../buffers/vertex"
import Texture "../texture"

Sprite :: struct {
    width:          u32,
    height:         u32,
    position:       linalg.Vector3f32,
    scale:          linalg.Vector3f32,
    pivot:          linalg.Vector3f32,
    rotation:       f32,
    visible:        bool,
    texture:        Texture.Texture,
    color:          linalg.Vector4f32,

    quad:           [4 * 9]f32,
    indices:        [2 * 3]u32,
    is_dirty:       bool,

    index_buffer:   IndexBuffer.IndexBuffer,
    vertex_array:   VertexArray.VertexArray,
    vertex_buffer:  VertexBuffer.VertexBuffer,

    get_color:      proc(img: ^Sprite) -> linalg.Vector4f32,
    get_pivot:      proc(img: ^Sprite) -> (f32, f32),
    get_position:   proc(img: ^Sprite) -> (f32, f32),
    get_rotation:   proc(img: ^Sprite) -> f32,
    get_scale:      proc(img: ^Sprite) -> (f32, f32),
    is_visible:     proc(img: ^Sprite) -> bool,
    set_color:      proc(img: ^Sprite, color: linalg.Vector4f32),
    set_pivot:      proc(img: ^Sprite, x, y: f32),
    set_position:   proc(img: ^Sprite, x, y: f32),
    set_rotation:   proc(img: ^Sprite, angle: f32),
    set_scale:      proc(img: ^Sprite, x, y: f32),
    set_visible:    proc(img: ^Sprite, visible: bool),
    render:         proc(img: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32),
    update_quad:    proc(img: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32),
}

Init :: proc(img: ^Sprite, texture: ^Texture.Texture) {
    log.debugf("LakshmiSprite: Init\n")

    img.scale   = 1
    img.visible = true
    img.color   = {1, 1, 1, 1}
    img.texture = texture^

    // TODO: those should be different in the future
    img.width, img.height = u32(img.texture.width), u32(img.texture.height)

    img.quad = {
        // positions        // colors               // uv coords
         0.5,  0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     1.0, 1.0,  // top right
         0.5, -0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     1.0, 0.0,  // bottom right
        -0.5, -0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     0.0, 0.0,  // bottom left
        -0.5,  0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     0.0, 1.0,  // top left
    }

    img.indices = {
        0, 1, 3,
        1, 2, 3,
    }

    img.is_dirty = true

    img.vertex_buffer = VertexBuffer.Init(4 * 9 * size_of(f32))
    img.vertex_array = VertexArray.Init()
    img.index_buffer = IndexBuffer.Init(len(img.indices))
    img.index_buffer->add(img.indices[:], len(img.indices))

    img.get_color    = sprite_get_color
    img.get_pivot    = sprite_get_pivot
    img.get_position = sprite_get_position
    img.get_rotation = sprite_get_rotation
    img.get_scale    = sprite_get_scale
    img.is_visible   = sprite_is_visible
    img.set_color    = sprite_set_color
    img.set_pivot    = sprite_set_pivot
    img.set_position = sprite_set_position
    img.set_rotation = sprite_set_rotation
    img.set_scale    = sprite_set_scale
    img.set_visible  = sprite_set_visible
    img.render       = sprite_render
    img.update_quad  = sprite_update_quad
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
        { "new",        _new },
        { "getColor",   _get_color },
        { "getPiv",     _get_piv },
        { "getPos",     _get_pos },
        { "getRot",     _get_rot},
        { "getScl",     _get_scl },
        { "isVisible",  _get_visible },
        { "setColor",   _set_color },
        { "setPiv",     _set_piv },
        { "setPos",     _set_pos },
        { "setRot",     _set_rot },
        { "setScl",     _set_scl },
        { "setVisible", _set_visible },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiSprite", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

sprite_get_color :: proc(img: ^Sprite) -> linalg.Vector4f32 {
    return img.color
}

sprite_get_pivot :: proc(img: ^Sprite) -> (f32, f32) {
    return img.pivot.x, img.pivot.y
}

sprite_get_position :: proc(img: ^Sprite) -> (f32, f32) {
    return img.position.x, img.position.y
}

sprite_get_rotation :: proc(img: ^Sprite) -> f32 {
    return img.rotation
}

sprite_get_scale :: proc(img: ^Sprite) -> (f32, f32) {
    return img.scale.x, img.scale.y
}

sprite_set_pivot :: proc(img: ^Sprite, x, y: f32) {
    img.pivot = {f32(x), f32(y), 0}
    img.is_dirty = true
}

sprite_is_visible :: proc(img: ^Sprite) -> bool {
    return img.visible
}

sprite_set_color :: proc(img: ^Sprite, color: linalg.Vector4f32) {
    img.color = color
    img.is_dirty = true
}

sprite_set_position :: proc(img: ^Sprite, x, y: f32) {
    img.position = {f32(x), f32(y), 0}
    img.is_dirty = true
}

sprite_set_rotation :: proc(img: ^Sprite, angle: f32) {
    img.rotation = angle
    img.is_dirty = true
}

sprite_set_scale :: proc(img: ^Sprite, x, y: f32) {
    img.scale = {f32(x), f32(y), 1}
    img.is_dirty = true
}

sprite_set_visible :: proc(img: ^Sprite, visible: bool) {
    img.visible = visible
}

sprite_render :: proc(img: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32) {
    if ! img.visible {
        return
    }

    if img.is_dirty {
        img->update_quad(screen_width, screen_height, screen_ratio)
        img.vertex_buffer.pos = 0
        img.vertex_buffer->add(img.quad[:], size_of(img.quad))
        img.is_dirty = false
    } else {
        img.vertex_buffer->bind()
    }

    img.vertex_array->bind()
    img.texture->bind()
    gl.DrawElements(gl.TRIANGLES, img.index_buffer.count, gl.UNSIGNED_INT, nil)
}

sprite_update_quad :: proc(img: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32) {
    pos_normalized: linalg.Vector3f32
    pos_normalized.x = (img.position.x + f32(screen_width) * 0.5) / f32(screen_width)
    pos_normalized.x = pos_normalized.x * screen_ratio * 2 - screen_ratio
    pos_normalized.y = (img.position.y + f32(screen_height) * 0.5) / f32(screen_height)
    pos_normalized.y = pos_normalized.y * 2 - 1

    piv_normalized: linalg.Vector3f32
    piv_normalized.x = (img.pivot.x + f32(screen_width) * 0.5) / f32(screen_width)
    piv_normalized.x = piv_normalized.x * screen_ratio * 2 - screen_ratio
    piv_normalized.y = (img.pivot.y + f32(screen_height) * 0.5) / f32(screen_height)

    size_normalized: linalg.Vector3f32
    size_normalized.x = f32(img.width) / f32(screen_width) * screen_ratio
    size_normalized.y = f32(img.height) / f32(screen_height)

    model_matrix: linalg.Matrix4f32 = 1

    model_matrix *= linalg.matrix4_scale(img.scale)

    model_matrix *= linalg.matrix4_translate(linalg.Vector3f32{piv_normalized.x, piv_normalized.y, 0})
    model_matrix *= linalg.matrix4_rotate(math.to_radians(img.rotation), linalg.Vector3f32{0, 0, 1})
    model_matrix *= linalg.matrix4_translate(linalg.Vector3f32{-piv_normalized.x, -piv_normalized.y, 0})

    model_matrix *= linalg.matrix4_translate(pos_normalized)

    a := model_matrix * linalg.Vector4f32{ size_normalized.x,  size_normalized.y, 0.0, 1.0}
    b := model_matrix * linalg.Vector4f32{ size_normalized.x, -size_normalized.y, 0.0, 1.0}
    c := model_matrix * linalg.Vector4f32{-size_normalized.x, -size_normalized.y, 0.0, 1.0}
    d := model_matrix * linalg.Vector4f32{-size_normalized.x,  size_normalized.y, 0.0, 1.0}

    // set positions
    img.quad[0]  = a[0]
    img.quad[1]  = a[1]
    img.quad[2]  = a[2]
    img.quad[9]  = b[0]
    img.quad[10] = b[1]
    img.quad[11] = b[2]
    img.quad[18] = c[0]
    img.quad[19] = c[1]
    img.quad[20] = c[2]
    img.quad[27] = d[0]
    img.quad[28] = d[1]
    img.quad[29] = d[2]

    // set color
    img.quad[3]  = img.color.r
    img.quad[4]  = img.color.g
    img.quad[5]  = img.color.b
    img.quad[6]  = img.color.a
    img.quad[12] = img.color.r
    img.quad[13] = img.color.g
    img.quad[14] = img.color.b
    img.quad[15] = img.color.a
    img.quad[21] = img.color.r
    img.quad[22] = img.color.g
    img.quad[23] = img.color.b
    img.quad[24] = img.color.a
    img.quad[30] = img.color.r
    img.quad[31] = img.color.g
    img.quad[32] = img.color.b
    img.quad[33] = img.color.a
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.newuserdata(L, size_of(Sprite)))
    path := lua.L_checkstring(L, 1)

    texture := Texture.Init(string(path))
    Init(sprite, &texture)

    LuaRuntime.BindClassMetatable(L, "LakshmiSprite")

    return 1
}

_get_color :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    color := sprite->get_color()

    lua.pushnumber(L, lua.Number(color.r * 255))
    lua.pushnumber(L, lua.Number(color.g * 255))
    lua.pushnumber(L, lua.Number(color.b * 255))
    lua.pushnumber(L, lua.Number(color.a * 255))

    return 4
}

_get_piv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    x, y := sprite->get_pivot()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    x, y := sprite->get_position()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    angle := sprite->get_rotation()

    lua.pushnumber(L, lua.Number(angle))

    return 1
}

_get_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    x, y := sprite->get_scale()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    visible := sprite->is_visible()

    lua.pushboolean(L, b32(visible))

    return 1
}

_set_color :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -5))
    r := f32(lua.tonumber(L, -4)) / 255
    g := f32(lua.tonumber(L, -3)) / 255
    b := f32(lua.tonumber(L, -2)) / 255
    a := f32(lua.tonumber(L, -1)) / 255
    sprite->set_color(linalg.Vector4f32{r, g, b, a})

    return 0
}

_set_piv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, 1))
    x := f32(lua.tonumber(L, 2))
    y := f32(lua.tonumber(L, 3))
    sprite->set_pivot(x, y)

    return 0
}

_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))
    sprite->set_position(x, y)

    return 0
}

_set_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -2))
    angle := f32(lua.tonumber(L, -1))
    sprite->set_rotation(angle)

    return 0
}

_set_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))
    sprite->set_scale(x, y)

    return 0
}

_set_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -2))
    sprite->set_visible(bool(lua.toboolean(L, -1)))

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    Destroy(sprite)

    return 0
}
