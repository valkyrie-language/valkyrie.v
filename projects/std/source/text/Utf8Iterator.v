namespace std.text;

class Utf8Iterator {
    _text: &Utf8Text,
    _offset: usize,
}

imply Utf8Iterator: std::iterator::Iterator {
    type Item = char;

    micro new(text: &Utf8Text) -> Self {
        return Self {
            _text: text,
            _offset: 0,
        }
    }

    micro offset(self) -> usize {
        return self._offset
    }

    micro has_next(self) -> bool {
        return self._offset < self._text.byte_length()
    }

    micro next(mut self) -> Option<char> {
        if !self.has_next() {
            return None
        }

        # 迭代器内部按字节偏移推进（实现细节），解码委托 `Utf8Text` 的
        # `character_at_byte` / `char_width_at`（单一实现来源，不内联第二份解码）。
        let ch: char = self._text.character_at_byte(self._offset)
        self._offset = self._offset + self._text.char_width_at(self._offset)
        return Some(ch)
    }
}
