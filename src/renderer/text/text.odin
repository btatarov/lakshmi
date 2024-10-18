package renderer_text

import "core:fmt"
import "core:log"
import "core:os"
import "core:math/linalg"

import lua "vendor:lua/5.4"
import stbtt "vendor:stb/truetype"

import Sprite "../sprite"
import Texture "../texture"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

Text :: struct {
    width:    u32,
    height:   u32,
    position: linalg.Vector3f32,
    str:      string,
    sprites:  [dynamic]Sprite.Sprite,

    is_gone:  bool,

    get_position: proc(text: ^Text) -> (f32, f32),
    set_position: proc(text: ^Text, x, y: f32),
    set_visible:  proc(text: ^Text, visible: bool),
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

    text.sprites = make([dynamic]Sprite.Sprite)
    text.str = str

    data, ok := os.read_entire_file(font_path)
    assert(ok, fmt.tprintf("LakshmiText: Failed to find font file: %s", font_path))

    font: stbtt.fontinfo
    stbtt.InitFont(&font, &data[0], 0)

    scale := stbtt.ScaleForPixelHeight(&font, f32(size))

    char_offset: u32 = 5
    x_first, x_total: f32
    height_total: u32
    for char, i in str {
        identifier := fmt.tprintf("%s__%d__%r", font_path, size, char)

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

    // position based on center origin point
    for &sprite in text.sprites {
        x, y := sprite->get_position()
        sprite->set_position(x - f32(text.width) / 2, y - f32(text.height) / 2)
    }

    text.get_position = text_get_position
    text.set_position = text_set_position
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
        { "getPos",     _get_pos },
        { "setPos",     _set_pos },
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

text_get_position :: proc(text: ^Text) -> (f32, f32) {
    return text.position.x, text.position.y
}

text_set_position :: proc(text: ^Text, x, y: f32) {
    position_offset := linalg.Vector2f32 {
        x - text.position.x,
        y - text.position.y,
    }
    _ = position_offset

    text.position = linalg.Vector3f32{x, y, 0}

    for &sprite in text.sprites {
        x_old, y_old := sprite->get_position()
        sprite->set_position(x_old + position_offset.x, y_old + position_offset.y)
    }
}

text_set_visible :: proc(text: ^Text, visible: bool) {
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

_get_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x, y := text->get_position()

    lua.pushnumber(L, lua.Number(x))
    lua.pushnumber(L, lua.Number(y))

    return 2
}

_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    text := (^Text)(lua.touserdata(L, 1))
    x := f32(lua.tonumber(L, 2))
    y := f32(lua.tonumber(L, 3))
    text->set_position(x, y)

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
