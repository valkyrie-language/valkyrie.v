namespace std.text;

⍝ ────────── 不可变文本视图 ──────────
⍝ 视图是对 `Utf8Text` 的引用加一个区间，极轻量。
⍝ 因为 `Utf8Text` 不可变且为引用类型，视图始终有效。
⍝ 两类视图严格区分：
⍝ - `Utf8View` 是有效文本视图——起止必须落在码点边界，覆盖区间恒为整段码点；
⍝ - `Utf8ByteWindow` 是任意字节窗口——任何字节区间都合法（字节级搬运、
⍝   调试转储用），具体化为文本必须经严格验证。

⍝ 文本视图构造的失败类别：携带出错端点的字节位置。
unite Utf8ViewError {
    ⍝ 区间起点落在续字节（0x80..0xBF）上
    [constructor]
    StartNotBoundary { position: usize },
    ⍝ 区间终点截断在码点序列内部
    [constructor]
    EndNotBoundary { position: usize },
    ⍝ 区间越出底层文本的字节长度
    [constructor]
    BeyondText { position: usize },
}

structure Utf8View {
    ⍝ 指向底层不可变文本，永远有效
    text: &Utf8Text,
    ⍝ 视图覆盖的字节范围：起止都落在码点边界上（类型不变量）
    span: TextSpan,
}

imply Utf8View {
    ⍝ 全区间视图：整段文本本身就是码点对齐的有效区间
    micro new(text: &Utf8Text) -> Self {
        return Self {
            text: text,
            span: TextSpan {
                offset: 0,
                length: text.byte_length(),
            }
        }
    }

    ⍝ 严格构造：起点必须是码点边界、终点必须恰好与码点边界重合，
    ⍝ 否则结构化失败——不收敛、不截断、不漂移到最近边界。
    micro try_new(text: &Utf8Text, span: TextSpan) -> Result<Self, Utf8ViewError> {
        let size: usize = text.byte_length()
        if span.offset > size {
            return Fail { error: BeyondText { position: span.offset } }
        }

        ⍝ `length` 只与剩余量比较、不与 `offset` 相加后再判界，请求区间越界
        ⍝ 不存在整数溢出路径；`end` 只在已证明 `offset + length <= size` 后计算。
        let remaining: usize = size - span.offset
        if span.length > remaining {
            return Fail { error: BeyondText { position: size } }
        }

        let end: usize = span.offset + span.length

        if span.offset < size {
            let lead: u32 = text.byte_at(span.offset) as u32
            if (lead & 0xC0) == 0x80 {
                return Fail { error: StartNotBoundary { position: span.offset } }
            }
        }

        ⍝ 自起点逐码点前进：终点必须与某个码点边界精确重合
        let mut cursor: usize = span.offset
        while cursor < end {
            let width: usize = text.char_width_at(cursor)
            if cursor + width > end {
                return Fail { error: EndNotBoundary { position: end } }
            }

            cursor = cursor + width
        }

        return Fine { value: Self { text: text, span: span } }
    }

    micro span(self) -> TextSpan {
        return self.span
    }

    micro byte_length(self) -> usize {
        return self.span.length
    }

    micro is_empty(self) -> bool {
        return self.span.length == 0
    }

    ⍝ 对视图自身再取相对区间（同样按有效文本视图验证）
    micro try_view(self, span: TextSpan) -> Result<Utf8View, Utf8ViewError> {
        return Utf8View::try_new(self.text, TextSpan {
            offset: self.span.offset + span.offset,
            length: span.length,
        })
    }

    ⍝ 具体化为文本：经严格 UTF-8 验证返回 `Result`。
    ⍝ 视图不变量保证区间良构，验证是该入口的合同形态，不走信任捷径。
    micro to_text(self) -> Result<Utf8Text, Utf8DecodeError> {
        let mut bytes: ArrayList<u8> = ArrayList::new(self.span.length)
        let end: usize = self.span.offset + self.span.length
        let mut index: usize = self.span.offset
        while index < end {
            bytes.push(self.text._repr⁅index⁆)
            index = index + 1
        }

        return Utf8Text::from_bytes(bytes.to_array())
    }
}

⍝ ────────── 任意字节窗口 ──────────
⍝ 不要求起止落在码点边界：任何字节区间都是合法窗口，越界区间收敛到有效范围。
⍝ 窗口只承诺字节语义；需要文本语义时用 `to_text` 显式验证，或改走 `Utf8View`。
structure Utf8ByteWindow {
    ⍝ 指向底层不可变文本，永远有效
    text: &Utf8Text,
    ⍝ 窗口覆盖的字节范围（任意区间）
    span: TextSpan,
}

imply Utf8ByteWindow {
    micro new(text: &Utf8Text, span: TextSpan) -> Self {
        let full_length: usize = text.byte_length()
        if span.offset >= full_length {
            return Self {
                text: text,
                span: TextSpan {
                    offset: full_length,
                    length: 0,
                }
            }
        }

        let mut length: usize = span.length
        if span.offset + length > full_length {
            length = full_length - span.offset
        }

        return Self {
            text: text,
            span: TextSpan {
                offset: span.offset,
                length: length,
            }
        }
    }

    micro span(self) -> TextSpan {
        return self.span
    }

    micro byte_length(self) -> usize {
        return self.span.length
    }

    micro is_empty(self) -> bool {
        return self.span.length == 0
    }

    ⍝ 对窗口自身再取相对字节窗口
    micro view(self, span: TextSpan) -> Utf8ByteWindow {
        return Utf8ByteWindow::new(self.text, TextSpan {
            offset: self.span.offset + span.offset,
            length: span.length,
        })
    }

    ⍝ 窗口的原始字节（不解释、不验证）
    micro to_bytes(self) -> [u8] {
        let mut bytes: ArrayList<u8> = ArrayList::new(self.span.length)
        let end: usize = self.span.offset + self.span.length
        let mut index: usize = self.span.offset
        while index < end {
            bytes.push(self.text._repr⁅index⁆)
            index = index + 1
        }

        return bytes.to_array()
    }

    ⍝ 具体化为文本：任意字节窗口可能截断码点序列，必须经严格验证
    micro to_text(self) -> Result<Utf8Text, Utf8DecodeError> {
        return Utf8Text::from_bytes(self.to_bytes())
    }
}
