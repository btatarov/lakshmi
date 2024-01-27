package texture

import "core:fmt"
import "core:image/png"

import "vendor:OpenGL"

Texture :: struct {
    path:   string,
    id:     u32,
    width:  u32,
    height: u32,

    bind:   proc(tex: ^Texture),
    unbind: proc(tex: ^Texture),
}

Init :: proc(path: string) -> (tex: Texture) {
    sprite, err := png.load_from_file(path)
    assert(err == nil , fmt.tprintf("Failed to load texture: %s", path))
    defer png.destroy(sprite)

    tex.path = path
    tex.width = u32(sprite.width)
    tex.height = u32(sprite.height)

    tex.bind   = texture_bind
    tex.unbind = texture_unbind

    OpenGL.GenTextures(1, &tex.id)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, tex.id)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_S, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_T, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MIN_FILTER, OpenGL.LINEAR)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MAG_FILTER, OpenGL.NEAREST)
    OpenGL.TexImage2D(OpenGL.TEXTURE_2D, 0, OpenGL.RGBA, i32(sprite.width), i32(sprite.height), 0, OpenGL.RGBA, OpenGL.UNSIGNED_BYTE, raw_data(sprite.pixels.buf))
    OpenGL.GenerateMipmap(OpenGL.TEXTURE_2D)

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
