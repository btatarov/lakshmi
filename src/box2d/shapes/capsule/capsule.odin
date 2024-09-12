package box2d_capsule

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import Box2DEntity "../../entity"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Init :: proc(primitive: ^Box2DEntity.Primitive, r, x1, y1, x2, y2: f32) {
    log.debugf("LakshmiBox2DCapsule: Init\n")

    capsule: b2.Capsule
    capsule.radius = r
    capsule.center1 = { x1, y1 }
    capsule.center2 = { x2, y2 }

    primitive.data = capsule
    primitive.type = .Capsule
}

Destroy :: proc(primitive: ^Box2DEntity.Primitive) {
    log.debugf("LakshmiBox2DCapsule: Destroy\n")
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _init },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DCapsule", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.newuserdata(L, size_of(Box2DEntity.Primitive)))
    radius := lua.tonumber(L, 1)
    x1 := lua.tonumber(L, 2)
    y1 := lua.tonumber(L, 3)
    x2 := lua.tonumber(L, 4)
    y2 := lua.tonumber(L, 5)

    Init(primitive, f32(radius), f32(x1), f32(y1), f32(x2), f32(y2))

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DCapsule")

    return 1
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.touserdata(L, 1))
    Destroy(primitive)

    return 0
}
