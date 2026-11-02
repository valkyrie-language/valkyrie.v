namespace std.data.text.von;

# Local source span for VON text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 旧轨包：诊断码表随错误容许改造补齐，暂以单码占位。
# `TextSpan` 是包内其余 AST/词法文件的局部 span，随旧轨改造一并收敛，本文件不再使用。

[tag(VonParseResultKind)]
unite VonParseResult<T> {
    [tag(0)]
    [constructor]
    Fine { value: T }
    [tag(1)]
    [constructor]
    Fail { error: Diagnostic }
}

micro new_von_diagnostic(message: utf8, start: usize, stop: usize) -> Diagnostic {
    return new_diagnostic("std.data.text.von.defect", Error, message, new_span(start, stop))
}

micro von_parse_take_fail<T>(parsed: VonParseResult<T>) -> Diagnostic? {
    match parsed {
        case Fail(error):
            return Some(error)
        else:
            return None()
    }
}

micro von_parse_take_fine<T>(parsed: VonParseResult<T>) -> T? {
    match parsed {
        case Fine(value):
            return Some(value)
        else:
            return None()
    }
}
