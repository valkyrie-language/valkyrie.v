namespace template;

# HTML 转义：插值默认出口。映射表（与宿主无关的合同）：
# `&` → `&amp;`，`<` → `&lt;`，`>` → `&gt;`，`"` → `&quot;`，`'` → `&#x27;`。
# 逐字符扫描，非命中字符按 span 切回原样（无损）。
micro template_escape_html(text: utf8) -> utf8 {
    let mut output: utf8 = ""
    let length: usize = text.length()
    let mut index: usize = 0
    while index < length {
        let c: char = text⁅index⁆
        if c == '&' {
            output = output + "&amp;"
        }
        else if c == '<' {
            output = output + "&lt;"
        }
        else if c == '>' {
            output = output + "&gt;"
        }
        else if c == '"' {
            output = output + "&quot;"
        }
        else if c == '\'' {
            output = output + "&#x27;"
        }
        else {
            output = output + text.slice(index, 1)
        }
        index = index + 1
    }
    return output
}
