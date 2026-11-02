namespace std.data.binary.jar;

using std.data.binary.`class`;

# Minimal JAR surface. Full zip/jar encode is frozen with the JVM lane;
# present so workspace members declared in legions.von resolve.

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 诊断类型收敛到 `std.diagnostic::Diagnostic`（统一合同，不再各自定义）。
# 旧轨包：诊断码表随错误容许改造补齐，暂以单码占位。

[tag(JarBinaryResultKind)]
unite JarBinaryResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: Diagnostic }
}

micro jar_binary_diagnostic(message: utf8) -> Diagnostic {
    return new_diagnostic("std.data.binary.jar.defect", Error, message, new_span(0, 0))
}

micro jar_encode_empty() -> [i32] {
    return []
}
