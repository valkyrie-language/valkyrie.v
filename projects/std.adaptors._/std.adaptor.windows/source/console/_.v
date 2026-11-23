# std.adaptor.windows: 控制台 IO
# x86-64 机器码目标经 `console.write` operator 直接写出 UTF-8 原始字节：
# 后端按冻结的数组合同把 `Utf8Text` gather 成连续字节，走 GetStdHandle + WriteFile，
# 重定向管道与控制台句柄共用同一写出通道（写出前设控制台 UTF-8 代码页）。
# STD_OUTPUT_HANDLE = -11, STD_ERROR_HANDLE = -12（GetStdHandle 伪句柄）。

namespace std.adaptor.windows.console;

[host_provider(std::console::write)]
micro print(msg: utf8): unit {
    __console_x86_64_write(-11, msg)
}

[host_provider(std::console::write_line)]
micro print_line(msg: utf8): unit {
    __console_x86_64_write(-11, msg)
    __console_x86_64_write(-11, "\n")
}

[host_provider(std::console::error_line)]
micro print_err(msg: utf8): unit {
    __console_x86_64_write(-12, msg)
}

[host_provider(std::console::read_line)]
micro read_line(): utf8 {
    return ""
}

# 机器后端冻结的控制台 operator：句柄按平台解释（Win64 伪句柄 / Linux fd），
# 消息是 `Utf8Text` 对象；空体由后端按 `console.write` 计划展开。
[x86_64_operator("console.write")]
private micro __console_x86_64_write(handle: i64, message: utf8): unit { }
