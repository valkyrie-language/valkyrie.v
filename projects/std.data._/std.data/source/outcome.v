namespace std.data;

# 诊断严重程度。判定权留给后续阶段与消费方：
# 产生阶段只如实标注，不替下游决定是否继续。
unite DataSeverity {
    Error
    Warning
    Info
}

# 结构化诊断（值，不是异常）：
# - `code`：稳定机器可读码，格式侧自己定义取值并在包内文档登记（如
#   `markdown.unclosed_fence`、`wasm.section.unknown_id`）；公共层不拥有码表。
# - `severity`：严重程度。
# - `span`：主位置。
# - `related`：主相关位置（零宽哨兵 0..0 表示无）。相关 token/节点一律以
#   span 引用——token kind 归格式私有，诊断模型若强类型化就会每格式一套，
#   违背统一；消费方按 span 回查源与 token 流。需要表达多个相关位置时，
#   以同 code 的多条诊断分别携带，不在单条诊断上挂列表。
structure DataDiagnostic {
    code: utf8
    severity: DataSeverity
    message: utf8
    span: DataSpan
    related: DataSpan
}

micro new_data_diagnostic(code: utf8, severity: DataSeverity, message: utf8, span: DataSpan) -> DataDiagnostic {
    return DataDiagnostic {
        code: code,
        severity: severity,
        message: message,
        span: span,
        related: new_data_span(0, 0)
    }
}

micro data_diagnostic_with_related(code: utf8, severity: DataSeverity, message: utf8, span: DataSpan, related: DataSpan) -> DataDiagnostic {
    return DataDiagnostic {
        code: code,
        severity: severity,
        message: message,
        span: span,
        related: related
    }
}

micro data_severity_is_error(severity: DataSeverity) -> bool {
    match severity {
        case Error:
            true
        case Warning:
            false
        case Info:
            false
    }
}

# 三层的统一产出：部分结果 + 诊断集合。
#
# 错误容许合同：各阶段不首错返回。即使输入损坏，也产出带 Missing/Poison
# 占位的部分结果与诊断；是否继续由后续阶段按诊断严重程度判断。
#
# 以 `unite` 承载（可区分联合的实质需求，非规避）：
# - `Fine`：结果完整（诊断至多 Warning/Info）。
# - `Partial`：结果含 Missing/Poison 占位（必有 Error 级诊断）。
# 双态让消费方不遍历诊断即可区分置信度；两者都携带值，
# 没有"无值失败"形态，也没有 panic 取用。
unite DataOutcome<T> {
    [constructor]
    Fine {
        value: T
        diagnostics: [DataDiagnostic]
    }
    [constructor]
    Partial {
        value: T
        diagnostics: [DataDiagnostic]
    }
}

micro data_outcome_of<T>(value: T) -> DataOutcome<T> {
    return Fine {
        value: value,
        diagnostics: []
    }
}

# 按诊断内容自动归位：含 Error 级诊断为 `Partial`，否则为 `Fine`。
micro data_outcome_with<T>(value: T, diagnostics: [DataDiagnostic]) -> DataOutcome<T> {
    if data_diagnostics_have_error(diagnostics) {
        return Partial {
            value: value,
            diagnostics: diagnostics
        }
    }
    return Fine {
        value: value,
        diagnostics: diagnostics
    }
}

micro data_outcome_value<T>(outcome: DataOutcome<T>) -> T {
    match outcome {
        case Fine(payload):
            payload.value
        case Partial(payload):
            payload.value
    }
}

micro data_outcome_diagnostics<T>(outcome: DataOutcome<T>) -> [DataDiagnostic] {
    match outcome {
        case Fine(payload):
            payload.diagnostics
        case Partial(payload):
            payload.diagnostics
    }
}

# 诊断集合是否含 `Error` 级（部分结果含 poison 的强信号；消费方据此决定置信度）。
micro data_diagnostics_have_error(diagnostics: [DataDiagnostic]) -> bool {
    let mut index: usize = 0
    while index < diagnostics.length() {
        if data_severity_is_error(diagnostics⁅index⁆.unwrap().severity) {
            return true
        }
        index = index + 1
    }
    return false
}

micro data_outcome_has_errors<T>(outcome: DataOutcome<T>) -> bool {
    return data_diagnostics_have_error(data_outcome_diagnostics(outcome))
}
