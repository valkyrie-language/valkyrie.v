namespace std.diagnostic;

# std.diagnostic — 通用结构化诊断层（值，不是异常）。
#
# 位置模型：`Span` 是半开区间 [start, end)；文本格式的源单元是字符、
# 二进制格式是字节，本层不解释单位语义，由使用方各自注明。
# 文件/源标识由外层携带，不进 `Diagnostic`。
#
# 严重程度的解释权：产生阶段只如实标注，是否继续、如何降级由后续阶段与
# 消费方判定，本层不替下游决定。

# 严重程度三档：纯标记（无 payload），`enums` 形态。
enums Severity {
    Info
    Warning
    Error
}

# 半开区间 [start, end)。
structure Span {
    start: usize
    end: usize
}

micro new_span(start: usize, end: usize) -> Span {
    return Span {
        start: start,
        end: end
    }
}

# span 是否形态合法（`end` 不早于 `start`）。
micro span_is_well_formed(span: Span) -> bool {
    return span.end >= span.start
}

# `child` 是否完整落在 `parent` 内（两端均为半开区间语义）。
micro span_contains(parent: Span, child: Span) -> bool {
    if !span_is_well_formed(parent) {
        return false
    }
    if !span_is_well_formed(child) {
        return false
    }
    return child.start >= parent.start && child.end <= parent.end
}

# span 长度；形态非法时按 0 处理，不产生负值。
micro span_length(span: Span) -> usize {
    if span.end < span.start {
        return 0
    }
    return span.end - span.start
}

# 结构化诊断：
# - `code`：稳定机器可读码，由产出方自己定义取值并登记（如
#   `markdown.unclosed_fence`、`wasm.section.unknown_id`）；本层不拥有码表。
# - `span`：主位置。
# - `related`：主相关位置（零宽哨兵 0..0 表示无）。需要表达多个相关位置时，
#   以同 code 的多条诊断分别携带，不在单条诊断上挂列表。
structure Diagnostic {
    code: utf8
    severity: Severity
    message: utf8
    span: Span
    related: Span
}

micro new_diagnostic(code: utf8, severity: Severity, message: utf8, span: Span) -> Diagnostic {
    return Diagnostic {
        code: code,
        severity: severity,
        message: message,
        span: span,
        related: new_span(0, 0)
    }
}

micro diagnostic_with_related(code: utf8, severity: Severity, message: utf8, span: Span, related: Span) -> Diagnostic {
    return Diagnostic {
        code: code,
        severity: severity,
        message: message,
        span: span,
        related: related
    }
}

micro diagnostic_code(diagnostic: Diagnostic) -> utf8 {
    return diagnostic.code
}

micro diagnostic_span(diagnostic: Diagnostic) -> Span {
    return diagnostic.span
}

micro severity_is_error(severity: Severity) -> bool {
    match severity {
        case Error:
            true
        case Warning:
            false
        case Info:
            false
    }
}
