namespace core::types;

⍝ 连续区间：半开 `[start, end)` 字节/索引范围。
structure Range {
    start: usize,
    end: usize,
}
