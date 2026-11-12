namespace std.text;

⍝ UTF-16 编码的字符串
[primitive("std::text::utf16")]
class Utf16Text {
    _repr: [u16]
}

imply Utf16Text {
    # 由码元数组直接落成文本；与 `Utf8Text::from_bytes` 对称，不做额外校验。
    micro from_units(units: [u16]) -> Self {
        return Utf16Text { _repr: units }
    }

    [host_contract]
    micro length(self) -> usize {
        return self._repr.length()
    }

    micro is_empty(self) -> bool {
        if self.length() == 0 {
            return true
        }

        return false
    }

    # 以下方法均为宿主契约：std 只声明签名与语义口径（索引空间为 UTF-16 码元）。
    # 提供真实宿主字符串能力的目标在其 adaptor 绑定 provider；未绑定合法 provider 时，
    # 本 shell 显式失败，不以占位返回值冒充未交付的能力。
    [host_contract]
    micro slice(self, start: usize, count: usize) -> utf16 {
        std::types::panic("Utf16Text slice 无合法 provider：当前目标未提供 UTF-16 切片能力")
    }

    [host_contract]
    micro concat(self, other: utf16) -> utf16 {
        std::types::panic("Utf16Text concat 无合法 provider：当前目标未提供 UTF-16 拼接能力")
    }

    [host_contract]
    micro contains(self, value: utf16) -> bool {
        std::types::panic("Utf16Text contains 无合法 provider：当前目标未提供 UTF-16 包含判定能力")
    }

    [host_contract]
    micro starts_with(self, prefix: utf16) -> bool {
        std::types::panic("Utf16Text starts_with 无合法 provider：当前目标未提供 UTF-16 前缀判定能力")
    }

    [host_contract]
    micro ends_with(self, suffix: utf16) -> bool {
        std::types::panic("Utf16Text ends_with 无合法 provider：当前目标未提供 UTF-16 后缀判定能力")
    }

    [host_contract]
    micro index_of(self, value: utf16) -> Option<usize> {
        std::types::panic("Utf16Text index_of 无合法 provider：当前目标未提供 UTF-16 查找能力")
    }

    [host_contract]
    micro trim(self) -> utf16 {
        std::types::panic("Utf16Text trim 无合法 provider：当前目标未提供 UTF-16 裁剪能力")
    }

    [host_contract]
    micro to_lower(self) -> utf16 {
        std::types::panic("Utf16Text to_lower 无合法 provider：当前目标未提供 UTF-16 小写映射能力")
    }

    [host_contract]
    micro to_upper(self) -> utf16 {
        std::types::panic("Utf16Text to_upper 无合法 provider：当前目标未提供 UTF-16 大写映射能力")
    }

    [host_contract]
    micro replace(self, old_value: utf16, new_value: utf16) -> utf16 {
        std::types::panic("Utf16Text replace 无合法 provider：当前目标未提供 UTF-16 替换能力")
    }

    [host_contract]
    micro equals(self, other: utf16) -> bool {
        std::types::panic("Utf16Text equals 无合法 provider：当前目标未提供 UTF-16 相等判定能力")
    }

    micro chars(self) -> Utf16Iterator {
        return Utf16Iterator::new(self)
    }
}

# 码位视图：`Utf16Iterator` 把代理对合成为完整 `char` 码位，与码元索引合同分离。
imply Utf16Text: std::iterator::IntoIterator {
    type Item = char;
    type Iter = Utf16Iterator;

    micro into_iterator(self): Utf16Iterator {
        return self.chars()
    }
}

# 0 基码元索引读写合同：`⁅ ⁆` / `⁅ ⁆=` 与同源的 `get_cardinal` / `set_cardinal`。
# 索引空间选定为 UTF-16 码元（code unit，与 `length` 的计数单位一致），元素即
# `u16` 码元本体，不是 `char` 码位：索引、长度与越界错误位置统一按码元空间；
# 码位语义只由 `Utf16Iterator` 的显式代理对合成视图提供，本合同不掺入码位解释，
# 也不设第二套索引空间。与 `Utf8Text` 的 0 基码点合同同构——都按各自 repr 的字符
# 单位计，只是单位不同（UTF-16 码元、UTF-8 码点）；字素口径未来以显式视图 API
# 单独开，不混入本合同。元素个数由 `length` 承担，与本合同无关。
imply Utf16Text: std::operator::Cardinal {
    type Element = u16;
    type Index = usize;

    # 0 基码元索引自动取值；越界结构化失败（合同语义见 `std::operator::Cardinal`）。
    # 读取只此一份：直接落在 `_repr` 的 0 基数组合同，与 `⁅ ⁆=` 的 `array::set` 对称。
    # 返回裸 `u16` 码元；代理半区以原值呈现，不在这里合成码位。
    suffix `⁅ ⁆`(self, offset: usize): u16 {
        if offset >= self.length() {
            std::types::panic("Utf16Text ⁅ ⁆ 越界：offset 超出元素个数")
        }

        return std::collection::array::get(self._repr, offset)
    }

    # 0 基 code unit 索引写入，只改元素不改元素个数；越界结构化失败，不许静默丢弃写入。
    # 参数即 `u16` 码元，天然落在码元值域内，不设码位范围判定；完整 astral 码位的
    # 写入属字符级 API（以 `char` 为参、内部做代理对拆分），不经单格码元写。
    suffix `⁅ ⁆=`(mut self, offset: usize, value: u16): unit {
        if offset >= self.length() {
            std::types::panic("Utf16Text ⁅ ⁆= 越界：offset 超出元素个数")
        }

        std::collection::array::set(self._repr, offset, value)
    }

    # 与 `⁅ ⁆` 同源：命名方法形态，互为委托，不维护第二套索引访问逻辑。
    micro get_cardinal(self, offset: usize): u16 {
        return self⁅offset⁆
    }

    # 与 `⁅ ⁆=` 同源：命名方法形态，互为委托。
    micro set_cardinal(mut self, offset: usize, value: u16): unit {
        self⁅offset⁆ = value
    }
}

# 1 基序数读写合同：`[ ]` / `[ ]=` 与同源的 `get` / `set`，索引空间同为码元。
# `Index` 取 `isize`（负数落入越界判定，读返回 `None`）；实际访问委托 `Cardinal`
# 的 0 基码元偏移，本 impl 不重复存储访问逻辑。
imply Utf16Text: std::operator::Ordinal {
    type Index = isize;
    type Element = u16;

    # 序数 1 基，裸 `u16` 码元读取；越界结构化失败。
    suffix `[ ]`(self, ordinal: isize): u16 {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ] 越界：序数超出 [1, 元素个数]")
        }

        return self.get_cardinal((ordinal - 1) as usize)
    }

    # 越界写结构化失败，不许静默丢弃写入。
    suffix `[ ]=`(mut self, ordinal: isize, value: u16): unit {
        if ordinal < 1 || ordinal > self.length() as isize {
            std::types::panic("Ordinal [ ]= 越界：序数超出 [1, 元素个数]")
        }

        self.set_cardinal((ordinal - 1) as usize, value)
    }

    # 命名读路径：可恢复形态，越界返回 `None`。
    micro get(self, ordinal: isize): Option<u16> {
        if ordinal < 1 || ordinal > self.length() as isize {
            return None
        }

        return Some(self.get_cardinal((ordinal - 1) as usize))
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, ordinal: isize, value: u16): unit {
        self[ordinal] = value
    }
}

