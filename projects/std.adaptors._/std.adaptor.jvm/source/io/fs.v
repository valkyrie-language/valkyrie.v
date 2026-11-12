namespace std.adaptor.jvm.io;

using std.io::{FileHandle, FileOpenMode, IoError, WriteFailure, io_invalid_input, io_failed};
using std.types::{Result, Option, Some, None, Fine, Fail};

# std.adaptor.jvm.io: `std.io` 字节流文件合同的 JVM lane 绑定。
#
# 合同映射（02 §4.3）：
# - 句柄载体：`FileHandle` 的 JVM 表示即 `java.io.RandomAccessFile` 对象，
#   经 `[jvm]` 绑定的 `FileHandle` 形参/返回直接流转。
# - 打开模式：`Read`→"r"（缺失即 `FileNotFoundException`，入口以
#   `File.exists` 预检并结构化拒绝）；`Write`→"rw" + `setLength(0)`（截断
#   并创建）；`Append`→"rw" + `seek(length())`；`ReadWrite`→"rw"。
# - 读：`RandomAccessFile.read()` 单字节返回，-1 即流尽——逐字节收集到
#   `max` 或流尽；不跨边界传可变 `byte[]` 缓冲（吸收语义只在写出方向）。
# - 写：`RandomAccessFile.write(byte[])` 要么整段吸收要么抛出；抛出是经
#   宿主的 trap，异常→结构化 `Fail` 的绑定合同未定案（02 §4.3 缺口③），
#   本 provider 不伪造 Fail 分支，也不以保守 0 代报吸收量。
# - `File.mkdirs` 以布尔返回失败（不抛），吸收为结构化 `Some(IoError)`。
# - `fs_list_directory` 不绑定：glob 模式语义未定案，JVM 侧显式缺能力，
#   由 provider 选择阶段失败，不以空目录伪装枚举成功。

[host_provider(std::io::fs_open)]
micro fs_open(path: utf8, mode: FileOpenMode) -> Result<FileHandle, IoError> {
    if mode == FileOpenMode::Read {
        if !__file_exists(path) {
            return Fail { error: io_invalid_input() }
        }
    }
    let handle: FileHandle = __raf_new(path, raf_mode_string(mode))
    if mode == FileOpenMode::Write {
        __raf_set_length(handle, 0)
        __raf_seek(handle, 0)
    }
    if mode == FileOpenMode::Append {
        __raf_seek(handle, __raf_length(handle))
    }
    return Fine(handle)
}

[host_provider(std::io::fs_read)]
micro fs_read(handle: FileHandle, max: usize) -> Result<[u8], IoError> {
    let mut collected: ArrayList<u8> = ArrayList::new(0)
    let mut taken: usize = 0
    while taken < max {
        let byte: i32 = __raf_read_byte(handle)
        if byte < 0 {
            break
        }
        collected.push(byte as u8)
        taken = taken + 1
    }
    return Fine(collected.to_array())
}

[host_provider(std::io::fs_write)]
micro fs_write(handle: FileHandle, bytes: ArrayView<u8>) -> Result<usize, WriteFailure> {
    let count: usize = bytes.length
    let mut buffer: ArrayList<u8> = ArrayList::new(count)
    let mut index: usize = 0
    while index < count {
        buffer.push(bytes⁅index⁆)
        index = index + 1
    }
    __raf_write_bytes(handle, buffer.to_array())
    return Fine(count)
}

# `RandomAccessFile` 无内部缓冲：写出即落底，`flush` 恒为成功（合同事实，
# 02 §4.3——零滞留由该 JVM 原语保证并在此写明）。
[host_provider(std::io::fs_flush)]
micro fs_flush(handle: FileHandle) -> Option<IoError> {
    return None
}

[host_provider(std::io::fs_close)]
micro fs_close(handle: FileHandle) -> Option<IoError> {
    __raf_close(handle)
    return None
}

[host_provider(std::io::fs_file_exists)]
micro fs_file_exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider(std::io::fs_directory_exists)]
micro fs_directory_exists(path: utf8) -> bool {
    return __is_directory(path)
}

[host_provider(std::io::fs_create_directory)]
micro fs_create_directory(path: utf8) -> Option<IoError> {
    if __mkdirs(path) {
        return None
    }
    return Some(io_failed())
}

[host_provider(std::io::fs_current_directory)]
micro fs_current_directory() -> Result<utf8, IoError> {
    return Fine(__system_get_property("user.dir"))
}

# `RandomAccessFile` 访问模式串："r" 只读（要求存在）、"rw" 读写（缺失创建）。
micro raf_mode_string(mode: FileOpenMode) -> utf8 {
    match mode {
        case Read:
            return "r"
        case Write:
            return "rw"
        case Append:
            return "rw"
        case ReadWrite:
            return "rw"
    }
}

[jvm("java.io.RandomAccessFile", "<init>")]
private micro __raf_new(path: utf8, mode: utf8): FileHandle { }

[jvm("java.io.RandomAccessFile", "read")]
private micro __raf_read_byte(handle: FileHandle): i32 { }

[jvm("java.io.RandomAccessFile", "write")]
private micro __raf_write_bytes(handle: FileHandle, bytes: [u8]): unit { }

[jvm("java.io.RandomAccessFile", "setLength")]
private micro __raf_set_length(handle: FileHandle, length: i64): unit { }

[jvm("java.io.RandomAccessFile", "seek")]
private micro __raf_seek(handle: FileHandle, pos: i64): unit { }

[jvm("java.io.RandomAccessFile", "length"), pure]
private micro __raf_length(handle: FileHandle): i64 { }

[jvm("java.io.RandomAccessFile", "close")]
private micro __raf_close(handle: FileHandle): unit { }

[jvm("java.io.File", "exists")]
private micro __file_exists(path: utf8): bool

[jvm("java.io.File", "mkdirs")]
private micro __mkdirs(path: utf8): bool

[jvm("java.io.File", "isDirectory")]
private micro __is_directory(path: utf8): bool

[jvm("java.lang.System", "getProperty")]
private micro __system_get_property(key: utf8): utf8
