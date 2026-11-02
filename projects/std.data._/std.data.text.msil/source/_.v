namespace std.data.text.msil;

# Local source span for MSIL text (not Valkyrie `.v` / `std.data.text.valkyrie`).
structure TextSpan {
    start: usize
    stop: usize
}

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 旧轨包：诊断码表随错误容许改造补齐，暂以单码占位。
# `TextSpan` 是包内其余 AST/词法文件的局部 span，随旧轨改造一并收敛，本文件不再使用。

[tag(MsilParseResultKind)]
unite MsilParseResult<T> {
    [tag(0)]
    [constructor]
    Fine { value: T }
    [tag(1)]
    [constructor]
    Fail { error: Diagnostic }
}

micro new_msil_diagnostic(message: utf8, start: usize, stop: usize) -> Diagnostic {
    return new_diagnostic("std.data.text.msil.defect", Error, message, new_span(start, stop))
}
