namespace std.io;

using std.types::{Result, Option, Some, None, Fine, Fail};

# std.io: 缓冲包装。
#
# `BufferedReader` 把底层 `read` 的小块读取聚合成内部缓冲，
# 调用方按任意 `max` 消费；`BufferedWriter` 把小块写出聚合到
# 容量阈值再大写落底。两侧都只依赖 `Reader`/`Writer` 合同，
# 不认识底层来源（文件、内存、网络皆可）。
#
# 归属合同（与 `Writer`/`write_all` 的吸收量口径一致，无特殊说明）：
# - `BufferedWriter.write` 把整段输入收进内部缓冲即视为吸收：
#   成功返回 `Fine(total)`；排空失败返回 `Fail(WriteFailure)` 且
#   `absorbed = total`——输入已归本写者所有，调用方（含 `write_all`）
#   不得重发，恢复动作是重试 `flush` 或继续写入。
# - 排空失败时只有被确认吸收的前缀离开缓冲，未落底尾部原序保留，
#   下一次 `write` 或 `flush` 按序续交；绝不清空整缓冲。
# - `flush` 同样只移除确认吸收的前缀；失败返回错误、缓冲保留尾部，
#   可安全重入。
#
# `BufferedReader.read` 的状态归属：读端游标只在返回数据时前进——
# 底层 refill 失败且本轮已收集到前缀时，先把前缀作为 `Fine` 交出、
# 把错误滞留为待报状态，下一次 `read` 以 `Fail` 报告；失败且无
# 前缀可交时直接 `Fail`，游标不动。返回的数据与游标推进严格一致，
# 不存在「报错了但字节已被吃掉」的丢尾形态。

structure BufferedReader<R> {
    _source: R
    _buffer: [u8]
    _cursor: usize
    _capacity: usize
    _pending_error: Option<IoError>
}

micro buffered_reader<R>(source: R, capacity: usize) -> BufferedReader<R> {
    return BufferedReader { _source: source, _buffer: [], _cursor: 0, _capacity: capacity, _pending_error: None }
}

imply BufferedReader<R>: Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError> {
        if self._capacity == 0 {
            return Fail { error: io_unsupported() }
        }
        # 待报错误优先于新读取：上一次失败时未交付的字节从未被消费，
        # 这里只把错误本身交出去。
        if self._pending_error.is_some() {
            let pending: IoError = self._pending_error.unwrap()
            self._pending_error = None
            return Fail { error: pending }
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
                    case Fail(error): {
                        if collected.length == 0 {
                            # 无前缀可交：游标不动，错误直接返回。
                            return Fail { error: error }
                        }
                        # 已有前缀：字节归本次返回，错误滞留待下一次
                        # `read` 报告——返回的数据与游标推进严格一致。
                        self._pending_error = Some(error)
                        return Fine { value: collected.to_array() }
                    }
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

# 保留 `[from, length)` 后缀为新缓冲：确认吸收的前缀已离开，其余原序保留。
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
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, WriteFailure> {
        if self._capacity == 0 {
            return Fail { error: WriteFailure { absorbed: 0, error: io_unsupported() } }
        }
        let total: usize = bytes.length
        let mut index: usize = 0
        while index < total {
            self._buffer.push(bytes⁅index⁆)
            index = index + 1
        }
        # 缓冲达到容量即排空到底层一轮。输入已整段收进缓冲：无论排空
        # 成败，本轮吸收量都是 `total`。排空成功则清空缓冲；排空失败
        # 只移除底层确认吸收的前缀，未落底尾部保留，下一次排空续交，
        # 并以 `absorbed = total` 报告归属——调用方不得重发本批字节。
        if self._buffer.length >= self._capacity {
            let drain: Result<usize, PartialWrite> = write_all(self._sink, self._buffer.view())
            match drain {
                case Fine(committed): {
                    # 全量吸收（committed 即当时的缓冲长度）。
                    self._buffer.clear()
                }
                case Fail(partial): {
                    self._buffer = buffer_retain_suffix(self._buffer, partial.committed)
                    return Fail { error: WriteFailure { absorbed: total, error: partial.error } }
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
