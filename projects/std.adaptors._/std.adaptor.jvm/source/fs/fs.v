namespace std.adaptor.jvm.fs;

# JVM lane 的 `std.fs` 字节合同绑定：java.nio.file.Files 的字节面。
# 路径句柄经 `Path::of` 物化为 `any`，字节进出宿主不做转码。

[host_provider(std::fs::exists)]
micro exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider(std::fs::read_bytes)]
micro read_bytes(path: utf8) -> [u8] {
    let handle: any = __path_of(path)
    return __files_read_all_bytes(handle)
}

[host_provider(std::fs::write_bytes)]
micro write_bytes(path: utf8, bytes: [u8]) -> bool {
    let handle: any = __path_of(path)
    __files_write_all_bytes(handle, bytes)
    return true
}

# `java.io.File::exists` 直接吃 String 路径，无需 Path 句柄。
[jvm("java.io.File", "exists")]
private micro __file_exists(path: utf8): bool

[jvm("java.nio.file.Path", "of")]
private micro __path_of(path: utf8): any

[jvm("java.nio.file.Files", "readAllBytes", "(Ljava/nio/file/Path;)[B")]
private micro __files_read_all_bytes(path_handle: any): [u8]

[jvm("java.nio.file.Files", "writeAllBytes", "(Ljava/nio/file/Path;[B)Ljava/nio/file/Path;")]
private micro __files_write_all_bytes(path_handle: any, bytes: [u8]): any
