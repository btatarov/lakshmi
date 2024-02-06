package pkg_reader

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strings"

import Pkg ".."

Package :: struct {
    data:   map[string]Pkg.Chunk,
    path:   string,
    offset: u64,

    read_file : proc(pkg: ^Package, file_path: string) -> []byte,
}

Init :: proc(path: string) -> (pkg: Package) {
    pkg.path = path
    pkg.data = make(map[string]Pkg.Chunk)

    pkg.read_file = package_read_file

    data, ok := os.read_entire_file_from_filename(path)
    assert(ok, fmt.tprintf("Pkg: Failed to read file: %s", path))

    // TODO: this duplicates the memory
    buf: bytes.Buffer
    bytes.buffer_init(&buf, data)
    delete(data)
    defer bytes.buffer_destroy(&buf)

    base_pkg: Pkg.Package = {path = path}
    defer delete(base_pkg.toc)

    _, err := bytes.buffer_read_ptr(&buf, &base_pkg.header, size_of(base_pkg.header))
    assert(err == .None, fmt.tprintf("Pkg: Failed to read header from file: %s", path))
    pkg.offset = size_of(base_pkg.header)

    for i in 0..<base_pkg.header.num_chunks {
        chunk: Pkg.Chunk
        name_buf: [Pkg.MAX_PATH_LEN]byte

        bytes.buffer_read_ptr(&buf, &chunk.name_len, size_of(u32))
        bytes.buffer_read_ptr(&buf, &name_buf, int(chunk.name_len))
        chunk.name = strings.clone(strings.string_from_ptr(&name_buf[0], int(chunk.name_len)), allocator=context.temp_allocator)

        bytes.buffer_read_ptr(&buf, &chunk.offset, size_of(u64))
        bytes.buffer_read_ptr(&buf, &chunk.size, size_of(u64))
        bytes.buffer_read_ptr(&buf, &chunk.orig_size, size_of(u64))

        pkg.offset += u64(size_of(chunk) - size_of(chunk.name) + chunk.name_len)

        pkg.data[chunk.name] = chunk
        append(&base_pkg.toc, chunk)
    }

    // TODO: verify base_pkg
    return
}

Destroy :: proc(pkg: ^Package) {
    delete(pkg.data)
}

package_read_file :: proc(pkg: ^Package, file_path: string) -> []byte {
    chunk, ok := pkg.data[file_path]
    assert(ok, fmt.tprintf("Pkg: Failed to find file: %s", file_path))

    file, err := os.open(pkg.path, os.O_CREATE | os.O_RDONLY)
    assert(err == 0, fmt.tprintf("Pkg: Failed to open file: %s", pkg.path))
    defer os.close(file)

    buf := make([]byte, chunk.size)
    defer delete(buf)

    os.seek(file, i64(pkg.offset + chunk.offset), os.SEEK_SET)
    os.read(file, buf)

    uncompressed_data: string
    uncompressed_data, ok = Pkg.Uncompress(&buf[0], chunk.size, chunk.orig_size)
    assert(ok, fmt.tprintf("Pkg: Failed to uncompress data for file: %s", file_path))

    return transmute([]byte)uncompressed_data
}
