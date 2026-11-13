namespace std.adaptor.clr.fs;

# CLR lane 的 `std.fs` 字节合同绑定：System.IO.File 的字节面。
# 文本编码不经过本文件；字节进出宿主不做转码。

[host_provider(std::fs::exists)]
micro exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider(std::fs::read_bytes)]
micro read_bytes(path: utf8) -> [u8] {
    return __read_all_bytes(path)
}

[host_provider(std::fs::write_bytes)]
micro write_bytes(path: utf8, bytes: [u8]) -> bool {
    __write_all_bytes(path, bytes)
    return true
}

[clr("System.IO.FileSystem", "System.IO.File", "Exists")]
private micro __file_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.File", "ReadAllBytes")]
private micro __read_all_bytes(path: utf8): [u8]

[clr("System.IO.FileSystem", "System.IO.File", "WriteAllBytes")]
private micro __write_all_bytes(path: utf8, bytes: [u8]): unit
