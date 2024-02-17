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

    read_file: proc(pkg: ^Package, file_path: string) -> []byte,
}

PackageErr :: enum {
    None,
    InvalidHeaderMagic,
    InvalidHeaderVersion,
    InvalidDataCRC32,
}

Init :: proc(path: string) -> (pkg: Package) {
    pkg.path = path
    pkg.data = make(map[string]Pkg.Chunk)

    pkg.read_file = package_read_file

    file, err := os.open(pkg.path, os.O_CREATE | os.O_RDONLY)
    assert(err == 0, fmt.tprintf("Pkg: Failed to open file: %s", pkg.path))

    base_pkg: Pkg.Package = {path = path}
    defer delete(base_pkg.toc)
    defer delete(base_pkg.data)

    os.read_ptr(file, &base_pkg.header, size_of(base_pkg.header))
    pkg.offset = size_of(base_pkg.header)

    // read toc
    for i in 0..<base_pkg.header.num_chunks {
        chunk: Pkg.Chunk
        name_buf: [Pkg.MAX_PATH_LEN]byte

        os.read_ptr(file, &chunk.name_len, size_of(u32))
        os.read_ptr(file, &name_buf, int(chunk.name_len))
        chunk.name = strings.clone(strings.string_from_ptr(&name_buf[0], int(chunk.name_len)), allocator=context.temp_allocator)

        os.read_ptr(file, &chunk.offset, size_of(u64))
        os.read_ptr(file, &chunk.size, size_of(u64))
        os.read_ptr(file, &chunk.orig_size, size_of(u64))

        pkg.offset += u64(size_of(chunk) - size_of(chunk.name) + chunk.name_len)

        pkg.data[chunk.name] = chunk
        append(&base_pkg.toc, chunk)
    }

    // read data
    data_buf := make([]byte, 1)
    defer delete(data_buf)
    for {
        bytes, err := os.read(file, data_buf)
        if bytes == 0 do break
        append(&base_pkg.data, data_buf[0])
    }

    verify_err := Pkg.Verify(&base_pkg)
    assert(verify_err == .None, fmt.tprintf("Pkg: Failed to verify package: %s", path))

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
