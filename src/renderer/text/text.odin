package renderer_text

import "core:fmt"
import "core:log"
import "core:os"
import "core:math/linalg"

import lua "vendor:lua/5.4"
import stbtt "vendor:stb/truetype"

import Renderable "../renderable"
import Sprite "../sprite"
import Texture "../texture"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

Text :: struct {
    using renderable: Renderable.Renderable,

    width:            u32,
    height:           u32,
    position:         linalg.Vector3f32,
    pivot:            linalg.Vector3f32,
    scale:            linalg.Vector3f32,
    rotation:         f32,
    visible:          bool,

    color:            linalg.Vector4f32,

    str:              string,
    sprites:          [dynamic]Sprite.Sprite,

    is_gone:          bool,

    get_color:        proc(text: ^Text) -> linalg.Vector4f32,
    get_pivot:        proc(text: ^Text) -> (f32, f32),
    get_position:     proc(text: ^Text) -> (f32, f32),
    get_rotation:     proc(text: ^Text) -> f32,
    get_scale:        proc(text: ^Text) -> (f32, f32),
    is_visible:       proc(text: ^Text) -> bool,
    set_color:        proc(text: ^Text, color: linalg.Vector4f32),
    set_pivot:        proc(text: ^Text, x, y: f32),
    set_position:     proc(text: ^Text, x, y: f32),
    set_rotation:     proc(text: ^Text, angle: f32),
    set_scale:        proc(text: ^Text, x, y: f32),
    set_visible:      proc(text: ^Text, visible: bool),
}

GlyphCache :: struct {
    font_path: string,
    char:      rune,
    size:      f32,
    width:     i32,
    height:    i32,
    x_offset:  i32,
    y_offset:  i32,
    bitmap:    [^]byte,
}

@private glyph_cache: map[string]GlyphCache

Init :: proc(text: ^Text, font_path, str: string, size: f32) {
    log.debugf("LakshmiText: Init\n")

    text.renderable_type = .Text

    text.position = {0, 0, 0}
    text.pivot    = {0, 0, 0}
    text.scale    = 1
    text.rotation = 0
    text.visible  = true

    text.sprites = make([dynamic]Sprite.Sprite)
    text.str = str

    text.is_gone = false

    data, ok := os.read_entire_file(font_path)
    assert(ok, fmt.tprintf("LakshmiText: Failed to find font file: %s", font_path))

    font: stbtt.fontinfo
    stbtt.InitFont(&font, &data[0], 0)

    scale := stbtt.ScaleForPixelHeight(&font, f32(size))

    char_offset: u32 = 5
    x_first, x_total: f32
    height_total: u32
    for char, i in str {
        identifier := fmt.aprintf("%s__%d__%r", font_path, size, char)

        cache: GlyphCache
        bitmap: [^]byte
        width, height, x_offset, y_offset: i32
        if cache, ok = glyph_cache[identifier]; ok {
            bitmap   = cache.bitmap
            width    = cache.width
            height   = cache.height
            x_offset = cache.x_offset
            y_offset = cache.y_offset
        } else {
            bitmap = stbtt.GetCodepointBitmap(&font, 0, scale, char, &width, &height, &x_offset, &y_offset)

            glyph_cache[identifier] = GlyphCache {
                font_path = font_path,
                char      = char,
                size      = size,
                width     = width,
                height    = height,
                x_offset  = x_offset,
                y_offset  = y_offset,
                bitmap    = bitmap,
            }
        }

        if i == 0 {
            x_first = f32(width) / 2
        }

        x_pos := x_total + f32(width) / 2 - x_first
        y_pos := - f32(y_offset) / 2

        height_total = max(u32(height), height_total)

        texture := Texture.Init(identifier, bitmap, width, height, 1)

        sprite: Sprite.Sprite
        Sprite.Init(&sprite, texture)
        sprite->set_position(x_pos, y_pos)
        append(&text.sprites, sprite)

        x_total += f32(width) + f32(x_offset) / 2 + f32(char_offset)

        if i < len(str) - 1 {
            kern := stbtt.GetCodepointKernAdvance(&font, rune(str[i]), rune(str[i + 1]))
            x_total += f32(kern) * scale
        }
    }

    text.width = u32(x_total) - char_offset
    text.height = u32(height_total)
    text.position = linalg.Vector3f32{0, 0, 0}

    // position and pivot based on center origin point
    for &sprite in text.sprites {
        x, y := sprite->get_position()

        x_pos := x - f32(text.width) / 2
        y_pos := y - f32(text.height) / 2
        sprite->set_position(x_pos, y_pos)

        x_piv := 0 - x_pos
        y_piv := 0 - y_pos
        sprite->set_pivot(x_piv, y_piv)
    }

    text.get_color    = text_get_color
    text.get_pivot    = text_get_pivot
    text.get_position = text_get_position
    text.get_rotation = text_get_rotation
    text.get_scale    = text_get_scale
    text.is_visible   = text_is_visible
    text.set_color    = text_set_color
    text.set_pivot    = text_set_pivot
    text.set_position = text_set_position
    text.set_rotation = text_set_rotation
    text.set_scale    = text_set_scale
    text.set_visible  = text_set_visible
}

Destroy :: proc(text: ^Text) {
    if text.is_gone {
        return
    }

    log.debugf("LakshmiText: Destroy\n")

    for &sprite in text.sprites {
        Sprite.Destroy(&sprite)
    }
    delete(text.sprites)

    text.is_gone = true
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",        _new },
        { "getColor",   _get_color },
        { "getPiv",     _get_piv },
        { "getPos",     _get_pos },
        { "getRot",     _get_rot },
        { "getScl",     _get_scl },
        { "getSize",    _get_size },
        { "isVisible",  _get_visible },
        { "setColor",   _set_color },
        { "setPiv",     _set_piv },
        { "setPos",     _set_pos },
        { "setRot",     _set_rot },
        { "setScl",     _set_scl },
        { "setVisible", _set_visible },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiText", &reg_table, __gc)

    glyph_cache = make(map[string]GlyphCache)
}

LuaUnbind :: proc(L: ^lua.State) {
    for key, _ in glyph_cache {
        stbtt.FreeBitmap(glyph_cache[key].bitmap, nil)
    }
    delete(glyph_cache)
}

text_get_color :: proc(text: ^Text) -> linalg.Vector4f32 {
    return text.color
}

text_get_pivot :: proc(text: ^Text) -> (f32, f32) {
    return text.pivot.x, text.pivot.y
}

text_get_position :: proc(text: ^Text) -> (f32, f32) {
    return text.position.x, text.position.y
}

text_get_rotation :: proc(text: ^Text) -> f32 {
    return text.rotation
}

text_get_scale :: proc(text: ^Text) -> (f32, f32) {
    return text.scale.x, text.scale.y
}

text_is_visible :: proc(text: ^Text) -> bool {
    return text.visible
}

text_set_color :: proc(text: ^Text, color: linalg.Vector4f32) {
    text.color = color

    for &sprite in text.sprites {
        sprite->set_color(color)
    }
}

text_set_pivot :: proc(text: ^Text, x, y: f32) {
    pivot_offset := linalg.Vector2f32 {
        x - text.pivot.x,
        y - text.pivot.y,
    }

    text.pivot = linalg.Vector3f32{x, y, 0}

    for &sprite in text.sprites {
        x_old, y_old := sprite->get_pivot()
        sprite->set_pivot(x_old + pivot_offset.x, y_old + pivot_offset.y)
    }
}

text_set_position :: proc(text: ^Text, x, y: f32) {
    position_offset := linalg.Vector2f32 {
        x - text.position.x,
        y - text.position.y,
    }

    text.position = linalg.Vector3f32{x, y, 0}

    for &sprite in text.sprites {
        x_old, y_old := sprite->get_position()
        sprite->set_position(x_old + position_offset.x, y_old + position_offset.y)
    }
}

text_set_rotation :: proc(text: ^Text, angle: f32) {
    text.rotation = angle

    for &sprite in text.sprites {
        sprite->set_rotation(angle)
    }
}

text_set_scale :: proc(text: ^Text, x, y: f32) {
    text.scale = linalg.Vector3f32{x, y, 1}

    for &sprite in text.sprites {
        sprite->set_scale(x, y)
    }
}

text_set_visible :: proc(text: ^Text, visible: bool) {
    text.visible = visible

    for &sprite in text.sprites {
        sprite->set_visible(visible)
    }
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.newuserdata(L, size_of(Text)))
    font := lua.tostring(L, 1)
    str := lua.tostring(L, 2)
    size := lua.tonumber(L, 3)

    Init(text, string(font), string(str), f32(size))

    LuaRuntime.BindClassMetatable(L, "LakshmiText")

    return 1
}

_get_color :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    color := text->get_color()

    lua.pushnumber(L, lua.Number(color.x))
    lua.pushnumber(L, lua.Number(color.y))
    lua.pushnumber(L, lua.Number(color.z))
    lua.pushnumber(L, lua.Number(color.w))

    return 4
}

_get_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    visible := text->is_visible()

    lua.pushboolean(L, b32(visible))

    return 1
}

_get_piv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x, y := text->get_pivot()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x, y := text->get_position()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    angle := text->get_rotation()

    lua.pushnumber(L, lua.Number(angle))

    return 1
}

_get_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x, y := text->get_scale()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_get_size :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))

    lua.pushnumber(L, lua.Number(text.width))
    lua.pushnumber(L, lua.Number(text.height))

    return 2
}

_set_color :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    color := linalg.Vector4f32{
        f32(lua.tonumber(L, 2)),
        f32(lua.tonumber(L, 3)),
        f32(lua.tonumber(L, 4)),
        f32(lua.tonumber(L, 5)),
    }
    text->set_color(color)

    return 0
}

_set_piv :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x := f32(lua.tonumber(L, 2))
    y := f32(lua.tonumber(L, 3))
    text->set_pivot(x, y)

    return 0
}

_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x := f32(lua.tonumber(L, 2))
    y := f32(lua.tonumber(L, 3))
    text->set_position(x, y)

    return 0
}

_set_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    angle := f32(lua.tonumber(L, 2))
    text->set_rotation(angle)

    return 0
}

_set_scl :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x := f32(lua.tonumber(L, 2))
    y := f32(lua.tonumber(L, 3))
    text->set_scale(x, y)

    return 0
}

_set_visible :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    visible := lua.toboolean(L, 2)
    text->set_visible(bool(visible))

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))

    Destroy(text)

    return 0
}
