namespace std.data.text.markdown;

# Local source span for Markdown text (not Valkyrie `.v` / `std.data.text.valkyrie`).
# Indices are language text offsets; `stop` is exclusive.
structure TextSpan {
    start: usize
    stop: usize
}

structure MarkdownDiagnostic {
    message: utf8
    span: TextSpan
}

[tag(MarkdownParseResultKind)]
unite MarkdownParseResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: MarkdownDiagnostic }
}

micro new_markdown_diagnostic(message: utf8, start: usize, stop: usize) -> MarkdownDiagnostic {
    return MarkdownDiagnostic {
        message: message,
        span: TextSpan {
            start: start,
            stop: stop
        }
    }
}
