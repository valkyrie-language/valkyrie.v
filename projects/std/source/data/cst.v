namespace std.data;

using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, diagnostic_with_related, span_is_well_formed, span_contains};

# 无损具体语法树（CST）节点。
#
# - `Node`：容器结构，`children` 保全部 token 与子结构（trivia 不丢、可回写），
#   不做任何语义裁剪；`kind` 归格式包。
# - `Token`：叶子，包裹词法 token。
# - `Missing`：结构应有而源缺席的占位（如未闭合 fence 的闭合标记），
#   零宽或极小 span；恢复时插入，标记"此处应有结构"。
# - `Poison`：内容损坏但字节完整保留的容器（如同步点间被丢弃的 token 序列），
#   `children` 保留被丢弃内容（无损），标记"语义不可信"。
# `Missing`/`Poison` 是语法结构事实，不挂严重程度级别字段。
# span 为绝对偏移（半开区间），并刻意重复存储：
# 不可变树上相对长度需要遍历还原，反而更糟，不做那种"优化"。
unite DataCstNode<K> {
    [constructor]
    Node {
        kind: K
        span: Span
        children: [DataCstNode<K>]
    }
    [constructor]
    Token {
        token: DataToken<K>
    }
    [constructor]
    Missing {
        span: Span
        reason: utf8
    }
    [constructor]
    Poison {
        span: Span
        children: [DataCstNode<K>]
        reason: utf8
    }
}

micro data_cst_token<K>(token: DataToken<K>) -> DataCstNode<K> {
    return Token {
        token: token
    }
}

micro data_cst_node<K>(kind: K, span: Span, children: [DataCstNode<K>]) -> DataCstNode<K> {
    return Node {
        kind: kind,
        span: span,
        children: children
    }
}

# 缺失占位：结构应有而源缺席。
micro data_cst_missing<K>(span: Span, reason: utf8) -> DataCstNode<K> {
    return Missing {
        span: span,
        reason: reason
    }
}

# 污染占位：内容损坏但全部字节保留在 `children`。
micro data_cst_poison<K>(span: Span, children: [DataCstNode<K>], reason: utf8) -> DataCstNode<K> {
    return Poison {
        span: span,
        children: children,
        reason: reason
    }
}

# 节点自身 span。
# 位置解构按声明顺序绑定：`Node` 为 `kind`、`span`、`children`；
# `Missing` 为 `span`、`reason`；`Poison` 为 `span`、`children`、`reason`。
micro data_cst_span<K>(node: DataCstNode<K>) -> Span {
    match node {
        case Node(kind, span, children):
            span
        case Token(token):
            token.span
        case Missing(span, reason):
            span
        case Poison(span, children, reason):
            span
    }
}

# 子节点 span 是否全部落在本节点 span 内（含形态合法性）。
micro data_cst_children_within<K>(span: Span, children: [DataCstNode<K>]) -> bool {
    let mut index: usize = 0
    while index < children.length() {
        let child_span: Span = data_cst_span(children⁅index⁆)
        if !span_contains(span, child_span) {
            return false
        }
        index = index + 1
    }
    return true
}

# 递归校验整棵树：每个节点 span 形态合法，且所有后代 span 落在祖先 span 内。
# 返回诊断列表，空列表即通过；子树越界属于结构问题，在构建期暴露，不留给消费端。
# 校验本身是错误容许的：聚合全部越界与非法形态，不在第一个问题上停。
micro data_cst_validate_spans<K>(node: DataCstNode<K>) -> [Diagnostic] {
    match node {
        case Node(kind, span, children):
            validate_node_spans(span, children)
        case Token(token):
            validate_token_span(token.span)
        case Missing(span, reason):
            validate_token_span(span)
        case Poison(span, children, reason):
            validate_node_spans(span, children)
    }
}

micro validate_token_span(span: Span) -> [Diagnostic] {
    let mut diagnostics: ArrayList<Diagnostic> = ArrayList::new(0)
    if !span_is_well_formed(span) {
        diagnostics.push(new_diagnostic("std.data.cst.malformed_span", Error, "span 形态非法：end 早于 start", span))
    }
    return diagnostics.to_array()
}

micro validate_node_spans<K>(span: Span, children: [DataCstNode<K>]) -> [Diagnostic] {
    let mut diagnostics: ArrayList<Diagnostic> = ArrayList::new(0)
    if !span_is_well_formed(span) {
        diagnostics.push(new_diagnostic("std.data.cst.malformed_span", Error, "节点 span 形态非法：end 早于 start", span))
    }
    let mut index: usize = 0
    while index < children.length() {
        let child: DataCstNode<K> = children⁅index⁆
        let child_span: Span = data_cst_span(child)
        if !span_contains(span, child_span) {
            diagnostics.push(diagnostic_with_related("std.data.cst.span_escape", Error, "子节点 span 越出父节点 span", child_span, span))
        }
        let child_diagnostics: [Diagnostic] = data_cst_validate_spans(child)
        let mut inner: usize = 0
        while inner < child_diagnostics.length() {
            diagnostics.push(child_diagnostics⁅inner⁆)
            inner = inner + 1
        }
        index = index + 1
    }
    return diagnostics.to_array()
}
