package box2d_world

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"
import LuaRuntime "../../lua"

World :: struct {
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
    }

    if world.steps == 0 {
        world.steps = 4
    }
    world.is_active = true
}

Destroy :: proc () {
    if world.is_active {
        log.debugf("LakshmiBox2DWorld: Destroy\n")
        b2.DestroyWorld(world.id)
    }

    world.is_active = false
}

GetWorld :: proc () -> ^World {
    return &world
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
}

LuaUnbind :: proc(L: ^lua.State) {
    Destroy()
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
    step := lua.tonumber(L, 1)

    if world.is_active {
        b2.World_Step(world.id, f32(step), world.steps)
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
