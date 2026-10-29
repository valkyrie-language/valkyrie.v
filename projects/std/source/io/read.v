# std.io: read helpers
namespace std.io;

micro read_line(): utf8 {
    return std.console.read_line()
}

micro read_all(): utf8 {
    return read_file_text("")
}

micro read_char(): i32 {
    return std.console.read_char()
}

# TODO: read_int / read_f64 待 std.text 解析能力落地后实现
# 当前 stub 返回 none 以避免 to_i32/to_f64 未定义引用

micro stdin_lines(): ArrayList<utf8> {
    let mut lines: ArrayList<utf8> = ArrayList::new(0)
    let mut line: utf8 = std.io.read_line()
    while line != "" {
        lines.push(line)
        line = std.io.read_line()
    }
    return lines
}
