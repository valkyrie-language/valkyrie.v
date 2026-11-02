namespace std.data;

# 源单元偏移对，`stop` 为开区间。
# 文本格式的源单元是字符，二进制格式的源单元是字节；
# 公共层不解释单位语义，由格式包各自注明。
structure DataSpan {
    start: usize
    stop: usize
}

micro new_data_span(start: usize, stop: usize) -> DataSpan {
    return DataSpan {
        start: start,
        stop: stop
    }
}

# span 是否形态合法（`stop` 不早于 `start`）。
micro data_span_is_well_formed(span: DataSpan) -> bool {
    return span.stop >= span.start
}

# `child` 是否完整落在 `parent` 内（两端均为开区间语义）。
micro data_span_contains(parent: DataSpan, child: DataSpan) -> bool {
    if !data_span_is_well_formed(parent) {
        return false
    }
    if !data_span_is_well_formed(child) {
        return false
    }
    return child.start >= parent.start && child.stop <= parent.stop
}

# span 长度；形态非法时按 0 处理，不产生负值。
micro data_span_length(span: DataSpan) -> usize {
    if span.stop < span.start {
        return 0
    }
    return span.stop - span.start
}
