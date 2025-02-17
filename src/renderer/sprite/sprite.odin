package renderer_sprite

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:strings"

import lua "vendor:lua/5.4"
import gl "vendor:OpenGL"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

import VertexArray "../buffers/array"
import IndexBuffer "../buffers/index"
import VertexBuffer "../buffers/vertex"
import Renderable "../renderable"
import Texture "../texture"

@private sprite_count: u32

Sprite :: struct {
    using renderable: Renderable.Renderable,

    width:            u32,
    height:           u32,
    position:         linalg.Vector3f32,
    pivot:            linalg.Vector3f32,
    scale:            linalg.Vector3f32,
    rotation:         f32,
    visible:          bool,

    texture_id:       string,
    color:            linalg.Vector4f32,
    uv0:              linalg.Vector2f32,
    uv1:              linalg.Vector2f32,

    quad:             [4 * 9]f32,
    indices:          [2 * 3]u32,
    is_dirty:         bool,

    is_gone:          bool,

    index_buffer:     IndexBuffer.IndexBuffer,
    vertex_array:     VertexArray.VertexArray,
    vertex_buffer:    VertexBuffer.VertexBuffer,

    get_color:        proc(sprite: ^Sprite) -> linalg.Vector4f32,
    get_pivot:        proc(sprite: ^Sprite) -> (f32, f32),
    get_position:     proc(sprite: ^Sprite) -> (f32, f32),
    get_rotation:     proc(sprite: ^Sprite) -> f32,
    get_scale:        proc(sprite: ^Sprite) -> (f32, f32),
    get_texture:      proc(sprite: ^Sprite) -> ^Texture.Texture,
    get_size:         proc(sprite: ^Sprite) -> (u32, u32),
    get_uv:           proc(sprite: ^Sprite) -> (f32, f32, f32, f32),
    is_visible:       proc(sprite: ^Sprite) -> bool,
    set_color:        proc(sprite: ^Sprite, color: linalg.Vector4f32),
    set_pivot:        proc(sprite: ^Sprite, x, y: f32),
    set_position:     proc(sprite: ^Sprite, x, y: f32),
    set_rotation:     proc(sprite: ^Sprite, angle: f32),
    set_scale:        proc(sprite: ^Sprite, x, y: f32),
    set_size:         proc(sprite: ^Sprite, width, height: u32),
    set_uv:           proc(sprite: ^Sprite, u, v, w, h: f32),
    set_visible:      proc(sprite: ^Sprite, visible: bool),
    render:           proc(sprite: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32),
    update_quad:      proc(sprite: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32),
}

Init :: proc(sprite: ^Sprite, texture: ^Texture.Texture) {
    log.debugf("LakshmiSprite: Init\n")

    sprite.renderable_type = .Sprite

    sprite.position = {0, 0, 0}
    sprite.pivot    = {0, 0, 0}
    sprite.scale    = 1
    sprite.rotation = 0
    sprite.visible  = true

    sprite.texture_id = strings.clone(texture.identifier)

    sprite.color = {1, 1, 1, 1}
    sprite.uv0   = {0, 0}
    sprite.uv1   = {1, 1}

    sprite.width, sprite.height = u32(texture.width), u32(texture.height)

    sprite.quad = {
        // positions        // colors               // uv coords
        -0.5,  0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     0.0, 0.0,  // top left
         0.5,  0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     1.0, 0.0,  // top right
         0.5, -0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     1.0, 1.0,  // bottom right
        -0.5, -0.5, 0.0,    1.0, 1.0, 1.0, 1.0,     0.0, 1.0,  // bottom left
    }

    sprite.indices = {
        0, 1, 3,
        1, 2, 3,
    }

    sprite.is_dirty = true
    sprite.is_gone = false

    sprite.vertex_buffer = VertexBuffer.Init(4 * 9 * size_of(f32))
    sprite.vertex_array = VertexArray.Init()
    sprite.index_buffer = IndexBuffer.Init(len(sprite.indices))
    sprite.index_buffer->add(sprite.indices[:], len(sprite.indices))

    sprite.get_color    = sprite_get_color
    sprite.get_pivot    = sprite_get_pivot
    sprite.get_position = sprite_get_position
    sprite.get_rotation = sprite_get_rotation
    sprite.get_scale    = sprite_get_scale
    sprite.get_size     = sprite_get_size
    sprite.get_texture  = sprite_get_texture
    sprite.get_uv       = sprite_get_uv
    sprite.is_visible   = sprite_is_visible
    sprite.set_color    = sprite_set_color
    sprite.set_pivot    = sprite_set_pivot
    sprite.set_position = sprite_set_position
    sprite.set_rotation = sprite_set_rotation
    sprite.set_scale    = sprite_set_scale
    sprite.set_size     = sprite_set_size
    sprite.set_uv       = sprite_set_uv
    sprite.set_visible  = sprite_set_visible
    sprite.render       = sprite_render
    sprite.update_quad  = sprite_update_quad

    sprite_count += 1
}

Destroy :: proc(sprite: ^Sprite) {
    if sprite.is_gone {
        return
    }

    log.debugf("LakshmiSprite: Destroy\n")

    Texture.Destroy(sprite->get_texture())
    VertexBuffer.Destroy(&sprite.vertex_buffer)
    VertexArray.Destroy(&sprite.vertex_array)
    IndexBuffer.Destroy(&sprite.index_buffer)

    sprite.is_gone = true
    sprite_count -= 1
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",        _new },
        { "getColor",   _get_color },
        { "getPiv",     _get_piv },
        { "getPos",     _get_pos },
        { "getRot",     _get_rot},
        { "getScl",     _get_scl },
        { "getSize",    _get_size },
        { "getUV",      _get_uv },
        { "isVisible",  _get_visible },
        { "setColor",   _set_color },
        { "setPiv",     _set_piv },
        { "setPos",     _set_pos },
        { "setRot",     _set_rot },
        { "setScl",     _set_scl },
        { "setSize",    _set_size },
        { "setUV",      _set_uv },
        { "setVisible", _set_visible },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiSprite", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

GetSpriteCount :: proc() -> u32 {
    return sprite_count
}

sprite_get_color :: proc(sprite: ^Sprite) -> linalg.Vector4f32 {
    return sprite.color
}

sprite_get_pivot :: proc(sprite: ^Sprite) -> (f32, f32) {
    return sprite.pivot.x, sprite.pivot.y
}

sprite_get_position :: proc(sprite: ^Sprite) -> (f32, f32) {
    return sprite.position.x, sprite.position.y
}

sprite_get_rotation :: proc(sprite: ^Sprite) -> f32 {
    return sprite.rotation
}

sprite_get_scale :: proc(sprite: ^Sprite) -> (f32, f32) {
    return sprite.scale.x, sprite.scale.y
}

sprite_get_size :: proc(sprite: ^Sprite) -> (u32, u32) {
    return sprite.width, sprite.height
}

sprite_get_texture :: proc(sprite: ^Sprite) -> ^Texture.Texture {
    return Texture.GetTexture(sprite.texture_id)
}

sprite_get_uv :: proc(sprite: ^Sprite) -> (f32, f32, f32, f32) {
    return expand_values(sprite.uv0), expand_values(sprite.uv1)
}

sprite_is_visible :: proc(sprite: ^Sprite) -> bool {
    return sprite.visible
}

sprite_set_color :: proc(sprite: ^Sprite, color: linalg.Vector4f32) {
    sprite.color = color
    sprite.is_dirty = true
}

sprite_set_pivot :: proc(sprite: ^Sprite, x, y: f32) {
    sprite.pivot = {f32(x), f32(y), 0}
    sprite.is_dirty = true
}

sprite_set_position :: proc(sprite: ^Sprite, x, y: f32) {
    sprite.position = {f32(x), f32(y), 0}
    sprite.is_dirty = true
}

sprite_set_rotation :: proc(sprite: ^Sprite, angle: f32) {
    sprite.rotation = angle
    sprite.is_dirty = true
}

sprite_set_scale :: proc(sprite: ^Sprite, x, y: f32) {
    sprite.scale = {f32(x), f32(y), 1}
    sprite.is_dirty = true
}

sprite_set_size :: proc(sprite: ^Sprite, width, height: u32) {
    sprite.width = width
    sprite.height = height
    sprite.is_dirty = true
}

sprite_set_uv :: proc(sprite: ^Sprite, u, v, w, h: f32) {
    sprite.uv0 = {u, v}
    sprite.uv1 = {u + w, v + h}
    sprite.is_dirty = true
}

sprite_set_visible :: proc(sprite: ^Sprite, visible: bool) {
    sprite.visible = visible
}

sprite_render :: proc(sprite: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32) {
    if sprite.is_dirty {
        sprite->update_quad(screen_width, screen_height, screen_ratio)
        sprite.vertex_buffer.pos = 0
        sprite.vertex_buffer->add(sprite.quad[:], size_of(sprite.quad))
        sprite.is_dirty = false
    } else {
        sprite.vertex_buffer->bind()
    }

    sprite.vertex_array->bind()

    gl.DrawElements(gl.TRIANGLES, sprite.index_buffer.count, gl.UNSIGNED_INT, nil)
}

sprite_update_quad :: proc(sprite: ^Sprite, screen_width, screen_height: i32, screen_ratio: f32) {
    pos_normalized: linalg.Vector3f32
    pos_normalized.x = (sprite.position.x + f32(screen_width) * 0.5) / f32(screen_width)
    pos_normalized.x = pos_normalized.x * screen_ratio * 2 - screen_ratio
    pos_normalized.y = (sprite.position.y + f32(screen_height) * 0.5) / f32(screen_height)
    pos_normalized.y = pos_normalized.y * 2 - 1

    piv_normalized: linalg.Vector3f32
    piv_normalized.x = (sprite.pivot.x + f32(screen_width) * 0.5) / f32(screen_width)
    piv_normalized.x = piv_normalized.x * screen_ratio * 2 - screen_ratio
    piv_normalized.y = (sprite.pivot.y + f32(screen_height) * 0.5) / f32(screen_height)
    piv_normalized.y = piv_normalized.y * 2 - 1

    size_normalized: linalg.Vector3f32
    size_normalized.x = f32(sprite.width) / f32(screen_width) * screen_ratio
    size_normalized.y = f32(sprite.height) / f32(screen_height)

    model_matrix: linalg.Matrix4f32 = 1
    model_matrix *= linalg.matrix4_translate(pos_normalized)
    model_matrix *= linalg.matrix4_translate(linalg.Vector3f32{piv_normalized.x, piv_normalized.y, 0})
    model_matrix *= linalg.matrix4_scale(sprite.scale)
    model_matrix *= linalg.matrix4_rotate(math.to_radians(sprite.rotation), linalg.Vector3f32{0, 0, 1})
    model_matrix *= linalg.matrix4_translate(linalg.Vector3f32{-piv_normalized.x, -piv_normalized.y, 0})

    a := model_matrix * linalg.Vector4f32{-size_normalized.x,  size_normalized.y, 0.0, 1.0}  // top left
    b := model_matrix * linalg.Vector4f32{ size_normalized.x,  size_normalized.y, 0.0, 1.0}  // top right
    c := model_matrix * linalg.Vector4f32{ size_normalized.x, -size_normalized.y, 0.0, 1.0}  // bottom right
    d := model_matrix * linalg.Vector4f32{-size_normalized.x, -size_normalized.y, 0.0, 1.0}  // bottom left

    // set positions
    swizzle(sprite.quad, 0, 1, 2)    = a.xyz
    swizzle(sprite.quad, 9, 10, 11)  = b.xyz
    swizzle(sprite.quad, 18, 19, 20) = c.xyz
    swizzle(sprite.quad, 27, 28, 29) = d.xyz

    // set color
    swizzle(sprite.quad, 3, 4, 5, 6)     = sprite.color
    swizzle(sprite.quad, 12, 13, 14, 15) = sprite.color
    swizzle(sprite.quad, 21, 22, 23, 24) = sprite.color
    swizzle(sprite.quad, 30, 31, 32, 33) = sprite.color

    // set uv coords
    swizzle(sprite.quad, 7, 8)   = {sprite.uv0.x, sprite.uv0.y}
    swizzle(sprite.quad, 16, 17) = {sprite.uv1.x, sprite.uv0.y}
    swizzle(sprite.quad, 25, 26) = {sprite.uv1.x, sprite.uv1.y}
    swizzle(sprite.quad, 34, 35) = {sprite.uv0.x, sprite.uv1.y}
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.newuserdata(L, size_of(Sprite)))
    path := lua.L_checkstring(L, 1)

    texture := Texture.Init(strings.clone_from_cstring(path))
    Init(sprite, texture)

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

_get_size :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    w, h := sprite->get_size()

    lua.pushnumber(L, lua.Number(w))
    lua.pushnumber(L, lua.Number(h))

    return 2
}

_get_uv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -1))
    u, v, w, h := sprite->get_uv()

    lua.pushnumber(L, lua.Number(u))
    lua.pushnumber(L, lua.Number(v))
    lua.pushnumber(L, lua.Number(w))
    lua.pushnumber(L, lua.Number(h))

    return 4
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

_set_size :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -3))
    w := u32(lua.tonumber(L, -2))
    h := u32(lua.tonumber(L, -1))
    sprite->set_size(w, h)

    return 0
}

_set_uv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    sprite := (^Sprite)(lua.touserdata(L, -5))
    u := f32(lua.tonumber(L, -4))
    v := f32(lua.tonumber(L, -3))
    w := f32(lua.tonumber(L, -2))
    h := f32(lua.tonumber(L, -1))
    sprite->set_uv(u, v, w, h)

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
