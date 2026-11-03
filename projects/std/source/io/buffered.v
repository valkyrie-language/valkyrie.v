namespace std.io;

using std.types::{Result, Option};

# std.io: 缓冲包装。
#
# `BufferedReader` 把底层 `read` 的小块读取聚合成内部缓冲，
# 调用方按任意 `max` 消费；`BufferedWriter` 把小块写出聚合到
# 容量阈值再大写落底。两侧都只依赖 `Reader`/`Writer` 合同，
# 不认识底层来源（文件、内存、网络皆可）。

structure BufferedReader<R> {
    _source: R
    _buffer: [u8]
    _cursor: usize
    _capacity: usize
}

micro buffered_reader<R>(source: R, capacity: usize) -> BufferedReader<R> {
    return BufferedReader { _source: source, _buffer: [], _cursor: 0, _capacity: capacity }
}

imply BufferedReader<R>: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if self._capacity == 0 {
            return Fail { error: io_unsupported() }
        }
        let mut collected: ArrayList<u8> = ArrayList::new(max)
        while collected.length < max {
            if self._cursor >= self._buffer.length {
                let refill: Result<[u8], IoError> = self._source.read(self._capacity)
                match refill {
                    case Fine(chunk): {
                        if chunk.length == 0 {
                            # 底层流尽：返回已收集的前缀（可能为空块）。
                            return Fine { value: collected.to_array() }
                        }
                        self._buffer = chunk
                        self._cursor = 0
                    }
                    case Fail(error):
                        return Fail { error: error }
                }
            }
            collected.push(self._buffer⁅self._cursor⁆)
            self._cursor = self._cursor + 1
        }
        return Fine { value: collected.to_array() }
    }
}

structure BufferedWriter<W> {
    _sink: W
    _buffer: ArrayList<u8>
    _capacity: usize
}

micro buffered_writer<W>(sink: W, capacity: usize) -> BufferedWriter<W> {
    return BufferedWriter { _sink: sink, _buffer: ArrayList::new(capacity), _capacity: capacity }
}

imply BufferedWriter<W>: Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError> {
        if self._capacity == 0 {
            return Fail { error: io_unsupported() }
        }
        let total: usize = bytes.length
        let mut index: usize = 0
        while index < total {
            self._buffer.push(bytes⁅index⁆)
            index = index + 1
        }
        # 缓冲达到容量即排空到底层一轮；排空失败的错误透传给调用方。
        # 底层自身的缓冲是否压刷由显式 `flush` 决定，`write` 不越权。
        if self._buffer.length >= self._capacity {
            let drain: Option<IoError> = write_all(self._sink, self._buffer.view())
            self._buffer.clear()
            if drain.is_some() {
                return Fail { error: drain.unwrap() }
            }
        }
        return Fine { value: total }
    }

    micro flush(mut self) -> Option<IoError> {
        if self._buffer.length > 0 {
            let drain: Option<IoError> = write_all(self._sink, self._buffer.view())
            self._buffer.clear()
            if drain.is_some() {
                return drain
            }
        }
        return self._sink.flush()
    }
}
