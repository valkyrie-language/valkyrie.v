namespace std.io.test;

using std.io::{
    BytesReader, BytesWriter, bytes_reader, bytes_writer, written_bytes,
    read_exact, read_to_end, write_all, io_error_code, IoError, io_failed,
    Writer, Reader, WriteFailure, PartialWrite,
    BufferedReader, BufferedWriter, buffered_reader, buffered_writer,
};
using std.types::{Result, Option, Some, None, Fine, Fail};

# std.io 字节流抽象的 lane 无关测试：
# 只走内存读写端（BytesReader/BytesWriter）、失败替身与组合子，
# 不触碰任何 [host_contract]，因此不依赖任何 lane 的 provider。

# 失败替身写端：每轮至多吸收 2 字节，随后以 `Fail` 报告吸收量 2。
# 用于验证「失败也携带真实吸收量」与 `write_all` 恢复点。
structure StallingWriter {
    _sink: ArrayList<u8>
}

micro stalling_writer() -> StallingWriter {
    return StallingWriter { _sink: ArrayList::new(0) }
}

imply StallingWriter: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, WriteFailure> {
        let take: usize = if bytes.length > 2 { 2 } else { bytes.length }
        let mut index: usize = 0
        while index < take {
            self._sink.push(bytes⁅index⁆)
            index = index + 1
        }
        if take == 0 {
            return Fail { error: WriteFailure { absorbed: 0, error: io_failed() } }
        }
        return Fail { error: WriteFailure { absorbed: take, error: io_failed() } }
    }

    micro flush(mut self) -> Option<IoError> {
        return None
    }
}

# 失败替身读端：前 `ok_reads` 次正常出块，之后一律失败。
structure FlakyReader {
    _data: [u8]
    _cursor: usize
    _ok_reads: usize
    _reads: usize
}

micro flaky_reader(data: [u8], ok_reads: usize) -> FlakyReader {
    return FlakyReader { _data: data, _cursor: 0, _ok_reads: ok_reads, _reads: 0 }
}

imply FlakyReader: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if self._reads >= self._ok_reads {
            return Fail { error: io_failed() }
        }
        self._reads = self._reads + 1
        let mut collected: ArrayList<u8> = ArrayList::new(max)
        while collected.length < max && self._cursor < self._data.length {
            collected.push(self._data⁅self._cursor⁆)
            self._cursor = self._cursor + 1
        }
        return Fine { value: collected.to_array() }
    }
}

[test]
micro `bytes writer accumulates view writes`() {
    let writer: BytesWriter = bytes_writer()
    let first: Result<usize, PartialWrite> = write_all(writer, [1 as u8, 2 as u8, 3 as u8])
    match first {
        case Fine(n):
            if n != 3 {
                panic("first write_all must commit three bytes")
            }
        case Fail(partial):
            panic("first write_all must succeed")
    }
    let second: Result<usize, PartialWrite> = write_all(writer, [4 as u8, 5 as u8])
    match second {
        case Fail(partial):
            panic("second write_all must succeed")
        case Fine(n):
            if n != 2 {
                panic("second write_all must commit two bytes")
            }
    }
    let output: [u8] = written_bytes(writer)
    if output.length != 5 {
        panic("written_bytes must keep all five bytes")
    }
    if output⁅0⁆ != 1 as u8 {
        panic("written_bytes must start with the first byte")
    }
    if output⁅4⁆ != 5 as u8 {
        panic("written_bytes must end with the last byte")
    }
}

[test]
micro `write_all recovery point carries absorbed amount on failure`() {
    # 每轮吸收 2 后失败：恢复点必须是真实吸收总量 2，
    # 调用方从恢复点重传不会重复也不会丢归属。
    let writer: StallingWriter = stalling_writer()
    let result: Result<usize, PartialWrite> = write_all(writer, [1 as u8, 2 as u8, 3 as u8, 4 as u8, 5 as u8])
    match result {
        case Fine(n):
            panic("stalling writer must fail")
        case Fail(partial):
            if partial.committed != 2 {
                panic("recovery point must equal absorbed amount")
            }
    }
}

[test]
micro `bytes reader streams chunks and drains`() {
    let mut reader: BytesReader = bytes_reader([10 as u8, 11 as u8, 12 as u8, 13 as u8, 14 as u8])
    let first: Result<[u8], IoError> = reader.read(3)
    match first {
        case Fine(chunk): {
            if chunk.length != 3 {
                panic("first chunk must carry three bytes")
            }
            if chunk⁅2⁆ != 12 as u8 {
                panic("first chunk must keep source order")
            }
        }
        case Fail(error): {
            panic("first chunk must not fail")
        }
    }
    let second: Result<[u8], IoError> = reader.read(3)
    match second {
        case Fine(chunk): {
            if chunk.length != 2 {
                panic("second chunk must carry the remaining two bytes")
            }
            if chunk⁅0⁆ != 13 as u8 {
                panic("second chunk must resume at the cursor")
            }
        }
        case Fail(error): {
            panic("second chunk must not fail")
        }
    }
    let third: Result<[u8], IoError> = reader.read(3)
    match third {
        case Fine(chunk): {
            if chunk.length != 0 {
                panic("drained reader must yield empty chunks")
            }
        }
        case Fail(error): {
            panic("drained read must stay in bounds")
        }
    }
}

[test]
micro `read combinators advance the caller reader`() {
    # `read_exact` 以 `mut` 借用进入：游标推进必须留在调用方实例上，
    # 不得按值复制读端后丢弃状态。
    let mut reader: BytesReader = bytes_reader([1 as u8, 2 as u8, 3 as u8, 4 as u8])
    let taken: Result<[u8], IoError> = read_exact(reader, 2)
    match taken {
        case Fail(error):
            panic("read_exact must succeed on a full source")
        case Fine(bytes):
            if bytes.length != 2 || bytes⁅1⁆ != 2 as u8 {
                panic("read_exact must return the requested prefix")
            }
    }
    let rest: Result<[u8], IoError> = reader.read(4)
    match rest {
        case Fine(bytes):
            if bytes.length != 2 || bytes⁅0⁆ != 3 as u8 {
                panic("caller reader must resume after read_exact")
            }
        case Fail(error):
            panic("follow-up read must succeed")
    }
}

[test]
micro `read to end roundtrips through the bytes pair`() {
    let writer: BytesWriter = bytes_writer()
    let write_result: Result<usize, PartialWrite> = write_all(writer, [0 as u8, 127 as u8, 128 as u8, 255 as u8])
    match write_result {
        case Fail(partial):
            panic("write_all must succeed on the memory writer")
        case Fine(n):
            if n != 4 {
                panic("write_all must commit all four bytes")
            }
    }
    let stored: [u8] = written_bytes(writer)
    let mut reader: BytesReader = bytes_reader(stored)
    let result: Result<[u8], IoError> = read_to_end(reader)
    match result {
        case Fine(bytes): {
            if bytes.length != 4 {
                panic("roundtrip must keep the byte count")
            }
            if bytes⁅1⁆ != 127 as u8 {
                panic("roundtrip must keep the boundary byte")
            }
            if bytes⁅2⁆ != 128 as u8 {
                panic("roundtrip must keep bytes outside the text range")
            }
        }
        case Fail(error): {
            panic("read_to_end must succeed on the memory reader")
        }
    }
}

[test]
micro `read exact surfaces end of stream as structured failure`() {
    let mut reader: BytesReader = bytes_reader([9 as u8])
    let result: Result<[u8], IoError> = read_exact(reader, 2)
    match result {
        case Fine(chunk): {
            panic("read_exact must fail on a short source")
        }
        case Fail(error): {
            if io_error_code(error) != 1 {
                panic("short read_exact must report EndOfStream")
            }
        }
    }
}

[test]
micro `buffered read keeps prefix and defers refill error`() {
    # 源只成功一次（4 字节），第二次 refill 失败：
    # 已收集前缀必须作为数据交出，错误滞留到下一次 `read`。
    let source: FlakyReader = flaky_reader([1 as u8, 2 as u8, 3 as u8, 4 as u8], 1)
    let mut reader: BufferedReader<FlakyReader> = buffered_reader(source, 4)
    let first: Result<[u8], IoError> = reader.read(8)
    match first {
        case Fine(chunk):
            if chunk.length != 4 || chunk⁅3⁆ != 4 as u8 {
                panic("buffered read must deliver the collected prefix")
            }
        case Fail(error):
            panic("refill error must not discard the collected prefix")
    }
    let second: Result<[u8], IoError> = reader.read(8)
    match second {
        case Fine(chunk):
            panic("deferred refill error must surface")
        case Fail(error):
            ()
    }
}

[test]
micro `buffered writer absorbs input even when drain fails`() {
    # 缓冲写排空失败时输入已整段进缓冲：吸收量为全部输入，
    # `write_all` 恢复点覆盖全部字节，调用方不得重发。
    let sink: StallingWriter = stalling_writer()
    let mut writer: BufferedWriter<StallingWriter> = buffered_writer(sink, 2)
    let result: Result<usize, PartialWrite> = write_all(writer, [7 as u8, 8 as u8, 9 as u8, 10 as u8])
    match result {
        case Fine(n):
            panic("drain failure must propagate")
        case Fail(partial):
            if partial.committed != 4 {
                panic("buffered write must absorb the full input on drain failure")
            }
    }
}
