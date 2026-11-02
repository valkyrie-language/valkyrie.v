namespace std.data;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};

# 诊断访问器往返：构造 → code/span 读回一致。

[test]
micro test_diagnostic_code_span_round_trip() -> unit {
    let diagnostic: Diagnostic = new_diagnostic("std.data.probe.round_trip", Error, "probe message", new_span(3, 7))
    if !data_diagnostic_code(diagnostic).equals("std.data.probe.round_trip") {
        panic("diagnostic code round trip mismatch")
    }
    let span = data_diagnostic_span(diagnostic)
    if span.start != 3 || span.end != 7 {
        panic("diagnostic span round trip mismatch")
    }
}
