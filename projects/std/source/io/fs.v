namespace std.io;

using std.types::{Result, Option, Some, None, Fine, Fail};
using std.collection::{array_view};
using std.text::{Utf8Text};

# std.io: 文件系统字节流资源。
#
# 分层合同：
# - 文件与 TCP 同属 `std.io` 字节流体系：`File` 实现 `Reader` 与 `Writer`，
#   承载的是字节，不是文本；文本编解码是显式的桥接层，不混进资源语义。
# - 终态三分且互不混同：流尽（`Reader.read` 返回空块）、已关闭
#   （`Fail(Closed)`，对已释放资源的调用）、底层错误（`Fail(Failed)` 等种类）。
#   不存在以空串、`-1`、`false` 兼作失败哨兵的入口。
# - 资源所有权显式：`open_file` 是唯一取得 `File` 的入口，`File` 移动语义持有
#   句柄；`close` 释放并幂等；句柄一经关闭，读写一律 `Closed`，不再触底。
# - 平台描述符的形态与解释完全归 adaptor：`FileHandle` 对 std 不透明，
#   std 不读取、不比较、不以特定值作哨兵。
# - 失败经 `IoError` 结构化返回；控制流不经 panic。

# 打开模式：`Write` 截断既有内容并在缺失时创建；`Append` 保留既有内容、
# 写入落在末尾；`Read` 要求路径存在；`ReadWrite` 允许双向。
enums FileOpenMode {
    Read
    Write
    Append
    ReadWrite
}

# 不透明文件句柄：宿主侧描述符的载体，std 只保存与移交。
structure FileHandle {
    _host: any
}

structure File {
    _handle: FileHandle
    _open: bool
}

# ── 宿主合同（adaptor 绑定；缺绑定的目标计划阶段结构化失败，无内建兜底）──

# 句柄载体构造入口：仅供 adaptor provider 把宿主描述符装入不透明句柄；
# 作者面不经手宿主 `any`，std 不读取、不比较、不以特定值作哨兵。
micro file_handle(host: any) -> FileHandle {
    return FileHandle { _host: host }
}

[host_contract]
micro fs_open(path: utf8, mode: FileOpenMode) -> Result<FileHandle, IoError>

[host_contract]
micro fs_read(handle: FileHandle, max: usize) -> Result<[u8], IoError>

# 写合同失败携带真实吸收前缀：`WriteFailure.absorbed` 是宿主本轮实际
# 吸收（落底或进宿主内部缓冲）的字节数；`absorbed: 0` 只允许是宿主
# 确认的零吸收事实，std 不以保守 0 代报未知（02 §4.3）。
[host_contract]
micro fs_write(handle: FileHandle, bytes: ArrayView<u8>) -> Result<usize, WriteFailure>

[host_contract]
micro fs_flush(handle: FileHandle) -> Option<IoError>

[host_contract]
micro fs_close(handle: FileHandle) -> Option<IoError>

[host_contract]
micro fs_file_exists(path: utf8) -> bool

[host_contract]
micro fs_directory_exists(path: utf8) -> bool

[host_contract]
micro fs_create_directory(path: utf8) -> Option<IoError>

[host_contract]
micro fs_current_directory() -> Result<utf8, IoError>

[host_contract]
micro fs_list_directory(path: utf8, pattern: utf8, recursive: bool) -> Result<[utf8], IoError>

# ── 资源入口 ──────────────────────────────────────────────────────────

micro open_file(path: utf8, mode: FileOpenMode) -> Result<File, IoError> {
    let opened: Result<FileHandle, IoError> = fs_open(path, mode)
    match opened {
        case Fine(handle):
            return Fine { value: File { _handle: handle, _open: true } }
        case Fail(error):
            return Fail { error: error }
    }
}

imply File: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if !self._open {
            return Fail { error: io_closed() }
        }
        return fs_read(self._handle, max)
    }
}

imply File: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, WriteFailure> {
        if !self._open {
            return Fail { error: WriteFailure { absorbed: 0, error: io_closed() } }
        }
        # 宿主合同直接携带吸收量与错误，std 原样传递，不代报、不折叠。
        return fs_write(self._handle, bytes)
    }

    micro flush(mut self) -> Option<IoError> {
        if !self._open {
            return Some(io_closed())
        }
        return fs_flush(self._handle)
    }
}

imply File {
    # 释放句柄。幂等：对已关闭的文件是无可观察效果的成功（`None`）。
    micro close(mut self) -> Option<IoError> {
        if !self._open {
            return None
        }
        self._open = false
        return fs_close(self._handle)
    }

    micro is_open(self) -> bool {
        return self._open
    }
}

# ── 整文件便捷层（建立在流式合同之上，不另设宿主通道）────────────────

# 整读：打开 → 读到流尽 → 关闭。失败按种类结构化返回，空数组只出现在
# 真实的零长文件上，不兼作失败哨兵。
micro read_file(path: utf8) -> Result<[u8], IoError> {
    let opened: Result<File, IoError> = open_file(path, Read)
    match opened {
        case Fine(file): {
            let mut handle: File = file
            let content: Result<[u8], IoError> = read_to_end(handle)
            handle.close()
            return content
        }
        case Fail(error):
            return Fail { error: error }
    }
}

# 整写：打开（截断/创建）→ 全量提交 → 压刷 → 关闭。返回提交字节数；
# 任一步失败即结构化返回，且句柄必被关闭（不泄漏资源）。
micro write_file(path: utf8, bytes: [u8]) -> Result<usize, IoError> {
    let opened: Result<File, IoError> = open_file(path, Write)
    match opened {
        case Fine(file): {
            let mut handle: File = file
            let commit: Result<usize, PartialWrite> = write_all(handle, array_view(bytes))
            let drain: Option<IoError> = handle.flush()
            let release: Option<IoError> = handle.close()
            match commit {
                case Fail(partial):
                    return Fail { error: partial.error }
                case Fine(written): {
                    if drain.is_some() {
                        return Fail { error: drain.unwrap() }
                    }
                    if release.is_some() {
                        return Fail { error: release.unwrap() }
                    }
                    return Fine { value: written }
                }
            }
        }
        case Fail(error):
            return Fail { error: error }
    }
}

# 文本桥接：字节读取 + UTF-8 显式转换。文本只是字节之上的编码视图，
# 不是文件资源的原生形态；桥接经 `from_bytes` 严格验证，非法字节序列
# 收敛为 `InvalidEncoding` 结构化失败。
micro read_file_text(path: utf8) -> Result<utf8, IoError> {
    let content: Result<[u8], IoError> = read_file(path)
    match content {
        case Fine(bytes):
            match Utf8Text::from_bytes(bytes) {
                case Fine(text):
                    return Fine { value: text }
                case Fail(decoding):
                    return Fail { error: io_invalid_encoding() }
            }
        case Fail(error):
            return Fail { error: error }
    }
}

micro write_file_text(path: utf8, text: utf8) -> Result<usize, IoError> {
    return write_file(path, Utf8Text::bytes(text))
}

# ── 路径与目录操作（结构化终态）──────────────────────────────────────

# 存在性是纯布尔判定（宿主合同给出），不携带失败语义。
micro file_exists(path: utf8) -> bool {
    return fs_file_exists(path)
}

micro directory_exists(path: utf8) -> bool {
    return fs_directory_exists(path)
}

micro create_directory(path: utf8) -> Option<IoError> {
    return fs_create_directory(path)
}

micro get_current_directory() -> Result<utf8, IoError> {
    return fs_current_directory()
}

micro get_files(path: utf8, pattern: utf8, recursive: bool) -> Result<[utf8], IoError> {
    return fs_list_directory(path, pattern, recursive)
}
