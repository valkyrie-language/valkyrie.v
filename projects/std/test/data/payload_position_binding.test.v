namespace std.data;

using std.diagnostic::{Diagnostic, Span, new_span};

# 位置解构的字段类型探针。
# `case` 的 binder 按变体声明的字段顺序绑定；这里用显式类型标注在编译期断言
# 每个 binder 的静态类型与对应字段的声明类型一致，标注不符即编译失败。
micro probe_data_source_binding_types(source: DataSource) -> unit {
    match source {
        case Text(text, digest):
            let text_field: utf8 = text
            let digest_field: usize = digest
        case Bytes(bytes, digest):
            let bytes_field: [u8] = bytes
            let digest_field: usize = digest
    }
}

# `DataCstNode<K>` 的四个变体各字段声明顺序：
# `Node` 为 `kind`、`span`、`children`；`Token` 为 `token`；
# `Missing` 为 `span`、`reason`；`Poison` 为 `span`、`children`、`reason`。
micro probe_data_cst_binding_types(node: DataCstNode<usize>) -> unit {
    match node {
        case Node(kind, span, children):
            let kind_field: usize = kind
            let span_field: Span = span
            let children_field: [DataCstNode<usize>] = children
        case Token(token):
            let token_field: DataToken<usize> = token
        case Missing(span, reason):
            let span_field: Span = span
            let reason_field: utf8 = reason
        case Poison(span, children, reason):
            let span_field: Span = span
            let children_field: [DataCstNode<usize>] = children
            let reason_field: utf8 = reason
    }
}

# `DataOutcome<T>` 的字段声明顺序：`Fine` 为 `value`；
# `Partial` 为 `value`、`diagnostics`；`Failed` 为 `diagnostics`。
micro probe_data_outcome_binding_types(outcome: DataOutcome<i32>) -> unit {
    match outcome {
        case Fine(value):
            let value_field: i32 = value
        case Partial(value, diagnostics):
            let value_field: i32 = value
            let diagnostics_field: [Diagnostic] = diagnostics
        case Failed(diagnostics):
            let diagnostics_field: [Diagnostic] = diagnostics
    }
}

[test]
micro test_payload_position_binding_types() -> unit {
    let text_source: DataSource = Text {
        text: "# probe",
        digest: 1
    }
    let bytes_source: DataSource = Bytes {
        bytes: [1, 2],
        digest: 2
    }
    probe_data_source_binding_types(text_source)
    probe_data_source_binding_types(bytes_source)

    let leaf: DataCstNode<usize> = data_cst_token::<usize>(new_data_token::<usize>(7, 0, 1))
    probe_data_cst_binding_types(leaf)
    probe_data_cst_binding_types(data_cst_node::<usize>(0, new_span(0, 1), [leaf]))

    probe_data_outcome_binding_types(data_outcome_of::<i32>(7))
    probe_data_outcome_binding_types(data_outcome_failed::<i32>([]))
}
