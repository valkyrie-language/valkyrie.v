namespace std.data.text.mermaid;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, DataToken, data_cst_missing, data_outcome_diagnostics, data_outcome_failed, data_outcome_partial, data_outcome_value_or, data_source_from_text, new_data_settings};
using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};
using document.plot::{PlotDecl, PlotEdge, plot_decl, plot_edge};

# 语义段：CST -> `MermaidDiagram`。词素按 span 从源切回。
# header 决定图类（`graph TD/TB`、`flowchart TD/TB`、`sequenceDiagram`）；
# 不支持的 header 记 `mermaid.build.unsupported_header` 并 `Failed`。
# 语句级失败在语法段已登记；builder 对 `Poison` 子树跳过不补。
# 节点登记：首次出现定身份；带标签规格后写覆盖标签。

structure MermaidBuildState {
    text: utf8
    diagnostics: [Diagnostic]
}

micro mermaid_lexeme(state: MermaidBuildState, span: Span) -> utf8 {
    return state.text.slice(span.start, span.end - span.start)
}

micro mermaid_diagnose(state: MermaidBuildState, code: utf8, message: utf8, span: Span) -> MermaidBuildState {
    return MermaidBuildState {
        text: state.text,
        diagnostics: push(state.diagnostics, new_diagnostic(code, Error, message, span))
    }
}

# 语句 token 的可见词素拼接（`Space` 折叠为单个空格）。
micro mermaid_join_lexemes(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> utf8 {
    let mut out: utf8 = ""
    let mut spaced: bool = false
    let mut index: usize = 0
    while index < tokens.length() {
        match tokens⁅index⁆.kind {
            case Space:
                spaced = true
            else:
                if out.length() > 0 && spaced {
                    out = out + " "
                }
                out = out + mermaid_lexeme(state, tokens⁅index⁆.span)
                spaced = false
        }
        index = index + 1
    }
    return out
}

structure MermaidStatementWords {
    words: [utf8]
}

# 语句的 `Text` 片段列表（忽略其他 token）。
micro mermaid_text_words(tokens: [DataToken<MermaidTokenKind>], state: MermaidBuildState) -> [utf8] {
    let mut out: [utf8] = []
    let mut index: usize = 0
    while index < tokens.length() {
        match tokens⁅index⁆.kind {
            case Text:
                out = push(out, mermaid_lexeme(state, tokens⁅index⁆.span))
            else:
                out = out
        }
        index = index + 1
    }
    return out
}

micro mermaid_statement_tokens(node: DataCstNode<MermaidTokenKind>) -> [DataToken<MermaidTokenKind>] {
    match node {
        case Node(payload):
            let mut out: [DataToken<MermaidTokenKind>] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                match payload.children⁅index⁆ {
                    case Token(leaf):
                        out = push(out, leaf.token)
                    else:
                        out = out
                }
                index = index + 1
            }
            return out
        case Poison(payload):
            let mut out: [DataToken<MermaidTokenKind>] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                match payload.children⁅index⁆ {
                    case Token(leaf):
                        out = push(out, leaf.token)
                    else:
                        out = out
                }
                index = index + 1
            }
            return out
        else:
            return []
    }
}
