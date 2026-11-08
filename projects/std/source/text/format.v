namespace std.text;

# `Display` 的整数/布尔/字符/文本实现，以及 `format` 的声明层重载。
#
# 口径：
# - `{}` 槽位只调 `display()`，但槽位本身只有 `{}` 一种形态；宽度、精度、命名参数
#   与转义都不在 v1 范围。
# - 渲染实现只有一份：`Utf8Text` 的 `Template<[utf8]>` impl；`format` 只做「逐参
#   `display()` + 取 `render` 的 `Fine`」，不另建第二套替换逻辑。
# - 模板是运行时文本，槽位数与实参数不一致属于调用方缺陷：`format` 直接
#   `unwrap()`，把 `TemplateError` 交给 `panic`。
# - 整数十进制、`bool`、`char`、`utf8` 全部纯 V，零 host 依赖。
# - `usize` / `isize` 是目标别名，不单独写 impl；覆盖由别名目标类型（`u64` /
#   `i64` 或 32 位目标上的 `u32` / `i32`）的 impl 继承。
# - `i128` / `u128` 暂缺：std 尚未声明这两种宽度的算术与比较算子，无法在 V 层
#   做十进制拆分，故不写「假装能显示」的实现。
# - 浮点（`f32` / `f64`）在 `float_display.v`：位模式经 `to_bits` 拆分指数与
#   尾数，最短可回读十进制按精确算术逐位产出；不以每目标 host 原语替代。

imply Utf8Text: Display {
    micro display(self): utf8 {
        return self
    }
}

imply bool: Display {
    micro display(self): utf8 {
        if self {
            return "true"
        }

        return "false"
    }
}

imply char: Display {
    micro display(self): utf8 {
        return encode_char_as_utf8(self)
    }
}

# 无符号十进制：逐位取余后倒序拼字节，不做本地化、不加前导零。
private micro decimal_u64(value: u64) -> utf8 {
    if value == 0 {
        let zero: [u8] = [48]
        return Utf8Text::from_bytes(zero)
    }

    let mut digits: ArrayList<u8> = ArrayList::new(20)
    let mut rest: u64 = value
    while rest > 0 {
        digits.push(48 + (rest % 10) as u8)
        rest = rest / 10
    }

    let mut bytes: ArrayList<u8> = ArrayList::new(digits.length())
    let mut index: usize = digits.length()
    while index > 0 {
        index = index - 1
        bytes.push(digits⁅index⁆)
    }

    return Utf8Text::from_bytes(bytes.to_array())
}

# 有符号十进制：负号单独写入，绝对值按 `u64` 走。最小负数不能直接取负，
# 先抬到 `value + 1` 再取负，避开了 `-MIN` 的溢出。
private micro decimal_i64(value: i64) -> utf8 {
    if value >= 0 {
        return decimal_u64(value as u64)
    }

    let lifted: i64 = value + 1
    let magnitude: u64 = ((-lifted) as u64) + 1
    return "-" + decimal_u64(magnitude)
}

imply i8: Display {
    micro display(self): utf8 {
        return decimal_i64(self as i64)
    }
}

imply i16: Display {
    micro display(self): utf8 {
        return decimal_i64(self as i64)
    }
}

imply i32: Display {
    micro display(self): utf8 {
        return decimal_i64(self as i64)
    }
}

imply i64: Display {
    micro display(self): utf8 {
        return decimal_i64(self)
    }
}

imply u8: Display {
    micro display(self): utf8 {
        return decimal_u64(self as u64)
    }
}

imply u16: Display {
    micro display(self): utf8 {
        return decimal_u64(self as u64)
    }
}

imply u32: Display {
    micro display(self): utf8 {
        return decimal_u64(self as u64)
    }
}

imply u64: Display {
    micro display(self): utf8 {
        return decimal_u64(self)
    }
}

# 唯一渲染入口：模板文本自身就是渲染载体，实参是已 `display()` 的文本序列。
# 槽位只认 `{}`；孤立 `{` / `}` 报 `InvalidSyntax`，实参数不符报 `ArgumentMismatch`。
imply Utf8Text: Template<[utf8]> {
    micro render(self, arguments: [utf8]): Result<utf8, TemplateError> {
        let size: usize = self.byte_length()
        let mut out: Utf8Builder = Utf8Builder::new(size)
        let mut cursor: usize = 0
        let mut slot: usize = 0
        while cursor < size {
            let current: char = self.character_at_byte(cursor)
            if current == '{' {
                if cursor + 1 >= size {
                    return Fail { error: InvalidSyntax { offset: cursor } }
                }

                let closing: char = self.character_at_byte(cursor + 1)
                if closing != '}' {
                    return Fail { error: InvalidSyntax { offset: cursor } }
                }

                if slot >= arguments.length() {
                    return Fail { error: ArgumentMismatch { expected: arguments.length(), actual: slot + 1 } }
                }

                out.append(arguments⁅slot⁆)
                slot = slot + 1
                cursor = cursor + 2
            }
            else if current == '}' {
                return Fail { error: InvalidSyntax { offset: cursor } }
            }
            else {
                out.append(current)
                cursor = cursor + self.char_width_at(cursor)
            }
        }

        if slot != arguments.length() {
            return Fail { error: ArgumentMismatch { expected: arguments.length(), actual: slot } }
        }

        let value: utf8 = out.build()
        return Fine { value: value }
    }
}

# `format` 是 `Template::render` 的声明层糖：arity 1–3 各一个重载，
# 编译器不出现任何 `format` 特判或内建。
micro format<A>(template: utf8, first: A) -> utf8
    where A: Display
{
    let arguments: [utf8] = [first.display()]
    return template.render(arguments).unwrap()
}

micro format<A, B>(template: utf8, first: A, second: B) -> utf8
    where A: Display, B: Display
{
    let arguments: [utf8] = [first.display(), second.display()]
    return template.render(arguments).unwrap()
}

micro format<A, B, C>(template: utf8, first: A, second: B, third: C) -> utf8
    where A: Display, B: Display, C: Display
{
    let arguments: [utf8] = [first.display(), second.display(), third.display()]
    return template.render(arguments).unwrap()
}
