namespace std.data;

# 泛型 + 递归 unite 的最小验证（DataCstNode<K> 的编译器前置），
# 兼做 span 校验的正反用例。kind 以 usize 占位：0=root，1=section。

[test]
micro test_cst_construct_and_match_round_trip() -> unit {
    let token: DataToken<usize> = new_data_token::<usize>(7, 0, 5)
    let leaf: DataCstNode<usize> = data_cst_token::<usize>(token)
    let root: DataCstNode<usize> = data_cst_node::<usize>(0, new_data_span(0, 5), [leaf])
    match root {
        case Node(payload):
            if payload.kind != 0 {
                panic("node kind mismatch")
            }
            if payload.children.length() != 1 {
                panic("node should hold one child")
            }
        case Token(payload):
            panic("root must be a node")
    }
    let span: DataSpan = data_cst_span(root)
    if span.start != 0 || span.stop != 5 {
        panic("node span mismatch")
    }
}

[test]
micro test_cst_validate_accepts_well_nested_tree() -> unit {
    let first: DataCstNode<usize> = data_cst_token::<usize>(new_data_token::<usize>(7, 0, 5))
    let second: DataCstNode<usize> = data_cst_token::<usize>(new_data_token::<usize>(8, 5, 12))
    let section: DataCstNode<usize> = data_cst_node::<usize>(1, new_data_span(0, 12), [first, second])
    let root: DataCstNode<usize> = data_cst_node::<usize>(0, new_data_span(0, 12), [section])
    let diagnostics: [DataDiagnostic] = data_cst_validate_spans(root)
    if diagnostics.length() != 0 {
        panic("well-nested tree must pass validation")
    }
}

[test]
micro test_cst_validate_flags_child_outside_parent() -> unit {
    let leaf: DataCstNode<usize> = data_cst_token::<usize>(new_data_token::<usize>(7, 3, 20))
    let root: DataCstNode<usize> = data_cst_node::<usize>(0, new_data_span(0, 10), [leaf])
    let diagnostics: [DataDiagnostic] = data_cst_validate_spans(root)
    if diagnostics.length() == 0 {
        panic("child span outside parent must be flagged")
    }
}

[test]
micro test_cst_validate_flags_malformed_span() -> unit {
    let leaf: DataCstNode<usize> = data_cst_token::<usize>(new_data_token::<usize>(7, 8, 3))
    let root: DataCstNode<usize> = data_cst_node::<usize>(0, new_data_span(0, 10), [leaf])
    let diagnostics: [DataDiagnostic] = data_cst_validate_spans(root)
    if diagnostics.length() == 0 {
        panic("malformed token span must be flagged")
    }
}
