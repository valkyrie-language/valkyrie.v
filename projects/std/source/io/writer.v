namespace std.io;

using std.types::{Result, Option, Fine, Fail};

# std.io: 字节流写出抽象。
#
# `Writer` 的原语是 `write` 与 `flush`：
# - `write` 写入 `bytes`（`ArrayView<u8>` 零拷贝窗口）的一个前缀，
#   返回实际提交的字节数；返回 0 且未失败表示底层暂不可写。
# - `flush` 把缓冲内容压到底层；`Option<IoError>` 承载失败（`None` 即成功）。
#
# `write_all` 是 `write` 上的自由组合子（对任何实现一致可用），语义为
# 「全部提交，或报告已提交前缀」，单一模型：
# - 写者以 `mut` 借用进入、内部 cursor 逐轮推进：不复制泛型写者，
#   改动直接落在调用方持有的实例上；
# - 每轮只把剩余区间的零拷贝后缀窗口交给 `write`：短写不重复搬运
#   已提交字节，也不逐轮重拼剩余输入；
# - 失败经 `PartialWrite` 同时携带已提交字节数与错误，调用方据此
#   决定重传起点或恢复动作；
# - `write` 返回 0（零提交）即终止，以 `Failed` 报告，避免静默死循环。

trait Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError>

    micro flush(mut self) -> Option<IoError>
}

# 部分提交状态：`committed` 是底层已确认可见的字节数，`error` 是失败原因。
# 两者不可分离——丢弃提交数就丢掉恢复点，丢弃错误就丢掉原因。
structure PartialWrite {
    committed: usize
    error: IoError
}

# 后缀零拷贝窗口：`view` 的 `[offset, length)` 子区间，不复制元素。
micro view_suffix(view: ArrayView<u8>, offset: usize) -> ArrayView<u8> {
    return ArrayView { _source: view._source, _offset: view._offset + offset, _length: view._length - offset }
}

micro write_all<W>(mut writer: W, bytes: ArrayView<u8>) -> Result<usize, PartialWrite> {
    let total: usize = bytes.length
    let mut offset: usize = 0
    while offset < total {
        let window: ArrayView<u8> = view_suffix(bytes, offset)
        let step: Result<usize, IoError> = writer.write(window)
        match step {
            case Fine(written): {
                if written == 0 {
                    return Fail { error: PartialWrite { committed: offset, error: io_failed() } }
                }
                offset = offset + written
            }
            case Fail(error):
                return Fail { error: PartialWrite { committed: offset, error: error } }
        }
    }
    return Fine { value: total }
}
