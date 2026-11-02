namespace std.data;

# 无损具体语法树（CST）节点。
#
# - `Node`：容器结构，`children` 保全部 token 与子结构（trivia 不丢、可回写），
#   不做任何语义裁剪；`kind` 归格式包（`unite`）。
# - `Token`：叶子，包裹词法 token。
# - `Missing`：结构应有而源缺席的占位（如未闭合 fence 的闭合标记），
#   零宽或极小 span；恢复时插入，标记"此处应有结构"。
# - `Poison`：内容损坏但字节完整保留的容器（如同步点间被丢弃的 token 序列），
#   `children` 保留被丢弃内容（无损），标记"语义不可信"。
# span 为绝对偏移（`stop` 开区间），并刻意重复存储：
# 不可变树上相对长度需要遍历还原，反而更糟，不做那种"优化"。
unite DataCstNode<K> {
    [constructor]
    Node {
        kind: K
        span: DataSpan
        children: [DataCstNode<K>]
    }
    [constructor]
    Token {
        token: DataToken<K>
    }
    [constructor]
    Missing {
        span: DataSpan
        reason: utf8
    }
    [constructor]
    Poison {
        span: DataSpan
        children: [DataCstNode<K>]
        reason: utf8
    }
}

micro data_cst_token<K>(token: DataToken<K>) -> DataCstNode<K> {
    return Token {
        token: token
    }
}

micro data_cst_node<K>(kind: K, span: DataSpan, children: [DataCstNode<K>]) -> DataCstNode<K> {
    return Node {
        kind: kind,
        span: span,
        children: children
    }
}

# 缺失占位：结构应有而源缺席。
micro data_cst_missing<K>(span: DataSpan, reason: utf8) -> DataCstNode<K> {
    return Missing {
        span: span,
        reason: reason
    }
}

# 污染占位：内容损坏但全部字节保留在 `children`。
micro data_cst_poison<K>(span: DataSpan, children: [DataCstNode<K>], reason: utf8) -> DataCstNode<K> {
    return Poison {
        span: span,
        children: children,
        reason: reason
    }
}

# 节点自身 span。
micro data_cst_span<K>(node: DataCstNode<K>) -> DataSpan {
    match node {
        case Node(payload):
            payload.span
        case Token(payload):
            payload.token.span
        case Missing(payload):
            payload.span
        case Poison(payload):
            payload.span
    }
}

# 子节点 span 是否全部落在本节点 span 内（含形态合法性）。
micro data_cst_children_within<K>(span: DataSpan, children: [DataCstNode<K>]) -> bool {
    let mut index: usize = 0
    while index < children.length() {
        let child_span: DataSpan = data_cst_span(children⁅index⁆.unwrap())
        if !data_span_contains(span, child_span) {
            return false
        }
        index = index + 1
    }
    return true
}

# 递归校验整棵树：每个节点 span 形态合法，且所有后代 span 落在祖先 span 内。
# 返回诊断列表，空列表即通过；子树越界属于结构问题，在构建期暴露，不留给消费端。
# 校验本身是错误容许的：聚合全部越界与非法形态，不在第一个问题上停。
micro data_cst_validate_spans<K>(node: DataCstNode<K>) -> [DataDiagnostic] {
    match node {
        case Node(payload):
            validate_node_spans(payload.span, payload.children)
        case Token(payload):
            validate_token_span(payload.token.span)
        case Missing(payload):
            validate_token_span(payload.span)
        case Poison(payload):
            validate_node_spans(payload.span, payload.children)
    }
}

micro validate_token_span(span: DataSpan) -> [DataDiagnostic] {
    let mut diagnostics: [DataDiagnostic] = []
    if !data_span_is_well_formed(span) {
        diagnostics = push(diagnostics, new_data_diagnostic("std.data.cst.malformed_span", Error, "span 形态非法：stop 早于 start", span))
    }
    return diagnostics
}

micro validate_node_spans<K>(span: DataSpan, children: [DataCstNode<K>]) -> [DataDiagnostic] {
    let mut diagnostics: [DataDiagnostic] = []
    if !data_span_is_well_formed(span) {
        diagnostics = push(diagnostics, new_data_diagnostic("std.data.cst.malformed_span", Error, "节点 span 形态非法：stop 早于 start", span))
    }
    let mut index: usize = 0
    while index < children.length() {
        let child: DataCstNode<K> = children⁅index⁆.unwrap()
        let child_span: DataSpan = data_cst_span(child)
        if !data_span_contains(span, child_span) {
            diagnostics = push(diagnostics, data_diagnostic_with_related("std.data.cst.span_escape", Error, "子节点 span 越出父节点 span", child_span, span))
        }
        let child_diagnostics: [DataDiagnostic] = data_cst_validate_spans(child)
        let mut inner: usize = 0
        while inner < child_diagnostics.length() {
            diagnostics = push(diagnostics, child_diagnostics⁅inner⁆.unwrap())
            inner = inner + 1
        }
        index = index + 1
    }
    return diagnostics
}
