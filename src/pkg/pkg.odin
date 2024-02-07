package pkg

import "core:fmt"
import "core:hash"
import "core:os"
import "core:strings"

import "vendor:zlib"

HEADER_MAGIC :: "LPKG"
HEADER_VERSION :: 1
HEADER_CRC32_POS :: 12
HEADER_SIZE :: 20
MAX_PATH_LEN :: 1024

PackageErr :: enum {
    None,
    InvalidHeaderMagic,
    InvalidHeaderVersion,
    InvalidDataCRC32,
}

Header :: struct #packed {
    magic:      [4]byte,
    version:    u32,
    params:     u32,
    crc32:      u32,
    num_chunks: u32,
}
#assert(size_of(Header) == HEADER_SIZE, "Pkg: Header size mismatch")

Chunk :: struct #packed {
    name_len:   u32,
    name:       string,
    offset:     u64,
    size:       u64,
    orig_size:  u64,
}

Package :: struct {
    path: string,
    header: Header,
    toc: [dynamic]Chunk,
    data: [dynamic]byte,
    data_size: u64,
}

CRC32 :: proc(pkg: ^Package) -> (crc32: u32) {
    return hash.crc32(pkg.data[:])
}

Compress :: proc(input: [^]byte, len: u64) -> (string, bool) {
    buf: [dynamic]byte
    bound := zlib.compressBound(len)
    resize(&buf, int(bound))
    defer delete(buf)

    if err := zlib.compress(raw_data(buf), &bound, input, len); err != 0 {
        // TODO: error log
        return "", false
    }

    return strings.clone_from_bytes(buf[:bound], allocator=context.temp_allocator), true
}

Uncompress :: proc(input: [^]byte, len: u64, original_len: u64) -> (string, bool) {
    original_len := original_len
    buf: [dynamic]byte
    resize(&buf, int(original_len))
    defer delete(buf)

    if err := zlib.uncompress(raw_data(buf), &original_len, input, len); err != 0 {
        // TODO: error log
        return "", false
    }

    return strings.clone_from_bytes(buf[:original_len], allocator=context.temp_allocator), true
}

Verify :: proc(pkg: ^Package) -> (err: PackageErr) {
    fmt.println(pkg.header.crc32, CRC32(pkg), len(pkg.data))
    if pkg.header.magic != HEADER_MAGIC do return .InvalidHeaderMagic
    if pkg.header.version > HEADER_VERSION do return .InvalidHeaderVersion
    if pkg.header.crc32 != CRC32(pkg) do return .InvalidDataCRC32
    return .None
}
