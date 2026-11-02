namespace weave.preview;

using std.data::{DataOutcome};
using std.data.text.markdown::{markdown_render_html};

# 预览驱动：消费方独立导出函数，把端到端链路的渲染结果经 wasm 会话导出。
# fixture 样本：标题/表格/脚注/flowchart/分式，与 `std.data.text.markdown` fixture 同源。

micro preview_fixture_source() -> utf8 {
    return "# Guide\n\nIntro **bold** $x^{2}$ end.\n\n| Name | Value |\n| --- | --- |\n| a | 1 |\n\nNote ref[^n1].\n\n[^n1]: note text\n\n```mermaid\ngraph TD\nA[Start] --> B[End]\n```\n\n$$\n\\frac{1}{x}\n$$\n"
}

[export]
micro render_fixture() -> utf8 {
    let outcome: DataOutcome<utf8> = markdown_render_html(preview_fixture_source())
    match outcome {
        case Fine(payload):
            return payload.value
        case Partial(payload):
            return payload.value
        case Failed(payload):
            return "FAILED: " + payload.diagnostics⁅0⁆.code
    }
}
