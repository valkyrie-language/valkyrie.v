namespace std.data.text.markdown;

# Local source span for Markdown text (not Valkyrie `.v` / `std.data.text.valkyrie`).
# Indices are language text offsets; `stop` is exclusive.
structure TextSpan {
    start: usize
    stop: usize
}
