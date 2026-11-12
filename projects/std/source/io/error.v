namespace std.io;

# std.io: 流错误分类。
#
# 错误语义由种类承载（结构化错误码），不携带自由文本消息：
# 调用方按种类做恢复决策，展示层按种类自行组织文案。
# 控制流一律经 `Result`/`Option` 返回，不用 panic 当控制流。

enums IoErrorKind {
    # 流已尽：`read_exact` 未读满请求的字节数。
    EndOfStream
    # 流已关闭。
    Closed
    # 该流不支持此操作（如容量为 0 的缓冲读取）。
    Unsupported
    # 调用参数不合法（如负值语义越界）。
    InvalidInput
    # 底层失败，未细分。
    Failed
    # 字节桥接为文本时不是合法 UTF-8：字节到文本的显式转换层失败。
    InvalidEncoding
}

structure IoError {
    kind: IoErrorKind
}

micro io_error(kind: IoErrorKind) -> IoError {
    return IoError { kind: kind }
}

micro io_error_kind(error: IoError) -> IoErrorKind {
    return error.kind
}

# 种类的数值探针（稳定顺序即声明序）：供测试与跨层断言做等值判定，
# 不以 `match` 形态把种类暴露给必须逐点判别的消费方。
micro io_error_code(error: IoError) -> i64 {
    match error.kind {
        case EndOfStream: {
            return 1
        }
        case Closed: {
            return 2
        }
        case Unsupported: {
            return 3
        }
        case InvalidInput: {
            return 4
        }
        case Failed: {
            return 5
        }
        case InvalidEncoding: {
            return 6
        }
    }
}

# 各类型的直接构造入口（与 `io_error` 同义，按种类一名一函）。

micro io_end_of_stream() -> IoError {
    return IoError { kind: EndOfStream }
}

micro io_closed() -> IoError {
    return IoError { kind: Closed }
}

micro io_unsupported() -> IoError {
    return IoError { kind: Unsupported }
}

micro io_invalid_input() -> IoError {
    return IoError { kind: InvalidInput }
}

micro io_failed() -> IoError {
    return IoError { kind: Failed }
}

micro io_invalid_encoding() -> IoError {
    return IoError { kind: InvalidEncoding }
}
