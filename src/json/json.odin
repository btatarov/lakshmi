package json_parser

import "base:runtime"

import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:strings"

import lua "vendor:lua/5.4"

import LuaRuntime "../lua"

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "decode", _decode },
        { "encode", _encode },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiJSON", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    // UNUSED
}

JsonToLua :: proc(L: ^lua.State, json_data: json.Value) {
    switch _ in json_data {
        case json.Object:
            lua.newtable(L)
            for key, value in json_data.(json.Object) {
                JsonToLua(L, value)
                lua.setfield(L, -2, strings.clone_to_cstring(key, context.temp_allocator))
            }

        case json.Array:
            lua.newtable(L)
            for value, idx in json_data.(json.Array) {
                lua.pushnumber(L, (lua.Number)(idx + 1))
                JsonToLua(L, value)
                lua.settable(L, -3)
            }

        case json.String:
            lua.pushstring(L, cstring(strings.clone_to_cstring(json_data.(json.String), context.temp_allocator)))

        case json.Integer:
            lua.pushnumber(L, (lua.Number)(json_data.(json.Integer)))

        case json.Float:
            lua.pushnumber(L, (lua.Number)(json_data.(json.Float)))

        case json.Boolean:
            lua.pushboolean(L, b32(json_data.(json.Boolean)))

        case json.Null:
            lua.pushlightuserdata(L, nil)
    }
}

LuaToJson :: proc(L: ^lua.State, idx: i32) -> json.Value {
    #partial switch lua.type(L, idx) {
        case lua.TTABLE:
            if lua.L_len(L, idx) > 0 {
                arr: json.Array
                key: i32 = 1
                for {
                    LuaRuntime.GetField(L, idx, key)
                    value := LuaToJson(L, -1)
                    lua.pop(L, 1)
                    if value != nil {
                        append(&arr, value)
                    }
                    else {
                        break
                    }
                    key += 1
                }
                return arr
            } else {
                object := json.Object{}
                itr := LuaRuntime.PushTableItr(L, idx)
                for {
                    if ! LuaRuntime.TableItrNext(L, itr) {
                        break
                    }
                    if lua.type(L, -2) != lua.TSTRING {
                        continue
                    }
                    key := lua.tostring(L, -2)
                    value := LuaToJson(L, -1)
                    if value != nil {
                        object[string(key)] = value
                    }
                }
                return object
            }

		case lua.TBOOLEAN:
			return bool(lua.toboolean(L, idx))

		case lua.TSTRING:
			return string(lua.tostring(L, idx))

		case lua.TNUMBER:
			num := f64(lua.tonumber(L, idx))
            int_part, frac_part := math.modf(num)
			if frac_part == 0.0 {
				return i64(int_part)
			} else{
				return f64(num)
			}
	}
    return nil
}

_decode :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    json_str := lua.L_checkstring(L, 1)
    json_data, err := json.parse_string(string(json_str), parse_integers=true)
    assert(err == .None , "LakshmiJSON: JSON decode error.")

    JsonToLua(L, json_data)
    return 1
}

_encode :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()

    assert(lua.istable(L, 1), "LakshmiJSON: First argument must be a table.")

    json_data := LuaToJson(L, 1)
    json_str, err := json.marshal(json_data)
    assert(err == json.Marshal_Data_Error.None, fmt.tprintf("LakshmiJSON: JSON encode error. %v", err))

    lua.pushstring(L, strings.clone_to_cstring(string(json_str), context.temp_allocator))
    return 1
}
