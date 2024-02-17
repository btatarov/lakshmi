package camera

import "core:math"
import "core:math/linalg"

Camera :: struct {
    projection: linalg.Matrix4f32,
    view:       linalg.Matrix4f32,
    vp:         linalg.Matrix4f32,
    position:   linalg.Vector3f32,
    rotation:   f32,

    get_position:           proc(camera: ^Camera) -> ^linalg.Vector3f32,
    get_projection_matrix:  proc(camera: ^Camera) -> ^linalg.Matrix4f32,
    get_rotation:           proc(camera: ^Camera) -> f32,
    get_view_matrix:        proc(camera: ^Camera) -> ^linalg.Matrix4f32,
    get_vp_matrix:          proc(camera: ^Camera) -> ^linalg.Matrix4f32,

    set_position:           proc(camera: ^Camera, position: linalg.Vector3f32),
    set_projection_matrix:  proc(camera: ^Camera, left, right, bottom, top: f32),
    set_rotation:           proc(camera: ^Camera, rotation: f32),

    update_view_matrix:     proc(camera: ^Camera),
}

Init :: proc(left, right, bottom, top: f32) -> (camera: Camera) {
    camera.projection = linalg.matrix_ortho3d(left, right, bottom, top, -1, 1)

    camera.get_position = camera_get_position
    camera.get_projection_matrix = camera_get_projection_matrix
    camera.get_rotation = camera_get_rotation
    camera.get_view_matrix = camera_get_view_matrix
    camera.get_vp_matrix = camera_get_vp_matrix
    camera.set_position = camera_set_position
    camera.set_projection_matrix = camera_set_projection_matrix
    camera.set_rotation = camera_set_rotation
    camera.update_view_matrix = camera_update_view_matrix

    camera->set_projection_matrix(left, right, bottom, top)

    return
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

camera_update_view_matrix :: proc(camera: ^Camera) {
    transform := linalg.matrix4_translate(camera.position)
    transform *= linalg.matrix4_rotate(math.to_radians(camera.rotation), linalg.Vector3f32{0, 0, 1})

    camera.view = linalg.matrix4_inverse(transform)
    camera.vp = camera.projection * camera.view
}
