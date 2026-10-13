namespace std.text;

⍝ 将模板中的字符串占位符替换为给定文本；占位符属于格式数据，不参与编译器语义分派。
micro format(template: utf8, argument: utf8): utf8 {
    return template.replace("{}", argument)
}
