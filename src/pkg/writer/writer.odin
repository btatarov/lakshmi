package pkg_writer

import "core:fmt"
import "core:os"

import Pkg ".."

Init :: proc(path: string) -> (pkg: Pkg.Package) {
    pkg.path = path
    pkg.data_size = 0

    pkg.header.magic = Pkg.HEADER_MAGIC
    pkg.header.version = Pkg.HEADER_VERSION
    pkg.header.params = 0
    pkg.header.crc32 = 0

    return
}

Destroy :: proc(pkg: ^Pkg.Package) {
    delete(pkg.toc)
    delete(pkg.data)
}

AddFile :: proc(pkg: ^Pkg.Package, name: string, data: [^]byte, size: u64) {
    assert(len(name) < Pkg.MAX_PATH_LEN, fmt.tprintf("Pkg: File name too long: %s. Max size is: %d", name, Pkg.MAX_PATH_LEN))

    chunk := Pkg.Chunk {
        name_len    = u32(len(name)),
        name        = name,
        offset      = pkg.data_size,
        orig_size   = size,
    }

    compressed_data, ok := Pkg.Compress(data, size)
    assert(ok, fmt.tprintf("Pkg: Failed to compress data for file: %s", name))

    for i in 0..<len(compressed_data) {
        append(&pkg.data, compressed_data[i])
    }

    chunk.size = u64(len(compressed_data))
    append(&pkg.toc, chunk)

    pkg.header.num_chunks += 1
    pkg.data_size += chunk.size
}

Write :: proc(pkg: ^Pkg.Package) -> bool {
    file, err := os.open(pkg.path, os.O_CREATE | os.O_RDWR, 0o644)
    assert(err == 0, fmt.tprintf("Pkg: Failed to open file: %s", pkg.path))
    defer os.close(file)

    os.write_ptr(file, &pkg.header, size_of(pkg.header))
    for chunk in &pkg.toc {
        os.write_ptr(file, &chunk.name_len, size_of(chunk.name_len))
        os.write(file, transmute([]byte)chunk.name)
        os.write_ptr(file, &chunk.offset, size_of(chunk.offset))
        os.write_ptr(file, &chunk.size, size_of(chunk.size))
        os.write_ptr(file, &chunk.orig_size, size_of(chunk.orig_size))
    }
    os.write(file, pkg.data[:])

    crc32 := Pkg.CRC32(pkg)
    os.seek(file, Pkg.HEADER_CRC32_POS, os.SEEK_SET)
    os.write_ptr(file, &crc32, size_of(crc32))

    return true
}
