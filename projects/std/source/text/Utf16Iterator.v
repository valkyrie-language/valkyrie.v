namespace std.text;

class Utf16Iterator {
    _text: &Utf16Text,
    _offset: usize,
}

imply Utf16Iterator: std::iterator::Iterator {
    type Item = char;

    micro new(text: &Utf16Text) -> Self {
        return Self {
            _text: text,
            _offset: 0,
        }
    }

    micro offset(self) -> usize {
        return self._offset
    }

    # 码位视图：代理对合成收口到 `std.text.encoding` 的 `decode_utf16_at`
    # （唯一实现来源，本文件不再写第二份合成/判定逻辑）。
    # 落单代理项显式失败：迭代器协议没有错误通道，非法配对序列 panic，
    # 绝不把代理半区原值冒充码位产出；可恢复解码直接走 `decode_utf16_at`。
    micro next(mut self) -> Option<char> {
        let units: [u16] = self._text.units()
        if self._offset >= units.length() {
            return None
        }

        let decoded: Result<(char, usize), Utf16DecodeError> = decode_utf16_at(units, self._offset)
        let pair: (char, usize) = decoded.unwrap()
        self._offset = self._offset + pair.1
        return Some(pair.0)
    }
}
