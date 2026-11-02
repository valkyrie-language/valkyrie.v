namespace std.data.text.markdown;

using std.data::{DataOutcome, data_outcome_partial};
using std.diagnostic::{Diagnostic, Warning, new_diagnostic, new_span};

# Markdown 词法分析：源文本 -> token 流（`MarkdownToken`）。
# 只认词法：同类连续字符合并为一个 token，每个字符恰好属于一个 token（无损）。
# 未闭合配对、结构语义一律留给 parser；本层不做任何语义判断。
#
# 错误容许：非法码位产出 `Illegal` token（span 保留原字节）并继续扫描，
# 同时登记 `markdown.lex.illegal_code_point`（Warning）诊断；
# 不停在第一个非法单元，也不静默吞掉它。
#
# 数字码位全部为 ASCII 十进制，逐处标注对应字符；待字符/字节字面量
# （`'c'` / `b'c'`，含转义与类型提升）落地后机械改回字面量形式，
# 不得用查表、十六进制或预计算布尔替代。

# 32=' '（空格），9='\t'（制表符）。待字面量：`code_point == ' ' || code_point == '\t'`
micro is_space_code_point(code_point: u32) -> bool {
    return code_point == 32 || code_point == 9
}

# 35='#'，96='`'，126='~'，42='*'，95='_'，61='='。待字面量：逐一对照字符形式。
micro is_run_marker_code_point(code_point: u32) -> bool {
    return code_point == 35 || code_point == 96 || code_point == 126
        || code_point == 42 || code_point == 95 || code_point == 61
}

# 分派对照：35='#'->Hash，96='`'->Backtick，126='~'->Tilde，42='*'->Asterisk，
# 95='_'->Underscore，61='='->Equals。待字面量。
micro run_marker_kind(code_point: u32) -> MarkdownTokenKind {
    if code_point == 35 {
        return Hash
    }
    if code_point == 96 {
        return Backtick
    }
    if code_point == 126 {
        return Tilde
    }
    if code_point == 42 {
        return Asterisk
    }
    if code_point == 95 {
        return Underscore
    }
    return Equals
}

# 91='['，93=']'，40='('，41=')'，60='<'，62='>'，45='-'，43='+'，124='|'，58=':'。待字面量。
micro is_punctuation_code_point(code_point: u32) -> bool {
    return code_point == 91 || code_point == 93 || code_point == 40 || code_point == 41
        || code_point == 60 || code_point == 62 || code_point == 45 || code_point == 43
        || code_point == 124 || code_point == 58
}

micro punctuation_kind(code_point: u32) -> MarkdownTokenKind {
    if code_point == 91 {
        return BracketOpen
    }
    if code_point == 93 {
        return BracketClose
    }
    if code_point == 40 {
        return ParenOpen
    }
    if code_point == 41 {
        return ParenClose
    }
    if code_point == 60 {
        return AngleOpen
    }
    if code_point == 62 {
        return AngleClose
    }
    if code_point == 45 {
        return Minus
    }
    if code_point == 43 {
        return Plus
    }
    if code_point == 124 {
        return Pipe
    }
    return Colon
}

micro is_text_code_point(code_point: u32) -> bool {
    # 32=' '：控制字符不是文本。待字面量：`code_point < ' '`
    if code_point < 32 {
        return false
    }
    if is_space_code_point(code_point) {
        return false
    }
    if is_run_marker_code_point(code_point) {
        return false
    }
    if is_punctuation_code_point(code_point) {
        return false
    }
    return true
}

# 0 基码点索引：`⁅ ⁆` 直接给出 `char`，转 `u32` 即码点值。
micro code_point_at(source: utf8, index: usize) -> u32 {
    return source⁅index⁆ as u32
}

micro markdown_lex(source: utf8) -> DataOutcome<[MarkdownToken]> {
    let mut tokens: [MarkdownToken] = []
    let mut diagnostics: [Diagnostic] = []
    let length: usize = source.length()
    let mut index: usize = 0
    while index < length {
        let code_point: u32 = code_point_at(source, index)
        # 13='\r'，10='\n'。待字面量：`code_point == '\r' || code_point == '\n'`
        if code_point == 13 || code_point == 10 {
            let mut stop: usize = index + 1
            if code_point == 13 && index + 1 < length {
                if code_point_at(source, index + 1) == 10 {
                    stop = index + 2
                }
            }
            tokens = push(tokens, new_markdown_token(Newline, index, stop))
            index = stop
        }
        else if is_space_code_point(code_point) {
            let mut stop: usize = index
            while stop < length {
                if !is_space_code_point(code_point_at(source, stop)) {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(Whitespace, index, stop))
            index = stop
        }
        else if is_run_marker_code_point(code_point) {
            let mut stop: usize = index
            while stop < length {
                if code_point_at(source, stop) != code_point {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(run_marker_kind(code_point), index, stop))
            index = stop
        }
        else if is_punctuation_code_point(code_point) {
            tokens = push(tokens, new_markdown_token(punctuation_kind(code_point), index, index + 1))
            index = index + 1
        }
        # 32=' '：小于空格码位的不可见控制字符归为非法。待字面量：`code_point < ' '`
        else if code_point < 32 {
            tokens = push(tokens, new_markdown_token(Illegal, index, index + 1))
            diagnostics = push(diagnostics, new_diagnostic("markdown.lex.illegal_code_point", Warning, "不可见控制字符", new_span(index, index + 1)))
            index = index + 1
        }
        else {
            let mut stop: usize = index
            while stop < length {
                if !is_text_code_point(code_point_at(source, stop)) {
                    break
                }
                stop = stop + 1
            }
            tokens = push(tokens, new_markdown_token(Text, index, stop))
            index = stop
        }
    }
    return data_outcome_partial(tokens, diagnostics)
}
