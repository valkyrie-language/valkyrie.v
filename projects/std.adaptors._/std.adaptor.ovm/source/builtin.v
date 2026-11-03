# std.adaptor.ovm: VM 内置函数 [ovm] 宿主绑定
# 将 valkyrie-core 的运行时函数映射为 OVM opcode
# 无函数体 = [ovm] 声明式宿主绑定，编译器发射对 OVM runtime 宿主函数的调用

#region 输出

[ovm("println")]
micro println_i32(value: i32): i32

[ovm("println")]
private micro println_utf8(value: utf8): utf8

[ovm("print")]
micro print_i32(value: i32): i32

[ovm("print")]
private micro print_utf8(value: utf8): utf8

[host_provider(std::console::write)]
micro write(message: utf8): unit {
    print_utf8(message)
}

[host_provider(std::console::write_line)]
micro write_line(message: utf8): unit {
    println_utf8(message)
}

[host_provider(std::console::error_line)]
micro error_line(message: utf8): unit {
    println_utf8(message)
}

#endregion

#region 系统
# 墙上时钟与单调时钟是两个不同宿主通道：`get_time` 取 Unix 纪元毫秒，
# `monotonic_ms` 取进程内单调毫秒。二者不可互相顶替。

[ovm("sleep_ms")]
micro sleep_ms(ms: i32): i32

[ovm("get_time")]
private micro __get_time(): i64

[ovm("monotonic_ms")]
private micro __monotonic_ms(): i64

[host_provider(std::io::now)]
micro get_time(): i64 {
    return __get_time()
}

[host_provider(std::io::monotonic)]
micro monotonic_time(): i64 {
    return __monotonic_ms()
}

[host_provider(std::io::sleep)]
micro sleep(ms: i32): unit {
    sleep_ms(ms)
}

#endregion

#region 熵

# 全宽 64 位原始随机字：OVM 不做范围整形，均匀分布由 std 的 `Generator` 合同派生。
[ovm("random_u64")]
micro random_u64(): u64

#endregion

#region 数学

[ovm("math_sin")]
micro math_sin(x: f64): f64

[ovm("math_cos")]
micro math_cos(x: f64): f64

[ovm("math_sqrt")]
micro math_sqrt(x: f64): f64

#endregion
