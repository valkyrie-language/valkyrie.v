namespace std.io;

using std.types::{Result, Option, Some};

# std.io: 字节流写出抽象。
#
# `Writer` 的原语是 `write` 与 `flush`：
# - `write` 写入 `bytes`（`ArrayView<u8>` 零拷贝窗口）的一个前缀，
#   返回实际写入的字节数；返回 0 且未失败表示底层暂不可写。
# - `flush` 把缓冲内容压到底层；`Option<IoError>` 承载失败（`None` 即成功）。
#
# `write_all` 是 `write` 上的自由组合子（对任何实现一致可用），语义为
# 「写满或返回错误」：剩余段经复用缓冲以视图交给 `write`；
# `write` 返回 0 时以 `Failed` 终止，避免静默死循环。

trait Writer {
    micro write(mut self, bytes: ArrayView<u8>) -> Result<usize, IoError>

    micro flush(mut self) -> Option<IoError>
}

micro write_all<W>(writer: W, bytes: ArrayView<u8>) -> Option<IoError> {
    let mut cursor: W = writer
    let mut offset: usize = 0
    let total: usize = bytes.length
    # 复用缓冲：每轮 `clear()` 后装剩余段，视图交给 `write`，不逐轮分配新数组。
    let mut rest: ArrayList<u8> = ArrayList::new(total)
    while offset < total {
        rest.clear()
        let mut index: usize = offset
        while index < total {
            rest.push(bytes⁅index⁆)
            index = index + 1
        }
        let written_result: Result<usize, IoError> = cursor.write(rest.view())
        match written_result {
            case Fine(written): {
                if written == 0 {
                    return Some(io_failed())
                }
                offset = offset + written
            }
            case Fail(error):
                return Some(error)
        }
    }
    return None
}
