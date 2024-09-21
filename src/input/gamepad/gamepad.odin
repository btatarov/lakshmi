package input_gamepad

import "core:fmt"
import "core:log"

import "vendor:glfw"
import lua "vendor:lua/5.4"

import LakshmiContext "../../base/context"

import LuaRuntime "../../lua"

@private callback_ref: i32 = lua.REFNIL

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "isPresent",      _isPresent },
        { "clearCallback",  _clearCallback },
        { "setCallback",    _setCallback },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiGamepad", &reg_table)

    // bind constants
    for name, _ in GAMEPAD_EVENT {
        lua.pushinteger(L, lua.Integer(GAMEPAD_EVENT(name)))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }
    for name, _ in GAMEPAD_MAP {
        lua.pushinteger(L, lua.Integer(GAMEPAD_MAP(name)))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }
    for name, _ in GAMEPAD_AXIS {
        lua.pushinteger(L, lua.Integer(GAMEPAD_AXIS(name)))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

Update :: proc() {
    if callback_ref != lua.REFNIL {

        state: glfw.GamepadState
        if glfw.GetGamepadState(glfw.JOYSTICK_1, &state) != 0 {
            L := LuaRuntime.GetState()

            lua.rawgeti(L, lua.REGISTRYINDEX, lua.Integer(callback_ref))

            lua.newtable(L)
            for i, v in state.buttons {
                lua.pushinteger(L, lua.Integer(v))
                lua.pushinteger(L, lua.Integer(i))
                lua.settable(L, -3)
            }

            lua.newtable(L)
            for i, v in state.axes {
                lua.pushinteger(L, lua.Integer(v))
                lua.pushnumber(L, lua.Number(i))
                lua.settable(L, -3)
            }

            status := lua.pcall(L, 2, 0, 0)
            if ! LuaRuntime.CheckOK(L, lua.Status(status)) {
                log.errorf("LakshmiGamepad: callback failed: %s\n", lua.tostring(L, -1))
                lua.pop(L, 1)
            }
        }
    }
}

_isPresent :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if glfw.JoystickPresent(glfw.JOYSTICK_1) && glfw.JoystickIsGamepad(glfw.JOYSTICK_1) {
        lua.pushboolean(L, true)
    } else {
        lua.pushboolean(L, false)
    }

    return 1
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
        log.errorf("LakshmiGamepad.setCallback: argument 1 is not a function\n")
        lua.pop(L, 1)
        return 0
    }

    callback_ref = lua.L_ref(L, lua.REGISTRYINDEX)

    return 0
}
