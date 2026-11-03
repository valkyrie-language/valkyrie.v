namespace std.text;

⍝ [AsciiText] 是一个 ascii 文本，它只包含 ascii 字符集
structure AsciiText {
    _bytes: [u8]
}

class AsciiIterator {
    _text: &AsciiText
    _offset: usize
}

⍝ ────────── 不可变 ASCII 视图 ──────────
⍝ 视图是对 `AsciiText` 的引用加一个字节区间，不拥有数据。
structure AsciiView {
    text: &AsciiText,
    span: TextSpan,
}

imply AsciiView: TextView {
    type Text = AsciiText;

    micro span(self) -> TextSpan {
        return self.span
    }

    micro to_text(self) -> AsciiText {
        let mut bytes: ArrayList<u8> = ArrayList::new(self.span.length)
        let end: usize = self.end_offset()
        let mut index: usize = self.span.offset
        while index < end {
            bytes.push(self.text._bytes⁅index⁆)
            index = index + 1
        }

        return AsciiText { _bytes: bytes.to_array() }
    }
}

imply AsciiView: Text {
    type View = AsciiView;

    micro is_empty(self) -> bool {
        return self.span.length == 0
    }

    micro view(self, span: TextSpan) -> AsciiView {
        let view_end: usize = self.end_offset()
        let start: usize = self.span.offset + span.offset
        if start >= view_end {
            return AsciiView {
                text: self.text,
                span: TextSpan { offset: view_end, length: 0 },
            }
        }

        let mut length: usize = span.length
        if start + length > view_end {
            length = view_end - start
        }

        return AsciiView {
            text: self.text,
            span: TextSpan { offset: start, length: length },
        }
    }

    micro slice(self, span: TextSpan) -> AsciiView {
        return self.view(span)
    }
}

imply AsciiView {
    private micro end_offset(self) -> usize {
        return self.span.offset + self.span.length
    }
}

# 基本方法
imply AsciiText: Text {
    type View = AsciiView;

    ⍝ 获取 ascii 文本的字节数长度
    micro byte_length(self) -> usize {
        return self._bytes.length()
    }

    micro char_length(self) -> usize {
        return self._bytes.length()
    }

    micro is_empty(self) -> bool {
        return self._bytes.is_empty()
    }

    ⍝ 获取覆盖 `span` 区间的不可变视图；区间越界时收敛到有效范围
    micro view(self, span: TextSpan) -> AsciiView {
        let full_length: usize = self._bytes.length()
        let mut begin: usize = span.offset
        if begin > full_length {
            begin = full_length
        }

        let remaining: usize = full_length - begin
        let mut take: usize = span.length
        if take > remaining {
            take = remaining
        }

        return AsciiView {
            text: self,
            span: TextSpan { offset: begin, length: take },
        }
    }

    ⍝ 切分一段具有独立所有权的 ascii 文本
    micro slice(self, span: TextSpan) -> AsciiText {
        return self.view(span).to_text()
    }

    micro to_utf8(self) -> utf8 {
        # 安全性： 任何合法的 ascii 文本都可以转换为 utf8 文本
        return Utf8Text::from_bytes(self._bytes)
    }

    micro to_utf16(self) -> utf16 {
        return self._bytes.chars().collect()
    }

    micro to_c_str(self) -> c_str {
        # todo: 实现 c_str 转换
    }
}

# 迭代器方法
imply AsciiText {
    ⍝ 获取 ascii 文本的字符迭代器
    micro chars(self) -> AsciiIterator {
        return AsciiIterator {
            _text: self,
            _offset: 0,
        }
    }
}

imply AsciiText: std::iterator::IntoIterator {
    type Item = char;
    type Iter = AsciiIterator;

    micro into_iterator(self): AsciiIterator {
        return self.chars()
    }
}

imply AsciiIterator: std::iterator::Iterator {
    type Item = char;

    micro has_next(self): bool {
        return self._offset < self._text._bytes.length()
    }

    micro next(mut self): Option<char> {
        if !self.has_next() {
            return None
        }

        let value: char = self._text._bytes⁅self._offset⁆ as char
        self._offset = self._offset + 1
        return Some(value)
    }
}
