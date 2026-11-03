namespace std.text;

structure c_str {
    _address: usize
}

structure c_char {
    _char: u8
}

# c_str 编码转换是语言可见的宿约声明，provider 由目标 adaptor 在 link/plan 阶段绑定；
# std 自身构建只要求声明在场，不挂 adaptor。
[host_contract]
micro c_str_length(s: c_str): i32 { }

[host_contract]
micro c_str_to_utf8(s: c_str): utf8 { }

[host_contract]
micro c_str_to_utf16(s: c_str): utf16 { }

imply c_str {
    micro null_ptr() -> Self {
        return Self { _address: 0 }
    }

    micro is_null(self) -> bool {
        return self._address == 0
    }

    micro length(self) -> i32 {
        return c_str_length(self)
    }

    micro is_empty(self) -> bool {
        return c_str_length(self) == 0
    }

    micro to_utf8(self) -> utf8 {
        return c_str_to_utf8(self)
    }

    micro to_utf16(self) -> utf16 {
        return c_str_to_utf16(self)
    }
}

structure jvm_str {
    _address: usize
}

imply jvm_str {
    micro null_ptr() -> Self {
        return Self { _address: 0 }
    }

    micro is_null(self) -> bool {
        return self._address == 0
    }
}
