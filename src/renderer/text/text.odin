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

    get_position: proc(text: ^Text) -> (f32, f32),
    set_position: proc(text: ^Text, x, y: f32),
    set_visible:  proc(text: ^Text, visible: bool),
}

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
        // TODO: load from cache first
        width, height, x_offset, y_offset: i32
        bitmap := stbtt.GetCodepointBitmap(&font, 0, scale, char, &width, &height, &x_offset, &y_offset)
        defer stbtt.FreeBitmap(bitmap, nil)

        // flip vertically
        for y: i32 = 0; y < height / 2; y += 1 {
            for x: i32 = 0; x < width; x += 1 {
                i0 := y * width + x
                i1 := (height - y - 1) * width + x
                bitmap[i0], bitmap[i1] = bitmap[i1], bitmap[i0]
            }
        }

        if i == 0 {
            x_first = f32(width) / 2
        }

        x_pos := x_total + f32(width) / 2 - x_first
        y_pos := - f32(y_offset) / 2

        height_total = max(u32(height), height_total)

        identifier := fmt.tprintf("%s__%d__%r", font_path, size, char)
        texture := Texture.Init(identifier, bitmap, width, height, 1)

        sprite: Sprite.Sprite
        Sprite.Init(&sprite, &texture)
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

    // position based on centerrorigin point
    for &sprite in text.sprites {
        x, y := sprite->get_position()
        sprite->set_position(x - f32(text.width) / 2, y - f32(text.height) / 2)
    }

    text.get_position = text_get_position
    text.set_position = text_set_position
    text.set_visible  = text_set_visible
}

Destroy :: proc(text: ^Text) {
    log.debugf("LakshmiText: Destroy\n")

    for &sprite in text.sprites {
        Sprite.Destroy(&sprite)
    }
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
}

LuaUnbind :: proc(L: ^lua.State) {
    // Empty
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
        fmt.println(x_old, y_old)
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
    fmt.println(text)
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
