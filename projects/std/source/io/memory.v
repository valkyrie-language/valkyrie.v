namespace std.io;

using std.types::{Result, Option};

# std.io: 内存字节流。
#
# `BytesReader` 把一段 `[u8]` 包装成 `Reader`（读端）；
# `BytesWriter` 把写出聚合到内部 `ArrayList<u8>` 缓冲（写端），
# 经 `written_bytes` 冻结取回。二者是测试、编解码管线与 `std.vfs`
# 内存后端的共用底座，不涉及任何宿主能力。

structure BytesReader {
    _bytes: [u8]
    _cursor: usize
}

micro bytes_reader(bytes: [u8]) -> BytesReader {
    return BytesReader { _bytes: bytes, _cursor: 0 }
}

imply BytesReader: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        let mut collected: ArrayList<u8> = ArrayList::new(max)
        while collected.length < max && self._cursor < self._bytes.length {
            collected.push(self._bytes⁅self._cursor⁆)
            self._cursor = self._cursor + 1
        }
        return Fine { value: collected.to_array() }
    }
}

structure BytesWriter {
    _bytes: ArrayList<u8>
}

micro bytes_writer() -> BytesWriter {
    return BytesWriter { _bytes: ArrayList::new(0) }
}

imply BytesWriter: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, WriteFailure> {
        let total: usize = bytes.length
        let mut index: usize = 0
        while index < total {
            self._bytes.push(bytes⁅index⁆)
            index = index + 1
        }
        return Fine { value: total }
    }

    micro flush(mut self) -> Option<IoError> {
        return None
    }
}

# 取回已累计的字节（冻结为定长数组；不消费写器，可继续写）。
micro written_bytes(writer: BytesWriter) -> [u8] {
    return writer._bytes.to_array()
}
