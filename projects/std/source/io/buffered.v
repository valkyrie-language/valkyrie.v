namespace std.io;

using std.types::{Result, Option, Some, None, Fine, Fail};

# std.io: 缓冲包装。
#
# `BufferedReader` 把底层 `read` 的小块读取聚合成内部缓冲，
# 调用方按任意 `max` 消费；`BufferedWriter` 把小块写出聚合到
# 容量阈值再大写落底。两侧都只依赖 `Reader`/`Writer` 合同，
# 不认识底层来源（文件、内存、网络皆可）。
#
# `BufferedWriter` 的排空失败恢复语义（合同的一部分）：
# - 底层提交失败时，只有被确认写出的前缀离开缓冲；未写出的尾部
#   原地保留，下一次 `write` 或 `flush` 会按原顺序再次提交。
#   本侧绝不在失败时清空整个缓冲——已接受进缓冲的字节不因一次
#   底层失败而丢失。
# - 因此 `write` 返回 `Fail` 时，本次输入已被缓冲吸收：调用方不得
#   重发同一批字节（重发即重复），恢复动作是重试 `flush` 或继续
#   写入新数据后 `flush`。
# - `flush` 同样只移除确认写出的前缀；失败返回错误，缓冲保留尾部，
#   可安全重入。

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

# 保留 `[from, length)` 后缀为新缓冲：确认写出的前缀已离开，其余原序保留。
micro buffer_retain_suffix(list: ArrayList<u8>, from: usize) -> ArrayList<u8> {
    let mut rest: ArrayList<u8> = ArrayList::new(list.length - from)
    let mut index: usize = from
    while index < list.length {
        rest.push(list⁅index⁆)
        index = index + 1
    }
    return rest
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
        # 缓冲达到容量即排空到底层一轮。排空成功则清空缓冲；排空失败
        # 只移除确认写出的前缀，未写尾部保留，下一次排空按原顺序续交。
        # 底层自身的缓冲是否压刷由显式 `flush` 决定，`write` 不越权。
        if self._buffer.length >= self._capacity {
            let drain: Result<usize, PartialWrite> = write_all(self._sink, self._buffer.view())
            match drain {
                case Fine(committed): {
                    # 全量提交（committed 即当时的缓冲长度）。
                    self._buffer.clear()
                }
                case Fail(partial): {
                    self._buffer = buffer_retain_suffix(self._buffer, partial.committed)
                    return Fail { error: partial.error }
                }
            }
        }
        return Fine { value: total }
    }

    micro flush(mut self) -> Option<IoError> {
        if self._buffer.length > 0 {
            let drain: Result<usize, PartialWrite> = write_all(self._sink, self._buffer.view())
            match drain {
                case Fine(committed): {
                    self._buffer.clear()
                }
                case Fail(partial): {
                    self._buffer = buffer_retain_suffix(self._buffer, partial.committed)
                    return Some(partial.error)
                }
            }
        }
        return self._sink.flush()
    }
}
