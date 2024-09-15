package input_keyboard

import "core:fmt"
import "core:log"

import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"

import LuaRuntime "../../lua"

@private callback_ref: i32 = lua.REFNIL

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "clearCallback",  _clearCallback },
        { "setCallback",    _setCallback },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiKeyboard", &reg_table)

    // bind constants
    for name, _ in KEYBOARD_EVENT {
        lua.pushinteger(L, lua.Integer(KEYBOARD_EVENT(name)))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }
    for name, _ in KEYBOARD_MAP {
        lua.pushinteger(L, lua.Integer(KEYBOARD_MAP(name)))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

LuaHandleCallback :: proc(key, action: i32) {
    if callback_ref == lua.REFNIL {
        return
    }

    L := LuaRuntime.GetState()

    lua.rawgeti(L, lua.REGISTRYINDEX, lua.Integer(callback_ref))
    lua.pushinteger(L, lua.Integer(key))
    lua.pushinteger(L, lua.Integer(action))

    status := lua.pcall(L, 2, 0, 0)
    if ! LuaRuntime.CheckOK(L, lua.Status(status)) {
        log.errorf("LakshmiKeyboard: callback failed: %s\n", lua.tostring(L, -1))
        lua.pop(L, 1)
    }
}

_clearCallback :: proc "c" (L: ^lua.State) -> i32 {
    if callback_ref != lua.REFNIL {
        lua.L_unref(L, lua.REGISTRYINDEX, callback_ref)
        callback_ref = lua.REFNIL
    }

    return 0
}

_setCallback :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if ! lua.isfunction(L, 1) {
        log.errorf("LakshmiKeyboard.setCallback: argument 1 is not a function\n")
        lua.pop(L, 1)
        return 0
    }

    callback_ref = lua.L_ref(L, lua.REGISTRYINDEX)

    return 0
}
