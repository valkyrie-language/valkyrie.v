namespace std.io;

using std.types::{Result};

# std.io: 字节流读取抽象。
#
# `Reader` 的唯一原语是 `read`：每次调用返回至多 `max` 字节的一个块，
# 块长 ∈ 0..=max；空块表示流尽（此后不再产生字节）。失败经 `Result` 返回。
#
# `read_exact` / `read_to_end` / `read_to_text` 是 `read` 上的自由组合子
# （对本 trait 的任何实现一致可用），实现方只需提供 `read`。
#
# 本层不认识路径、不认识文件系统：字节来源由实现方决定
# （内存字节串、文件、套接字、解码管道均可）。文件系统入口在 `std.fs`。

trait Reader {
    micro read(mut self, max: usize) -> Result<[u8], IoError>
}

# 恰好读满 `count` 字节；流提前结束（短读）时以 `EndOfStream` 失败，
# 已读到的前缀随失败丢弃（调用方需要部分前缀时应自行循环 `read`）。
micro read_exact<R>(reader: R, count: usize) -> Result<[u8], IoError> {
    let mut cursor: R = reader
    let mut collected: ArrayList<u8> = ArrayList::new(count)
    while collected.length < count {
        let remaining: usize = count - collected.length
        let chunk_result: Result<[u8], IoError> = cursor.read(remaining)
        match chunk_result {
            case Fine(chunk): {
                if chunk.length == 0 {
                    return Fail { error: io_end_of_stream() }
                }
                let mut index: usize = 0
                while index < chunk.length {
                    collected.push(chunk⁅index⁆)
                    index = index + 1
                }
            }
            case Fail(error):
                return Fail { error: error }
        }
    }
    return Fine { value: collected.to_array() }
}

# 读到流尽为止，返回全部字节。
micro read_to_end<R>(reader: R) -> Result<[u8], IoError> {
    let mut cursor: R = reader
    let mut collected: ArrayList<u8> = ArrayList::new(0)
    # 固定读取块大小：组合子层的默认调度粒度，与具体源无关。
    let chunk_size: usize = 4096
    let mut reading: bool = true
    while reading {
        let chunk_result: Result<[u8], IoError> = cursor.read(chunk_size)
        match chunk_result {
            case Fine(chunk): {
                if chunk.length == 0 {
                    reading = false
                }
                else {
                    let mut index: usize = 0
                    while index < chunk.length {
                        collected.push(chunk⁅index⁆)
                        index = index + 1
                    }
                }
            }
            case Fail(error):
                return Fail { error: error }
        }
    }
    return Fine { value: collected.to_array() }
}

# 读到流尽并按 UTF-8 桥接为文本（`std.text` 的 `Utf8Text::from_bytes`）。
# 桥接是字节到文本的显式入口；输入不是合法 UTF-8 时的诊断口径归
# `std.text` 的解码合同，本层不做校验。
micro read_to_text<R>(reader: R) -> Result<utf8, IoError> {
    let bytes_result: Result<[u8], IoError> = read_to_end(reader)
    match bytes_result {
        case Fine(bytes):
            return Fine { value: std::text::Utf8Text::from_bytes(bytes) }
        case Fail(error):
            return Fail { error: error }
    }
}
