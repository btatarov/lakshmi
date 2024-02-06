package main

import "core:fmt"
import "core:mem"

import Pkg "../../src/pkg"
import PkgReader "../../src/pkg/reader"
import PkgWriter "../../src/pkg/writer"

main :: proc() {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer if len(tracking_allocator.allocation_map) > 0 || len(tracking_allocator.bad_free_array) > 0 {
        fmt.println()
        for _, leak in tracking_allocator.allocation_map {
            fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
        }
        for bad_free in tracking_allocator.bad_free_array {
            fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
        }
    }

    write_pkg := PkgWriter.Init("test.lpkg")
    defer PkgWriter.Destroy(&write_pkg)

    test_in_1 := "Hello, 世界!"
    test_in_2 := "12345678901234567890123456789012345678901234567890"
    PkgWriter.AddFile(&write_pkg, "test1.txt", raw_data(test_in_1), u64(len(test_in_1)))
    PkgWriter.AddFile(&write_pkg, "test2.txt", raw_data(test_in_2), u64(len(test_in_2)))
    PkgWriter.Write(&write_pkg)

    read_pkg := PkgReader.Init("test.lpkg")
    defer PkgReader.Destroy(&read_pkg)

    test_out_1 := string(read_pkg->read_file("test1.txt"))
    test_out_2 := string(read_pkg->read_file("test2.txt"))

    assert(test_out_1 == test_in_1, "Test 1 failed")
    assert(test_out_2 == test_in_2, "Test 2 failed")
}
