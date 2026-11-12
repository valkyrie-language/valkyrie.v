namespace std.adaptor.clr.io;

using std.io::{FileHandle, FileOpenMode, IoError, WriteFailure, io_invalid_input};
using std.types::{Result, Option, Some, None, Fine, Fail};

# std.adaptor.clr.io: `std.io` 字节流文件合同的 CLR lane 绑定。
#
# 合同映射（02 §4.3）：
# - 句柄载体：`FileHandle` 的 CLR 表示即 `System.IO.FileStream` 对象本身，
#   经 `[clr]` 绑定的 `FileHandle` 形参/返回直接流转，std 不读取内部字段。
# - 读：`System.IO.BinaryReader.ReadBytes(int)` 返回 `byte[]`，EOF 给空数组，
#   与 `Reader` 合同「空块即流尽」一致，不以 -1 或异常兼作终态。
# - 写：`FileStream.Write(byte[], int, int)` 要么整段吸收（进流内部缓冲或
#   落底）要么抛出；抛出是经宿主的 trap，异常→结构化 `Fail` 的绑定合同
#   尚未定案（02 §4.3 缺口③），本 provider 不伪造 Fail 分支，也不以保守
#   0 代报吸收量——正常返回即全部吸收。
# - 存在性/目录：`File.Exists`、`Directory.Exists` 为纯布尔；
#   `Directory.CreateDirectory` 幂等（已存在不抛）；
#   `Directory.GetFiles(path, pattern, SearchOption)` 承接 glob 模式与递归。

[host_provider(std::io::fs_open)]
micro fs_open(path: utf8, mode: FileOpenMode) -> Result<FileHandle, IoError> {
    if mode == FileOpenMode::Read {
        if !__file_exists(path) {
            return Fail { error: io_invalid_input() }
        }
    }
    return Fine(__fs_stream_open(path, file_mode_code(mode)))
}

[host_provider(std::io::fs_read)]
micro fs_read(handle: FileHandle, max: usize) -> Result<[u8], IoError> {
    let want: i32 = if max > 2147483647 { 2147483647 } else { max as i32 }
    let reader: any = __binary_reader_new(handle)
    return Fine(__binary_reader_read(reader, want))
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
    let data: [u8] = buffer.to_array()
    let mut written: usize = 0
    while written < count {
        let remaining: usize = count - written
        let take: i32 = if remaining > 2147483647 { 2147483647 } else { remaining as i32 }
        __fs_stream_write(handle, data, written as i32, take)
        written = written + take as usize
    }
    return Fine(written)
}

[host_provider(std::io::fs_flush)]
micro fs_flush(handle: FileHandle) -> Option<IoError> {
    __fs_stream_flush(handle)
    return None
}

[host_provider(std::io::fs_close)]
micro fs_close(handle: FileHandle) -> Option<IoError> {
    __fs_stream_close(handle)
    return None
}

[host_provider(std::io::fs_file_exists)]
micro fs_file_exists(path: utf8) -> bool {
    return __file_exists(path)
}

[host_provider(std::io::fs_directory_exists)]
micro fs_directory_exists(path: utf8) -> bool {
    return __directory_exists(path)
}

[host_provider(std::io::fs_create_directory)]
micro fs_create_directory(path: utf8) -> Option<IoError> {
    __create_directory(path)
    return None
}

[host_provider(std::io::fs_current_directory)]
micro fs_current_directory() -> Result<utf8, IoError> {
    return Fine(__get_current_directory())
}

[host_provider(std::io::fs_list_directory)]
micro fs_list_directory(path: utf8, pattern: utf8, recursive: bool) -> Result<[utf8], IoError> {
    let search_option: i32 = if recursive { i32(1) } else { i32(0) }
    return Fine(__get_files(path, pattern, search_option))
}

# `FileMode` 数值：CreateNew=1、Create=2、Open=3、OpenOrCreate=4、Truncate=5、
# Append=6。合同语义映射：`Read`→Open（存在性已在入口预检）、
# `Write`→Create（截断既有内容并在缺失时创建）、`Append`→Append、
# `ReadWrite`→OpenOrCreate（双向、不截断）。
private micro file_mode_code(mode: FileOpenMode) -> i32 {
    match mode {
        case Read:
            return 3
        case Write:
            return 2
        case Append:
            return 6
        case ReadWrite:
            return 4
    }
}

[clr("System.IO.FileSystem", "System.IO.FileStream", ".ctor")]
private micro __fs_stream_open(path: utf8, mode: i32): FileHandle { }

[clr("System.Runtime", "System.IO.BinaryReader", ".ctor")]
private micro __binary_reader_new(stream: FileHandle): any { }

[clr("System.Runtime", "System.IO.BinaryReader", "ReadBytes")]
private micro __binary_reader_read(reader: any, count: i32): [u8] { }

[clr("System.IO.FileSystem", "System.IO.FileStream", "Write")]
private micro __fs_stream_write(stream: FileHandle, buffer: [u8], offset: i32, count: i32): unit { }

[clr("System.IO.FileSystem", "System.IO.FileStream", "Flush")]
private micro __fs_stream_flush(stream: FileHandle): unit { }

[clr("System.IO.FileSystem", "System.IO.FileStream", "Close")]
private micro __fs_stream_close(stream: FileHandle): unit { }

[clr("System.IO.FileSystem", "System.IO.File", "Exists")]
private micro __file_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "Exists")]
private micro __directory_exists(path: utf8): bool

[clr("System.IO.FileSystem", "System.IO.Directory", "CreateDirectory")]
private micro __create_directory(path: utf8): any

[clr("System.IO.FileSystem", "System.IO.Directory", "GetCurrentDirectory")]
private micro __get_current_directory(): utf8

[clr("System.IO.FileSystem", "System.IO.Directory", "GetFiles")]
private micro __get_files(path: utf8, pattern: utf8, search_option: i32): [utf8]
