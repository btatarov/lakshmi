package texture

import "core:fmt"

import "vendor:OpenGL"
import "vendor:stb/image"

Texture :: struct {
    path:       string,
    id:         u32,
    width:      i32,
    height:     i32,
    channels:   i32,

    bind:   proc(tex: ^Texture),
    unbind: proc(tex: ^Texture),
}

Init :: proc(path: cstring) -> (tex: Texture) {
    image.set_flip_vertically_on_load(1)
    data := image.load(path, &tex.width, &tex.height, &tex.channels, 0)
    assert(data != nil, fmt.tprintf("Failed to load texture: %s", path))
    defer image.image_free(data)

    internal_fmt: i32
    data_fmt: u32
    if tex.channels == 3 {
        internal_fmt = OpenGL.RGB8
        data_fmt = OpenGL.RGB
    } else if tex.channels == 4 {
        internal_fmt = OpenGL.RGBA8
        data_fmt = OpenGL.RGBA
    } else {
        assert(false, fmt.tprintf("Unsupported number of channels: %d", tex.channels))
    }

    OpenGL.GenTextures(1, &tex.id)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, tex.id)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_S, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_T, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MIN_FILTER, OpenGL.LINEAR)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MAG_FILTER, OpenGL.NEAREST)
    OpenGL.TexImage2D(OpenGL.TEXTURE_2D, 0, internal_fmt, i32(tex.width), i32(tex.height), 0, data_fmt, OpenGL.UNSIGNED_BYTE, rawptr(data))
    OpenGL.GenerateMipmap(OpenGL.TEXTURE_2D)

    tex.path = string(path)

    tex.bind   = texture_bind
    tex.unbind = texture_unbind

    return
}

Destroy :: proc(tex: ^Texture) {
    OpenGL.DeleteTextures(1, &tex.id)
}

texture_bind :: proc(tex: ^Texture) {
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, tex.id)
}

texture_unbind :: proc(_: ^Texture) {
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, 0)
}
