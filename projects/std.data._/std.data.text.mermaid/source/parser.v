namespace std.data.text.mermaid;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataToken, data_cst_node, data_cst_poison, data_cst_span, data_cst_token, data_outcome_partial};
using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};

# 语法段：token 流 -> 语句级 CST。`Newline` 为语句分隔；首条非注释语句为
# `NodeHeader`；行首连续 `Percent` 起至行尾折为 `NodeComment`；空行丢弃。
# 语句形态（v0，保守）：含 `Arrow`/`LBracket`/`SeqArrow`+`Colon` 之一或
# 首条语句即成形；其余整体挂 `Poison` 并登记 `mermaid.parse.unexpected_statement`。

micro mermaid_kind_of(node: DataCstNode<MermaidTokenKind>) -> Option<MermaidTokenKind> {
    match node {
        case Node(payload):
            return Some(payload.kind)
        else:
            return None
    }
}

micro mermaid_is_comment_line(line: [DataToken<MermaidTokenKind>]) -> bool {
    let mut index: usize = 0
    while index < line.length() {
        match line⁅index⁆.kind {
            case Space:
                index = index + 1
            case Percent:
                return true
            else:
                return false
        }
    }
    return false
}

micro mermaid_fold_tokens(line: [DataToken<MermaidTokenKind>]) -> [DataCstNode<MermaidTokenKind>] {
    let mut children: [DataCstNode<MermaidTokenKind>] = []
    let mut index: usize = 0
    while index < line.length() {
        children = push(children, data_cst_token(line⁅index⁆))
        index = index + 1
    }
    return children
}

micro mermaid_line_span(line: [DataToken<MermaidTokenKind>]) -> Span {
    return new_span(line⁅0⁆.span.start, line⁅line.length() - 1⁆.span.end)
}

micro mermaid_fold_statement(line: [DataToken<MermaidTokenKind>], ordinal: usize) -> DataCstNode<MermaidTokenKind> {
    let span: Span = mermaid_line_span(line)
    let children: [DataCstNode<MermaidTokenKind>] = mermaid_fold_tokens(line)
    if mermaid_is_comment_line(line) {
        return data_cst_node(NodeComment, span, children)
    }

    let mut has_arrow: bool = false
    let mut has_seq_arrow: bool = false
    let mut has_bracket: bool = false
    let mut has_colon: bool = false
    let mut has_text: bool = false
    let mut index: usize = 0
    while index < line.length() {
        match line⁅index⁆.kind {
            case Arrow:
                has_arrow = true
            case SeqArrow:
                has_seq_arrow = true
            case LBracket:
                has_bracket = true
            case Colon:
                has_colon = true
            case Text:
                has_text = true
            else:
                has_text = has_text
        }
        index = index + 1
    }

    let mut shaped: bool = false
    if has_text && has_arrow {
        shaped = true
    }
    if has_text && has_bracket {
        shaped = true
    }
    if has_text && has_seq_arrow && has_colon {
        shaped = true
    }
    if ordinal == 0 && has_text {
        shaped = true
    }
    if shaped {
        return data_cst_node(NodeStatement, span, children)
    }
    return data_cst_poison(span, children, "statement outside the supported mermaid subset")
}

micro mermaid_parse(tokens: [DataToken<MermaidTokenKind>], settings: DataSettings) -> DataOutcome<DataCstNode<MermaidTokenKind>> {
    let mut diagnostics: [Diagnostic] = []
    let mut statements: [DataCstNode<MermaidTokenKind>] = []
    let mut line: [DataToken<MermaidTokenKind>] = []
    let mut index: usize = 0
    while index <= tokens.length() {
        let mut at_break: bool = index == tokens.length()
        if !at_break {
            match tokens⁅index⁆.kind {
                case Newline:
                    at_break = true
                else:
                    at_break = false
            }
        }
        if at_break {
            if line.length() > 0 {
                let statement: DataCstNode<MermaidTokenKind> = mermaid_fold_statement(line, statements.length())
                let statement_kind: Option<MermaidTokenKind> = mermaid_kind_of(statement)
                let mut is_poison: bool = false
                if statement_kind.is_some() {
                    match statement_kind.unwrap() {
                        case Poison:
                            is_poison = true
                        else:
                            is_poison = false
                    }
                }
                if is_poison {
                    diagnostics = push(diagnostics, new_diagnostic("mermaid.parse.unexpected_statement", Error, "statement outside the supported mermaid subset", mermaid_line_span(line)))
                }
                statements = push(statements, statement)
            }
            line = []
        } else {
            line = push(line, tokens⁅index⁆)
        }
        index = index + 1
    }

    let mut children: [DataCstNode<MermaidTokenKind>] = []
    let mut header_done: bool = false
    let mut index2: usize = 0
    while index2 < statements.length() {
        let statement: DataCstNode<MermaidTokenKind> = statements⁅index2⁆
        let kind: Option<MermaidTokenKind> = mermaid_kind_of(statement)
        let mut is_comment: bool = false
        if kind.is_some() {
            match kind.unwrap() {
                case NodeComment:
                    is_comment = true
                else:
                    is_comment = false
            }
        }
        if !header_done && !is_comment {
            match statement {
                case Node(payload):
                    children = push(children, data_cst_node(NodeHeader, payload.span, payload.children))
                else:
                    children = push(children, statement)
            }
            header_done = true
        } else {
            children = push(children, statement)
        }
        index2 = index2 + 1
    }

    let mut span: Span = new_span(0, 0)
    if children.length() > 0 {
        span = new_span(data_cst_span(children⁅0⁆).start, data_cst_span(children⁅children.length() - 1⁆).end)
    }
    return data_outcome_partial(data_cst_node(NodeDiagram, span, children), diagnostics)
}
