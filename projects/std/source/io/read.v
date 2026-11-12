# std.io: 标准输入薄委托。
namespace std.io;

# 本层只把 `std.console` 的行/字符读取原样委托出去；输入终态的编码口径
# （空行与输入结束的区分、字符码的缺席表示）由 `std.console` 的合同决定，
# std.io 不在此处替它发明哨兵，也不提供把失败折叠成空串的整读占位。
#
# 需要「按行取到输入结束为止」这类可判定终态的输入流时，正确入口是
# `std.console` 给出类型化的行流合同；在该合同交付之前，std.io 不承载
# 以空串充当结束哨兵的循环。

micro read_line(): utf8 {
    return std.console.read_line()
}

micro read_char(): i32 {
    return std.console.read_char()
}
