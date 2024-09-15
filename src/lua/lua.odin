package lua

import "core:fmt"
import "core:log"
import "core:strings"

import lua "vendor:lua/5.4"

@private LuaState: ^lua.State

Init :: proc() {
    LuaState = lua.L_newstate()
    lua.L_openlibs(LuaState)
}

BindClass :: proc { BindClassSimple, BindClassWithConstants }

BindClassSimple :: proc(L: ^lua.State, name: cstring, reg_table: ^[]lua.L_Reg, destructor: proc "c" (L: ^lua.State) -> i32) {
    lua.newtable(L)
    index := lua.gettop(L)

    lua.pushvalue(L, index)
    lua.setglobal(L, name)
    lua.L_setfuncs(L, raw_data(reg_table[:]), 0)

    lua.L_newmetatable(L, fmt.ctprintf("%sMT", name))

    lua.pushstring(L, "__gc")
    lua.pushcfunction(L, lua.CFunction(destructor))
    lua.settable(L, -3)

    lua.pushstring(L, "__index")
    lua.pushvalue(L, index)
    lua.settable(L, -3)
}

BindClassWithConstants :: proc(L: ^lua.State, name: cstring, reg_table: ^[]lua.L_Reg, constants: ^map[string]u32, destructor: proc "c" (L: ^lua.State) -> i32) {
    lua.newtable(L)
    index := lua.gettop(L)

    lua.pushvalue(L, index)
    lua.setglobal(L, name)
    lua.L_setfuncs(L, raw_data(reg_table[:]), 0)

    for name, _ in constants {
        lua.pushinteger(L, lua.Integer(constants[name]))
        lua.setfield(L, -2, fmt.ctprintf("%s", name))
    }

    lua.L_newmetatable(L, fmt.ctprintf("%sMT", name))

    lua.pushstring(L, "__gc")
    lua.pushcfunction(L, lua.CFunction(destructor))
    lua.settable(L, -3)

    lua.pushstring(L, "__index")
    lua.pushvalue(L, index)
    lua.settable(L, -3)
}

BindClassMetatable :: proc(L: ^lua.State, name: cstring) {
    index := lua.gettop(L)
    lua.L_getmetatable(L, fmt.ctprintf("%sMT", name))
    assert(lua.istable(L, -1), fmt.tprintf("%sMT is not a table", name))
    lua.setmetatable(L, index)
}

BindSingleton :: proc(L: ^lua.State, name: cstring, reg_table: ^[]lua.L_Reg) {
    lua.newtable(L)
    lua.pushvalue(L, lua.gettop(L))
    lua.setglobal(L, name)
    lua.L_setfuncs(L, raw_data(reg_table[:]), 0)
}

CheckOK :: proc(L: ^lua.State, status: lua.Status) -> bool {
    if status != lua.OK {
        log.errorf("%s\n", lua.tostring(L, -1))
        return false
    }
    return true
}

Destroy :: proc(L: ^lua.State) {
    lua.close(L)
}

GetState :: proc() -> ^lua.State {
    return LuaState
}

Run :: proc(L: ^lua.State, args: []string) -> bool {
    if len(args) < 1 {
        CheckOK(L, lua.L_loadfile(L, "main.lua")) or_return
    } else {
        c_file := strings.clone_to_cstring(args[0], context.temp_allocator)
        CheckOK(L, lua.L_loadfile(L, c_file)) or_return
    }

    status := lua.pcall(L, 0, 0, 0)
    CheckOK(L, lua.Status(status)) or_return

    return true
}

GetField :: proc(L: ^lua.State, idx, key: i32) {
    abs_idx := GetAbsIndex(L, idx)
	lua.pushinteger(L, lua.Integer(key))
	lua.gettable(L, abs_idx)
}

GetAbsIndex :: proc(L: ^lua.State, idx: i32) -> i32 {
    if idx < 0 {
        return lua.gettop(L) + idx + 1
    }
    return idx
}

PushTableItr :: proc(L: ^lua.State, idx: i32) -> i32 {
    itr := GetAbsIndex(L, idx)
	lua.pushnil(L)
	lua.pushnil(L)
	lua.pushnil(L)
	return itr
}

TableItrNext :: proc(L: ^lua.State, itr: i32) -> bool {
    lua.pop(L, 2)  // pop the prev key/value; leave the key
    if lua.next(L, itr) != 0 {
		CopyToTop(L, -2)
		MoveToTop(L, -2)
		return true
	}
	return false
}

CopyToTop :: proc(L: ^lua.State, idx: i32) {
    lua.pushvalue(L, idx)
}

MoveToTop :: proc(L: ^lua.State, idx: i32) {
    abs_idx := GetAbsIndex(L, idx)
    lua.pushvalue(L, abs_idx)
	lua.remove(L, abs_idx)
}
