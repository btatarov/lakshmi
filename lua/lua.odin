package lua

import "core:strings"
import "core:fmt"

import lua "vendor:lua/5.4"

Init :: proc() -> (L: ^lua.State) {
    L = lua.L_newstate()
    lua.L_openlibs(L)
    return
}

BindSingleton :: proc(L: ^lua.State, name: cstring, reg_table: ^[]lua.L_Reg) {
    // TODO: const fields, e.g. LakshimiWindow.ON_CLOSE
    lua.newtable(L)
    lua.pushvalue(L, lua.gettop(L))
    lua.setglobal(L, name)
    lua.L_setfuncs(L, raw_data(reg_table[:]), 0)
}

CheckOK :: proc(L: ^lua.State, status: lua.Status) -> bool {
    if status != lua.OK {
        fmt.println(lua.tostring(L, -1))
        return false
    }
    return true
}

Destroy :: proc(L: ^lua.State) {
    lua.close(L)
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
