package box2d_box

import "core:log"
import "core:math"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import World "../../world"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Box :: struct {
    polygon:    b2.Polygon,
    body:       b2.BodyDef,
    body_id:    b2.BodyId,
    shape:      b2.ShapeDef,
    shape_id:   b2.ShapeId,
    idx:        int,
}

@private boxes: [dynamic]^Box

Init :: proc(box: ^Box, w, h : f32) {
    log.debugf("LakshmiBox2DBox: Init\n")

    box.polygon = b2.MakeBox(w, h)

    box.body = b2.DefaultBodyDef()
    box.body.type = .staticBody
    box.body.position = { 0, 0 }
    box.body_id = b2.CreateBody(World.GetWorld().id, box.body)

    box.shape = b2.DefaultShapeDef()
    box.shape_id = b2.CreatePolygonShape(box.body_id, box.shape, box.polygon)

    box.idx = len(boxes)
}

Destroy :: proc(box: ^Box) {
    log.debugf("LakshmiBox2DBox: Destroy\n")

    b2.DestroyShape(box.shape_id)
    b2.DestroyBody(box.body_id)

    ordered_remove(&boxes, box.idx)
    for i in box.idx+1..<len(boxes) {
        boxes[i].idx -= 1
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",            _new },
        { "getPos",         _getPos },
        { "getRot",         _getRot },
        { "getRestitution", _getRestitution },
        { "getFriction",    _getFriction },
        { "setPos",         _setPos },
        { "setRot",         _setRot },
        { "setFriction",    _setFriction },
        { "setRestitution", _setRestitution },
        { "setBodyType",    _setBodyType },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DBox", &reg_table, __gc)

    boxes = make([dynamic]^Box)
}

LuaUnbind :: proc(L: ^lua.State) {
    delete(boxes)
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.newuserdata(L, size_of(Box)))
    w := f32(lua.tonumber(L, 1))
    h := f32(lua.tonumber(L, 2))

    Init(box, w, h)

    append(&boxes, box)

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DBox")

    return 1
}

_getPos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -1))
    p := b2.Body_GetWorldPoint(box.body_id, { 0, 0 })

    lua.pushnumber(L, lua.Number(p.x))
    lua.pushnumber(L, lua.Number(p.y))

    return 2
}

_getRot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -1))
    angle := math.to_degrees(b2.Rot_GetAngle(b2.Body_GetRotation(box.body_id)))

    lua.pushnumber(L, lua.Number(angle))

    return 1
}

_getRestitution :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -1))
    restitution := b2.Shape_GetRestitution(box.shape_id)

    lua.pushnumber(L, lua.Number(restitution))

    return 1
}

_getFriction :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -1))
    friction := b2.Shape_GetFriction(box.shape_id)

    lua.pushnumber(L, lua.Number(friction))

    return 1
}

_setPos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))

    box.body.position = { x, y }
    b2.Body_SetTransform(box.body_id, box.body.position, box.body.rotation)

    return 0
}

_setRot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -2))
    angle := f32(lua.tonumber(L, -1))

    box.body.rotation = b2.MakeRot(math.to_radians(angle))
    b2.Body_SetTransform(box.body_id, box.body.position, box.body.rotation)

    return 0
}

_setRestitution :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -2))
    restitution := f32(lua.tonumber(L, -1))

    box.shape.restitution = restitution
    b2.Shape_SetRestitution(box.shape_id, box.shape.restitution)

    return 0
}

_setFriction :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -2))
    friction := f32(lua.tonumber(L, -1))

    box.shape.friction = friction
    b2.Shape_SetFriction(box.shape_id, box.shape.friction)

    return 0
}

_setBodyType :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -2))
    body_type := lua.tonumber(L, -1)

    box.body.type = b2.BodyType(body_type)
    b2.Body_SetType(box.body_id, box.body.type)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    box := (^Box)(lua.touserdata(L, -1))
    Destroy(box)

    return 0
}
