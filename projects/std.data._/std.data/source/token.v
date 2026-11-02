namespace std.data;

# 词法层统一 token 形态：kind 归格式包（`unite`），公共层只约束带 span。
# 词素不重复存放，按 span 从源切回（无损）。
structure DataToken<K> {
    kind: K
    span: DataSpan
}

micro new_data_token<K>(kind: K, start: usize, stop: usize) -> DataToken<K> {
    return DataToken {
        kind: kind,
        span: new_data_span(start, stop)
    }
}
