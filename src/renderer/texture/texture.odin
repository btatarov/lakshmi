package render_texture

import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

Texture :: struct {
    id:         u32,
    ref_count:  u32,
    slot:       u32,
    width:      i32,
    height:     i32,
    channels:   i32,
    identifier: string,

    bind:   proc(tex: ^Texture),
    unbind: proc(tex: ^Texture),
}

TextureCache :: struct {
    textures:       map[string]Texture,
    bound_texture:  u32,
}

@private texture_cache: TextureCache

Init :: proc { InitWithPath, InitWithData }

InitWithPath :: proc(path: string) -> Texture {
    tex := texture_cache.textures[path]
    if tex.identifier == path && tex.id != 0 && tex.ref_count > 0 {
        tex.ref_count += 1
        return tex
    }

    stbi.set_flip_vertically_on_load(1)
    data := stbi.load(strings.clone_to_cstring(path, context.temp_allocator), &tex.width, &tex.height, &tex.channels, 0)
    assert(data != nil, fmt.tprintf("Failed to load texture: %s", path))
    defer stbi.image_free(data)

    InitInternal(&tex, path, data)

    return tex
}

InitWithData :: proc(identifier: string, data: [^]byte, width, height, channels: i32) -> Texture {
    tex := texture_cache.textures[identifier]
    if tex.identifier == identifier && tex.id != 0 && tex.ref_count > 0 {
        tex.ref_count += 1
        return tex
    }

    tex.width    = width
    tex.height   = height
    tex.channels = channels

    InitInternal(&tex, identifier, data)

    return tex
}

@private
InitInternal :: proc(tex: ^Texture, identifier: string, data: rawptr) {
    internal_fmt: i32
    data_fmt: u32
    if tex.channels == 1 {
        internal_fmt = gl.RGB
        data_fmt = gl.RED
    } else if tex.channels == 3 {
        internal_fmt = gl.RGB8
        data_fmt = gl.RGB
    } else if tex.channels == 4 {
        internal_fmt = gl.RGBA8
        data_fmt = gl.RGBA
    } else {
        assert(false, fmt.tprintf("Unsupported number of channels: %d", tex.channels))
    }

    gl.GenTextures(1, &tex.id)
    gl.BindTexture(gl.TEXTURE_2D, tex.id)
    if tex.channels == 1 {
        gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    }
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexImage2D(gl.TEXTURE_2D, 0, internal_fmt, i32(tex.width), i32(tex.height), 0, data_fmt, gl.UNSIGNED_BYTE, data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    tex.ref_count  = 1
    tex.slot       = u32(len(texture_cache.textures)) + 1  // 0 is reserved for empty texture
    tex.identifier = identifier

    tex.bind   = texture_bind
    tex.unbind = texture_unbind

    texture_cache.textures[identifier] = tex^
}

Destroy :: proc(tex: ^Texture) {
    tex.ref_count -= 1
    if tex.ref_count == 0 {
        delete_key(&texture_cache.textures, tex.identifier)
        gl.DeleteTextures(1, &tex.id)
    }
}

texture_bind :: proc(tex: ^Texture) {
    if texture_cache.bound_texture == tex.id {
        return
    }
    texture_cache.bound_texture = tex.id
    gl.BindTexture(gl.TEXTURE_2D, tex.id)
}

texture_unbind :: proc(_: ^Texture) {
    texture_cache.bound_texture = 0
    gl.BindTexture(gl.TEXTURE_2D, 0)
}
