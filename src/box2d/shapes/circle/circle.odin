package box2d_circle

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import Box2DEntity "../../entity"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Init :: proc(primitive: ^Box2DEntity.Primitive, radius: f32) {
    log.debugf("LakshmiBox2DCircle: Init\n")

    circle: b2.Circle
    circle.radius = radius

    primitive.data = circle
    primitive.type = .Circle
}

Destroy :: proc(primitive: ^Box2DEntity.Primitive) {
    log.debugf("LakshmiBox2DCircle: Destroy\n")
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _init },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DCircle", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.newuserdata(L, size_of(Box2DEntity.Primitive)))
    radius := lua.tonumber(L, 1)

    Init(primitive, f32(radius))

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DCircle")

    return 1
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.touserdata(L, 1))
    Destroy(primitive)

    return 0
}
