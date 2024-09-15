package box2d_entity

import "core:log"
import "core:math"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import World "../world"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

EntityType :: enum {
    Polygon,
    Circle,
    Capsule,
}

Primitive :: struct {
    data: union {
        b2.Polygon,
        b2.Circle,
        b2.Capsule,
    },
    type: EntityType,
}

Entity :: struct {
    primitive:  ^Primitive,
    body:       b2.BodyDef,
    body_id:    b2.BodyId,
    shape:      b2.ShapeDef,
    shape_id:   b2.ShapeId,
    idx:        int,
}

@private entities: [dynamic]^Entity

Init :: proc(entity: ^Entity, primitive: ^Primitive) {
    log.debugf("LakshmiBox2DEntity: Init\n")

    entity.primitive = primitive

    entity.body = b2.DefaultBodyDef()
    entity.body.type = .staticBody
    entity.body.position = { 0, 0 }
    entity.body_id = b2.CreateBody(World.GetWorld().id, entity.body)

    entity.shape = b2.DefaultShapeDef()

    switch primitive.type {
        case .Polygon:
            entity.shape_id = b2.CreatePolygonShape(entity.body_id, entity.shape, entity.primitive.data.(b2.Polygon))
        case .Circle:
            entity.shape_id = b2.CreateCircleShape(entity.body_id, entity.shape, entity.primitive.data.(b2.Circle))
        case .Capsule:
            entity.shape_id = b2.CreateCapsuleShape(entity.body_id, entity.shape, entity.primitive.data.(b2.Capsule))
    }

    entity.idx = len(entities)
}

Destroy :: proc(entity: ^Entity) {
    log.debugf("LakshmiBox2DEntity: Destroy\n")

    b2.DestroyShape(entity.shape_id)
    b2.DestroyBody(entity.body_id)

    ordered_remove(&entities, entity.idx)
    for i in entity.idx+1..<len(entities) {
        entities[i].idx -= 1
    }
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new",                _new },
        { "getPos",             _getPos },
        { "getRot",             _getRot },
        { "getFriction",        _getFriction },
        { "getRestitution",     _getRestitution },
        { "getLinearVelocity",  _getLinearVelocity },
        { "getAngularVelocity", _getAngularVelocity },
        { "getBodyType",        _getBodyType },
        { "setPos",             _setPos },
        { "setRot",             _setRot },
        { "setFriction",        _setFriction },
        { "setRestitution",     _setRestitution },
        { "setLinearVelocity",  _setLinearVelocity },
        { "setAngularVelocity", _setAngularVelocity },
        { "setBodyType",        _setBodyType },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DEntity", &reg_table, __gc)

    entities = make([dynamic]^Entity)
}

LuaUnbind :: proc(L: ^lua.State) {
    delete(entities)
}

_new :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.newuserdata(L, size_of(Entity)))
    primitive := (^Primitive)(lua.touserdata(L, 1))

    Init(entity, primitive)

    append(&entities, entity)

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DEntity")

    return 1
}

_getPos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    p := b2.Body_GetWorldPoint(entity.body_id, { 0, 0 })

    lua.pushnumber(L, lua.Number(p.x))
    lua.pushnumber(L, lua.Number(p.y))

    return 2
}

_getRot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    angle := math.to_degrees(b2.Rot_GetAngle(b2.Body_GetRotation(entity.body_id)))

    lua.pushnumber(L, lua.Number(angle))

    return 1
}

_getFriction :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    friction := b2.Shape_GetFriction(entity.shape_id)

    lua.pushnumber(L, lua.Number(friction))

    return 1
}

_getRestitution :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    restitution := b2.Shape_GetRestitution(entity.shape_id)

    lua.pushnumber(L, lua.Number(restitution))

    return 1
}

_getLinearVelocity :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    v := b2.Body_GetLinearVelocity(entity.body_id)

    lua.pushnumber(L, lua.Number(v.x))
    lua.pushnumber(L, lua.Number(v.y))

    return 2
}

_getAngularVelocity :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    v := b2.Body_GetAngularVelocity(entity.body_id)

    lua.pushnumber(L, lua.Number(v))

    return 1
}

_getBodyType :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    body_type := b2.Body_GetType(entity.body_id)

    lua.pushnumber(L, lua.Number(body_type))

    return 1
}

_setPos :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))

    entity.body.position = { x, y }
    b2.Body_SetTransform(entity.body_id, entity.body.position, entity.body.rotation)

    return 0
}

_setRot :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -2))
    angle := f32(lua.tonumber(L, -1))

    entity.body.rotation = b2.MakeRot(math.to_radians(angle))
    b2.Body_SetTransform(entity.body_id, entity.body.position, entity.body.rotation)

    return 0
}

_setFriction :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -2))
    friction := f32(lua.tonumber(L, -1))

    entity.shape.friction = friction
    b2.Shape_SetFriction(entity.shape_id, entity.shape.friction)

    return 0
}

_setRestitution :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -2))
    restitution := f32(lua.tonumber(L, -1))

    entity.shape.restitution = restitution
    b2.Shape_SetRestitution(entity.shape_id, entity.shape.restitution)

    return 0
}

_setLinearVelocity :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -3))
    x := f32(lua.tonumber(L, -2))
    y := f32(lua.tonumber(L, -1))

    b2.Body_SetLinearVelocity(entity.body_id, { x, y })

    return 0
}

_setAngularVelocity :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -2))
    angle := f32(lua.tonumber(L, -1))

    b2.Body_SetAngularVelocity(entity.body_id, math.to_radians(angle))

    return 0
}

_setBodyType :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -2))
    body_type := lua.tonumber(L, -1)

    entity.body.type = b2.BodyType(body_type)
    b2.Body_SetType(entity.body_id, entity.body.type)

    return 0
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    entity := (^Entity)(lua.touserdata(L, -1))
    Destroy(entity)

    return 0
}
