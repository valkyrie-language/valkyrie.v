namespace std.text;

class Utf16Iterator {
    _text: &Utf16Text,
    _offset: usize,
    _peek: Option<char>,
    _peeked: bool,
}

imply Utf16Iterator: std::iterator::Iterator {
    type Item = char;

    micro new(text: &Utf16Text) -> Self {
        return Self {
            _text: text,
            _offset: 0,
            _peek: None,
            _peeked: false,
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
        if self._peeked {
            self._peeked = false
            let cached: Option<char> = self._peek
            let empty: Option<char> = None
            self._peek = empty
            return cached
        }

        let units: [u16] = self._text.units()
        if self._offset >= units.length() {
            return None
        }

        let decoded: Result<(char, usize), Utf16DecodeError> = decode_utf16_at(units, self._offset)
        let pair: (char, usize) = decoded.unwrap()
        self._offset = self._offset + pair.1
        return Some(pair.0)
    }

    # 幂等观察：一格缓存。缓存空时恰好解码一个码位存入缓存并推进偏移；
    # 重复调用命中缓存，不再解码、不再推进。
    micro has_next(mut self): bool {
        if !self._peeked {
            let units: [u16] = self._text.units()
            if self._offset < units.length() {
                let decoded: Result<(char, usize), Utf16DecodeError> = decode_utf16_at(units, self._offset)
                let pair: (char, usize) = decoded.unwrap()
                self._offset = self._offset + pair.1
                self._peek = Some(pair.0)
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}
