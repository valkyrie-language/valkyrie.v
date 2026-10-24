# std.adaptor.nyar: 类型转换 [ovm] 宿主绑定
# 将 valkyrie-core 的类型转换映射为 NyarVM opcode
# OVM runtime 提供对应的转换宿主函数

#region 数值类型转换

[ovm("i32_to_i64")]
micro i32_to_i64(x: i32): i64

[ovm("i64_to_i32")]
micro i64_to_i32(x: i64): i32

[ovm("i32_to_f64")]
micro i32_to_f64(x: i32): f64

[ovm("f64_to_i32")]
micro f64_to_i32(x: f64): i32

[ovm("i64_to_f64")]
micro i64_to_f64(x: i64): f64

[ovm("f64_to_i64")]
micro f64_to_i64(x: f64): i64

#endregion

#region 字符串编码转换

[ovm("utf8_to_utf16")]
micro utf8_to_utf16(s: utf8): utf16

[ovm("utf16_to_utf8")]
micro utf16_to_utf8(s: utf16): utf8

[ovm("utf8_to_c_str")]
micro utf8_to_c_str(s: utf8): c_str

[ovm("c_str_to_utf8")]
micro c_str_to_utf8(s: c_str): utf8

[ovm("utf16_to_c_str")]
micro utf16_to_c_str(s: utf16): c_str

[ovm("c_str_to_utf16")]
micro c_str_to_utf16(s: c_str): utf16

#endregion

#region UTF-8 文本长度

[ovm("utf16_length")]
micro utf16_length(s: utf16): i32

[ovm("c_str_length")]
micro c_str_length(s: c_str): i32

#endregion
