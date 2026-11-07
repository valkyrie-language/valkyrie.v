namespace std.data;

using std.diagnostic::{Diagnostic, Error, Span, severity_is_error};

# 三层的统一产出：三态，值域互不重叠。
#
# - `Fine { value }`：结果完整，不带诊断字段——Fine 不是"恰好空诊断的 Partial"，
#   三态都挂诊断就等于没分。
# - `Partial { value, diagnostics }`：有值且诊断非空（至少一条）；值含
#   Missing/Poison 占位或降级结果，消费者可继续用值。"是否算严重"由
#   `Diagnostic.severity` 现算，不另存级别字段。
# - `Failed { diagnostics }`：确实产不出可用值；诊断至少一条且应含 `Error` 级。
#   只有这一态表示"无值"，其余情况一律不许首错返回。
#
# 错误容许合同：各阶段不首错返回。即使输入损坏，也产出带 Missing/Poison
# 占位的部分结果与诊断；是否继续由后续阶段按诊断严重程度判断。
unite DataOutcome<T> {
    [constructor]
    Fine {
        value: T
    }
    [constructor]
    Partial {
        value: T
        diagnostics: [Diagnostic]
    }
    [constructor]
    Failed {
        diagnostics: [Diagnostic]
    }
}

# 完整结果（无诊断）。
micro data_outcome_of<T>(value: T) -> DataOutcome<T> {
    return Fine {
        value: value
    }
}

# 部分结果：诊断非空才构成 `Partial`；调用方传空诊断列表时归位 `Fine`，
# 不产"空诊断的 Partial"（三态值域互不重叠的纪律）。
micro data_outcome_partial<T>(value: T, diagnostics: [Diagnostic]) -> DataOutcome<T> {
    if diagnostics.length() == 0 {
        return Fine {
            value: value
        }
    }
    return Partial {
        value: value,
        diagnostics: diagnostics
    }
}

# 无值失败：调用点保证诊断非空且至少一条 `Error` 级——只有"确实产不出
# 可用值"才允许走这一态，其余情况一律带值走 `Partial`。
micro data_outcome_failed<T>(diagnostics: [Diagnostic]) -> DataOutcome<T> {
    return Failed {
        diagnostics: diagnostics
    }
}

# 位置解构按声明顺序绑定：`Partial` 为 `value`、`diagnostics`；`Failed` 为 `diagnostics`。
micro data_outcome_diagnostics<T>(outcome: DataOutcome<T>) -> [Diagnostic] {
    match outcome {
        case Fine(value):
            []
        case Partial(value, diagnostics):
            diagnostics
        case Failed(diagnostics):
            diagnostics
    }
}

# 取值（带回退）：`Failed` 无值，返回调用方给的缺省；需要区分缺省来源的
# 消费方自行 match，不提供 panic 取用。
# 位置解构按声明顺序绑定：`Fine`/`Partial` 的首字段均为 `value`。
micro data_outcome_value_or<T>(outcome: DataOutcome<T>, fallback: T) -> T {
    match outcome {
        case Fine(value):
            value
        case Partial(value, diagnostics):
            value
        case Failed(diagnostics):
            fallback
    }
}

# 诊断码访问器（迁移自旧契约层，签名保持一致）。
micro data_diagnostic_code(diagnostic: Diagnostic) -> utf8 {
    return diagnostic.code
}

# 诊断主位置访问器（迁移自旧契约层，签名保持一致）。
micro data_diagnostic_span(diagnostic: Diagnostic) -> Span {
    return diagnostic.span
}

# 诊断集合是否含 `Error` 级（部分结果含 poison 的强信号；消费方据此决定置信度）。
micro data_diagnostics_have_error(diagnostics: [Diagnostic]) -> bool {
    let mut index: usize = 0
    while index < diagnostics.length() {
        if severity_is_error(diagnostics⁅index⁆.severity) {
            return true
        }
        index = index + 1
    }
    return false
}

# 是否有 `Error` 级问题：`Fine` 无诊断恒 false；`Failed` 恒 true（合同保证含
# Error 级）；`Partial` 现算诊断严重程度，不另存级别字段。
# 位置解构按声明顺序绑定：`Partial` 的第二个字段是 `diagnostics`。
micro data_outcome_has_errors<T>(outcome: DataOutcome<T>) -> bool {
    match outcome {
        case Fine(value):
            false
        case Partial(value, diagnostics):
            data_diagnostics_have_error(diagnostics)
        case Failed(diagnostics):
            true
    }
}
