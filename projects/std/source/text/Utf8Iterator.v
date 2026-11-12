namespace std.text;

class Utf8Iterator {
    _text: &Utf8Text,
    _offset: usize,
    _peek: Option<char>,
    _peeked: bool,
}

imply Utf8Iterator: std::iterator::Iterator {
    type Item = char;

    micro new(text: &Utf8Text) -> Self {
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

    micro next(mut self) -> Option<char> {
        if self._peeked {
            self._peeked = false
            let cached: Option<char> = self._peek
            let empty: Option<char> = None
            self._peek = empty
            return cached
        }

        if self._offset >= self._text.byte_length() {
            return None
        }

        # 迭代器内部按字节偏移推进（实现细节），解码委托 `Utf8Text` 的
        # `character_at_byte` / `char_width_at`（单一实现来源，不内联第二份解码）。
        let ch: char = self._text.character_at_byte(self._offset)
        self._offset = self._offset + self._text.char_width_at(self._offset)
        return Some(ch)
    }

    # 幂等观察：一格缓存。缓存空时恰好解码一个码点存入缓存并推进偏移；
    # 重复调用命中缓存，不再解码、不再推进。
    micro has_next(mut self): bool {
        if !self._peeked {
            if self._offset < self._text.byte_length() {
                let ch: char = self._text.character_at_byte(self._offset)
                self._offset = self._offset + self._text.char_width_at(self._offset)
                self._peek = Some(ch)
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}
