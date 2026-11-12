namespace std.io;

using std.types::{Result, Option, Fine, Fail};

# std.io: 字节流写出抽象。
#
# `Writer` 的原语是 `write` 与 `flush`，两侧共用一个口径——吸收量：
# - `write` 对输入窗口的前缀负责：`Fine(n)` 表示本轮从窗口吸收了
#   `n` 字节（归属写者状态：已落底、或已收进写者自己的缓冲）；
#   返回 0 且未失败表示底层暂不可写。
# - 失败经 `WriteFailure` 同时携带本轮真实吸收量 `absorbed` 与错误：
#   吸收量以下的数据归写者所有，调用方不得重发；吸收量以上仍归调用方。
#   成功与失败共享同一「吸收量」语义，任何实现对同一恢复算法一致可替换。
# - `flush` 把写者内部滞留压到底层；`Option<IoError>` 承载失败
#   （`None` 即成功）。`flush` 失败不改变归属：滞留字节仍归写者。
#
# `write_all` 是 `write` 上的自由组合子（对任何实现一致可用），语义为
# 「全部吸收，或报告吸收到的恢复点」，单一模型：
# - 写者以 `mut` 借用进入、内部游标逐轮推进：不复制泛型写者，
#   改动直接落在调用方持有的实例上；
# - 每轮只把剩余区间的零拷贝后缀窗口交给 `write`：短写不重复搬运
#   已吸收字节，也不逐轮重拼剩余输入；
# - 失败经 `PartialWrite` 携带吸收到的恢复点与错误：恢复点以下的字节
#   已被写者吸收，重传只能从恢复点开始——该恢复点对任意 `Writer`
#   实现成立（含缓冲写：其吸收量覆盖进缓冲的输入，失败不丢归属）；
# - `write` 返回 0（零吸收）即终止，以 `Failed` 报告，避免静默死循环。

trait Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, WriteFailure>

    micro flush(mut self) -> Option<IoError>
}

# 写出失败：`absorbed` 是本轮从输入窗口真实吸收的字节数（含收进写者
# 内部缓冲的部分），`error` 是失败原因。两者不可分离——丢弃吸收量
# 就丢掉恢复归属，丢弃错误就丢掉原因。
structure WriteFailure {
    absorbed: usize
    error: IoError
}

# 组合子失败：`committed` 是截至失败点写者已吸收的总量（恢复点），
# `error` 是失败原因。调用方重传只能从 `committed` 开始。
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
    let mut absorbed: usize = 0
    while absorbed < total {
        let window: ArrayView<u8> = view_suffix(bytes, absorbed)
        let step: Result<usize, WriteFailure> = writer.write(window)
        match step {
            case Fine(n): {
                if n == 0 {
                    return Fail { error: PartialWrite { committed: absorbed, error: io_failed() } }
                }
                absorbed = absorbed + n
            }
            case Fail(failure): {
                # 失败轮同样有归属：`absorbed` 字节已被写者收下，
                # 恢复点必须含入，否则重传即重复。
                let recovered: usize = absorbed + failure.absorbed
                return Fail { error: PartialWrite { committed: recovered, error: failure.error } }
            }
        }
    }
    return Fine { value: total }
}
