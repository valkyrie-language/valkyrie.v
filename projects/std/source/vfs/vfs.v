namespace std.vfs;

using std.io::{Reader, Writer, IoError, io_failed};
using std.types::{Result, Option, Some, Fine, Fail};

# std.vfs: 虚拟文件系统层 —— 把 `std.io` 的字节流抽象挂到可替换后端上。
#
# 分层合同：
# - `std.io` 只提供 Reader/Writer 流抽象，不认识路径；
# - 本层持有路径语义，以 `std.fs`（宿主文件系统字节合同）为默认后端；
# - 反向不允许：`std.fs` 不依赖本层，`std.io` 不依赖两者。
#
# `VfsReader` 在构造时经后端整读路径的全部字节，此后 `read` 只在
# 已加载字节上推进游标，不再触发宿主调用；构造时路径不存在则置失败态，
# 首次 `read` 以 `Failed` 结构化返回，不用 panic 当控制流。
#
# `VfsWriter` 把写出的字节经 `ArrayView<u8>` 零拷贝窗口累积进缓冲，
# `flush` 时整段提交后端（文件后端为整体覆盖语义，缓冲不清空、
# 重复 `flush` 幂等）；写路径不逐字节复制整表，也不用临时定长数组重拼。

structure VfsReader {
    _bytes: [u8]
    _cursor: usize
    _available: bool
}

micro vfs_reader(path: utf8) -> VfsReader {
    if std::fs::exists(path) {
        return VfsReader { _bytes: std::fs::read_bytes(path), _cursor: 0, _available: true }
    }
    return VfsReader { _bytes: [], _cursor: 0, _available: false }
}

imply VfsReader: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if !self._available {
            return Fail { error: io_failed() }
        }
        let mut collected: ArrayList<u8> = ArrayList::new(max)
        while collected.length < max && self._cursor < self._bytes.length {
            collected.push(self._bytes⁅self._cursor⁆)
            self._cursor = self._cursor + 1
        }
        return Fine { value: collected.to_array() }
    }
}

structure VfsWriter {
    _path: utf8
    _buffer: ArrayList<u8>
}

micro vfs_writer(path: utf8) -> VfsWriter {
    return VfsWriter { _path: path, _buffer: ArrayList::new(0) }
}

imply VfsWriter: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError> {
        let total: usize = bytes.length
        let mut index: usize = 0
        while index < total {
            self._buffer.push(bytes⁅index⁆)
            index = index + 1
        }
        return Fine { value: total }
    }

    micro flush(mut self) -> Option<IoError> {
        let committed: bool = std::fs::write_bytes(self._path, self._buffer.to_array())
        if committed {
            return None
        }
        return Some(io_failed())
    }
}
