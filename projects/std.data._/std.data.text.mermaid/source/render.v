namespace std.data.text.mermaid;

using std.data::{DataCstNode, DataOutcome, DataSource, DataToken, data_cst_missing, data_outcome_diagnostics, data_outcome_value_or, data_source_from_text, new_data_settings};
using std.diagnostic::{Diagnostic, new_span};
using document.plot::{plot_emit_svg, plot_flowchart, plot_sequence_full, plot_sequence_spec};

# 便捷管线：源文本 -> SVG（解析三段 + 布局 + 发射；诊断跨段聚合）。

micro mermaid_render_svg(text: utf8) -> DataOutcome<utf8> {
    let settings: DataSettings = new_data_settings(64, 0)
    let source: DataSource = data_source_from_text(text)
    let lexed: DataOutcome<[DataToken<MermaidTokenKind>]> = mermaid_lex(source, settings)
    let mut diagnostics: [Diagnostic] = data_outcome_diagnostics(lexed)
    let tokens: [DataToken<MermaidTokenKind>] = data_outcome_value_or(lexed, [])
    let parsed: DataOutcome<DataCstNode<MermaidTokenKind>> = mermaid_parse(tokens, settings)
    diagnostics = mermaid_concat_diagnostics(diagnostics, data_outcome_diagnostics(parsed))
    let cst: DataCstNode<MermaidTokenKind> = data_outcome_value_or(parsed, data_cst_missing(new_span(0, 0), "parse failed"))
    let built: DataOutcome<MermaidDiagram> = mermaid_build(cst, source, settings)
    diagnostics = mermaid_concat_diagnostics(diagnostics, data_outcome_diagnostics(built))
    match built {
        case Fine(payload):
            return data_outcome_partial(mermaid_emit(payload.value), diagnostics)
        case Partial(payload):
            return data_outcome_partial(mermaid_emit(payload.value), diagnostics)
        case Failed(payload):
            return data_outcome_failed(diagnostics)
    }
}

micro mermaid_emit(diagram: MermaidDiagram) -> utf8 {
    match diagram {
        case MermaidFlowchart(payload):
            return plot_emit_svg(plot_flowchart(payload.nodes, payload.edges))
        case MermaidSequence(payload):
            return plot_emit_svg(plot_sequence_full(plot_sequence_spec(payload.participants, payload.events)))
    }
}

micro mermaid_concat_diagnostics(first: [Diagnostic], second: [Diagnostic]) -> [Diagnostic] {
    let mut out: [Diagnostic] = first
    let mut index: usize = 0
    while index < second.length() {
        out = push(out, second⁅index⁆)
        index = index + 1
    }
    return out
}
