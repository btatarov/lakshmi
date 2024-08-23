package camera

import "core:math"
import "core:math/linalg"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

Camera :: struct {
    projection: linalg.Matrix4f32,
    view:       linalg.Matrix4f32,
    vp:         linalg.Matrix4f32,
    position:   linalg.Vector3f32,
    rotation:   f32,
    screen:     [2]i32,
    screen_pos: [2]f32,

    get_position:           proc(camera: ^Camera) -> ^linalg.Vector3f32,
    get_projection_matrix:  proc(camera: ^Camera) -> ^linalg.Matrix4f32,
    get_rotation:           proc(camera: ^Camera) -> f32,
    get_view_matrix:        proc(camera: ^Camera) -> ^linalg.Matrix4f32,
    get_vp_matrix:          proc(camera: ^Camera) -> ^linalg.Matrix4f32,

    set_position:           proc(camera: ^Camera, position: linalg.Vector3f32),
    set_projection_matrix:  proc(camera: ^Camera, left, right, bottom, top: f32),
    set_rotation:           proc(camera: ^Camera, rotation: f32),
    set_screen_size:        proc(camera: ^Camera, width, height: i32),

    update_view_matrix:     proc(camera: ^Camera),
}

@private camera: Camera

Init :: proc(left, right, bottom, top: f32) -> ^Camera {
    camera.projection = linalg.matrix_ortho3d(left, right, bottom, top, -1, 1)

    camera.get_position = camera_get_position
    camera.get_projection_matrix = camera_get_projection_matrix
    camera.get_rotation = camera_get_rotation
    camera.get_view_matrix = camera_get_view_matrix
    camera.get_vp_matrix = camera_get_vp_matrix
    camera.set_position = camera_set_position
    camera.set_projection_matrix = camera_set_projection_matrix
    camera.set_rotation = camera_set_rotation
    camera.set_screen_size = camera_set_screen_size
    camera.update_view_matrix = camera_update_view_matrix

    camera->set_projection_matrix(left, right, bottom, top)

    return &camera
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "getPos", _get_pos },
        { "getRot", _get_rot },
        { "setPos", _set_pos },
        { "setRot", _set_rot },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiCamera", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

camera_get_position :: proc(camera: ^Camera) -> ^linalg.Vector3f32 {
    return &camera.position
}

camera_get_projection_matrix :: proc(camera: ^Camera) -> ^linalg.Matrix4f32 {
    return &camera.projection
}

camera_get_rotation :: proc(camera: ^Camera) -> f32 {
    return camera.rotation
}

camera_get_view_matrix :: proc(camera: ^Camera) -> ^linalg.Matrix4f32 {
    return &camera.view
}

camera_get_vp_matrix :: proc(camera: ^Camera) -> ^linalg.Matrix4f32 {
    return &camera.vp
}

camera_set_position :: proc(camera: ^Camera, position: linalg.Vector3f32) {
    camera.position = position
    camera->update_view_matrix()
}

camera_set_projection_matrix :: proc(camera: ^Camera, left, right, bottom, top: f32) {
    camera.projection = linalg.matrix_ortho3d(left, right, bottom, top, -1, 1)
    camera->update_view_matrix()
}

camera_set_rotation :: proc(camera: ^Camera, rotation: f32) {
    camera.rotation = rotation
    camera->update_view_matrix()
}

camera_set_screen_size :: proc(camera: ^Camera, width, height: i32) {
    camera.screen = {width, height}
}

camera_update_view_matrix :: proc(camera: ^Camera) {
    transform := linalg.matrix4_translate(camera.position)
    transform *= linalg.matrix4_rotate(math.to_radians(camera.rotation), linalg.Vector3f32{0, 0, 1})

    camera.view = linalg.matrix4_inverse(transform)
    camera.vp = camera.projection * camera.view
}

_get_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    lua.pushnumber(L, lua.Number(camera.screen_pos.x))
    lua.pushnumber(L, lua.Number(camera.screen_pos.y))

    return 2
}

_get_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    angle := camera->get_rotation()

    lua.pushnumber(L, lua.Number(angle))

    return 1
}

_set_pos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    screen_ratio := f32(camera.screen.x) / f32(camera.screen.y)

    x := f32(lua.tonumber(L, -2))
    x_proj := (x + f32(camera.screen.x) * 0.5) / f32(camera.screen.x)
    x_proj = x_proj * screen_ratio * 2 - screen_ratio

    y := f32(lua.tonumber(L, -1))
    y_proj := (y + f32(camera.screen.y) * 0.5) / f32(camera.screen.y)
    y_proj = y_proj * 2 - 1

    camera.screen_pos = {x, y}
    camera->set_position(linalg.Vector3f32{x_proj, y_proj, 0})

    return 0
}

_set_rot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    angle := f32(lua.tonumber(L, -1))
    camera->set_rotation(angle)

    return 0
}
