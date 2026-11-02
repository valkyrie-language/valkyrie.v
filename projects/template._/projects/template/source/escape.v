namespace template;

# HTML 转义：插值默认出口。映射表（与宿主无关的合同）：
# 38='&' → `&amp;`，60='<' → `&lt;`，62='>' → `&gt;`，34='"' → `&quot;`，39='\'' → `&#x27;`。
# 逐码点扫描，非命中码位按 span 切回原样（无损）。
micro template_escape_html(text: utf8) -> utf8 {
    let mut output: utf8 = ""
    let length: usize = text.length()
    let mut index: usize = 0
    while index < length {
        let code_point: u32 = text⁅index⁆ as u32
        if code_point == 38 {
            output = output + "&amp;"
        }
        else if code_point == 60 {
            output = output + "&lt;"
        }
        else if code_point == 62 {
            output = output + "&gt;"
        }
        else if code_point == 34 {
            output = output + "&quot;"
        }
        else if code_point == 39 {
            output = output + "&#x27;"
        }
        else {
            output = output + text.slice(index, 1)
        }
        index = index + 1
    }
    return output
}
