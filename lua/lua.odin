package lua

import "core:strings"
import "core:fmt"

import lua "vendor:lua/5.4"

L : ^lua.State

Init :: proc() {
    L = lua.L_newstate()
    lua.L_openlibs(L)
}

CheckOK :: proc(status: lua.Status) -> bool {
    if status != lua.OK {
        fmt.println("Error: ", status)
        fmt.println(lua.tostring(L, -1))
        return false
    }
    return true
}

Destroy :: proc() {
    lua.close(L)
}

Run :: proc(args: []string) -> bool {
    if len(args) < 1 {
        CheckOK(lua.L_loadfile(L, "main.lua")) or_return
    } else {
        CheckOK(lua.L_loadfile(L, strings.clone_to_cstring(args[0]))) or_return
    }

    status := lua.pcall(L, 0, 0, 0)
    CheckOK(lua.Status(status)) or_return

    return true
}

