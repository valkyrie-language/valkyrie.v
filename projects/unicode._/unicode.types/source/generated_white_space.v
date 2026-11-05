namespace unicode.types;

⍝ 自动生成，请勿手改：node scripts/gen-unicode-types.mjs
⍝ 包版本：unicode.types 0.1.0
⍝ 数据版本：Unicode 16.0.0
⍝ 来源与输入哈希：
⍝   https://www.unicode.org/Public/16.0.0/ucd/PropList.txt
⍝     SHA-256 53D614508E2A0B2305A8AA21CD60D993DE9326CDF65993660DFCCE4503548583
⍝ 覆盖范围：
⍝   White_Space 10 段 / 25 个码点（含 U+0085，不含 U+200B/U+FEFF）
⍝ 限制：`char` 是 u16，仅 BMP；White_Space 全部位于 BMP，无截断。
⍝   非 BMP 区间跳过 0 段。

⍝ `White_Space` 区间：偶数下标起点、奇数下标终点（含端点），按起点严格递增。
micro unicode_white_space_ranges() -> [char] {
    return [
        0x0009 as char, 0x000D as char, 0x0020 as char, 0x0020 as char,
        0x0085 as char, 0x0085 as char, 0x00A0 as char, 0x00A0 as char,
        0x1680 as char, 0x1680 as char, 0x2000 as char, 0x200A as char,
        0x2028 as char, 0x2029 as char, 0x202F as char, 0x202F as char,
        0x205F as char, 0x205F as char, 0x3000 as char, 0x3000 as char,
    ]
}
