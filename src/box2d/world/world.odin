package box2d_world

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import Entity "../entity"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

World :: struct {
    entities:   map[b2.ShapeId]^Entity.Entity,
    def:        b2.WorldDef,
    id:         b2.WorldId,
    steps:      i32,
    is_active:  bool,
}

@private world: World

Init :: proc() {
    log.debugf("LakshmiBox2DWorld: Init\n")

    if ! world.is_active {
        world.def = b2.DefaultWorldDef()
        world.id = b2.CreateWorld(world.def)
        Entity.SetWorldRef(world.id, &world.entities)
    }

    if world.steps == 0 {
        world.steps = 4
    }
    world.is_active = true
    world.entities = make(map[b2.ShapeId]^Entity.Entity)
}

Destroy :: proc () {
    if world.is_active {
        log.debugf("LakshmiBox2DWorld: Destroy\n")
        b2.DestroyWorld(world.id)
        Entity.UnsetWorldRef()
    }

    world.is_active = false
    for _, &entity in world.entities {
        Entity.Destroy(entity)
    }
    delete(world.entities)
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "init",               _init },
        { "destroy",            _destroy },
        { "update",             _update },
        { "setGravity",         _setGravity },
        { "setUnitsPerMeter",   _setUnitsPerMeter },
        { "setUpdateSteps",     _setUpdateSteps },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiBox2DWorld", &reg_table)

    // bind constants
    lua.pushinteger(L, lua.Integer(b2.BodyType.staticBody))
    lua.setfield(L, -2, "BODY_TYPE_STATIC")
    lua.pushinteger(L, lua.Integer(b2.BodyType.kinematicBody))
    lua.setfield(L, -2, "BODY_TYPE_KINEMATIC")
    lua.pushinteger(L, lua.Integer(b2.BodyType.dynamicBody))
    lua.setfield(L, -2, "BODY_TYPE_DYNAMIC")
    lua.pushinteger(L, lua.Integer(Entity.CollisionEventType.Begin))
    lua.setfield(L, -2, "COLLISION_EVENT_BEGIN")
    lua.pushinteger(L, lua.Integer(Entity.CollisionEventType.End))
    lua.setfield(L, -2, "COLLISION_EVENT_END")
    lua.pushinteger(L, lua.Integer(Entity.CollisionEventType.Hit))
    lua.setfield(L, -2, "COLLISION_EVENT_HIT")
}

LuaUnbind :: proc(L: ^lua.State) {
    Destroy()
}

HandleCollision :: proc(entity_a, entity_b: ^Entity.Entity, type: Entity.CollisionEventType) {
    event := Entity.CollisionEvent{
        self = world.entities[entity_a.shape_id],
        other = world.entities[entity_b.shape_id],
        type = type,
    }
    event.self->handle_collision(event)

    event.self = world.entities[entity_b.shape_id]
    event.other = world.entities[entity_a.shape_id]
    event.self->handle_collision(event)
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    Init()

    return 0
}

_destroy :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    Destroy()

    return 0
}

_update :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    step := lua.tonumber(L, 1)

    if world.is_active {
        b2.World_Step(world.id, f32(step), world.steps)

        contact_events := b2.World_GetContactEvents(world.id)
        for idx in 0..<contact_events.beginCount {
            entity_a := world.entities[contact_events.beginEvents[idx].shapeIdA]
            entity_b := world.entities[contact_events.beginEvents[idx].shapeIdB]
            HandleCollision(entity_a, entity_b, .Begin)
        }
        for idx in 0..<contact_events.endCount {
            entity_a := world.entities[contact_events.endEvents[idx].shapeIdA]
            entity_b := world.entities[contact_events.endEvents[idx].shapeIdB]
            HandleCollision(entity_a, entity_b, .End)
        }
        for idx in 0..<contact_events.hitCount {
            entity_a := world.entities[contact_events.hitEvents[idx].shapeIdA]
            entity_b := world.entities[contact_events.hitEvents[idx].shapeIdB]
            HandleCollision(entity_a, entity_b, .Hit)
        }
    }

    return 0
}

_setGravity :: proc "c" (L: ^lua.State) -> i32 {
    x := f32(lua.tonumber(L, 1)) * b2.GetLengthUnitsPerMeter()
    y := f32(lua.tonumber(L, 2)) * b2.GetLengthUnitsPerMeter()

    world.def.gravity = { x, y }
    b2.World_SetGravity(world.id, world.def.gravity)

    return 0
}

_setUnitsPerMeter :: proc "c" (L: ^lua.State) -> i32 {
    units := lua.tonumber(L, 1)

    b2.SetLengthUnitsPerMeter(f32(units))

    return 0
}

_setUpdateSteps :: proc "c" (L: ^lua.State) -> i32 {
    steps := lua.tonumber(L, 1)

    world.steps = i32(steps)

    return 0
}
