namespace std.text;

⍝ ────────── 不可变字节窗口视图 ──────────
⍝ 视图是对 `Utf8Text` 的引用加一个字节区间，极轻量。
⍝ 因为 `Utf8Text` 不可变且为引用类型，视图始终有效。
⍝ `Utf8View` 是字节窗口：任意字节范围都合法（字节级搬运、调试转储用），
⍝ 起止不要求落在码点边界，构造不验证边界。
⍝ 字节窗口具体化为有效文本必须经 `to_text` 严格验证：校验 span 两端落在
⍝ 码点边界、区间内全部序列为良构 UTF-8，返回 `Result`——禁止把半个码点
⍝ 重新包装为有效文本。需要「构造即边界良构」时用显式严格构造入口 `try_new`。

⍝ 严格构造视图的失败类别：携带出错端点的字节位置。
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
    ⍝ 窗口覆盖的字节范围：任意区间合法（构造时越界收敛到文本有效范围）
    span: TextSpan,
}

imply Utf8View {
    ⍝ 全区间窗口：整段文本本身就是窗口。
    micro full(text: &Utf8Text) -> Self {
        return Self {
            text: text,
            span: TextSpan {
                offset: 0,
                length: text.byte_length(),
            }
        }
    }

    ⍝ 字节窗口构造：任意字节范围都合法，不验证码点边界；
    ⍝ 越界区间收敛到文本有效范围（起点不越过文末，长度不越过剩余量）。
    ⍝ 长度只与「文末剩余量」比较，不与 `offset` 相加后再判界——
    ⍝ `offset + length` 的回绕路径不存在（01 §4.16）。
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

        let remaining: usize = full_length - span.offset
        let mut length: usize = span.length
        if length > remaining {
            length = remaining
        }

        return Self {
            text: text,
            span: TextSpan {
                offset: span.offset,
                length: length,
            }
        }
    }

    ⍝ 显式严格构造：起点必须是码点边界、终点必须恰好与码点边界重合，
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

    ⍝ 对窗口自身再取相对字节窗口（任意区间合法，构造同规则收敛）。
    ⍝ 先对父窗口剩余量判界，再换算绝对偏移：子窗口不得逃出父窗口，
    ⍝ 与底层文本是否还有余量无关（06 §1.29 维持拒收第 7 项）。
    micro view(self, span: TextSpan) -> Utf8View {
        let mut offset: usize = span.offset
        if offset > self.span.length {
            offset = self.span.length
        }

        let remaining: usize = self.span.length - offset
        let mut length: usize = span.length
        if length > remaining {
            length = remaining
        }

        return Utf8View {
            text: self.text,
            span: TextSpan {
                offset: self.span.offset + offset,
                length: length,
            }
        }
    }

    ⍝ 对窗口自身再取相对区间（按码点边界严格验证）。
    ⍝ 判界顺序同上：先父窗口剩余量，后绝对换算；`try_new` 只可能因
    ⍝ 码点边界失败，越界已在父窗口处结构化拒绝。
    micro try_view(self, span: TextSpan) -> Result<Utf8View, Utf8ViewError> {
        if span.offset > self.span.length {
            return Fail { error: BeyondText { position: span.offset } }
        }

        let remaining: usize = self.span.length - span.offset
        if span.length > remaining {
            return Fail { error: BeyondText { position: self.span.length } }
        }

        return Utf8View::try_new(self.text, TextSpan {
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

    ⍝ 具体化为文本：字节窗口可能截断码点序列，必须经严格验证返回 `Result`，
    ⍝ 禁止把半个码点重新包装为有效文本。
    ⍝ 先校验 span 两端落在码点边界（起始非续字节、结束不落多字节序列中间），
    ⍝ 错误携带底层文本的绝对字节位置；再交由 `Utf8Text::from_bytes` 唯一严格
    ⍝ 构造器对区间内完整序列逐类别判定（内部即 `validate_utf8`/`decode_char_at`）。
    micro to_text(self) -> Result<Utf8Text, Utf8DecodeError> {
        let end: usize = self.span.offset + self.span.length

        ⍝ 起点边界：非空窗口的首字节不得是续字节（0x80..0xBF）
        if self.span.offset < end {
            let lead: u32 = self.text.byte_at(self.span.offset) as u32
            if (lead & 0xC0) == 0x80 {
                return Fail { error: UnexpectedContinuation { position: self.span.offset } }
            }
        }

        ⍝ 终点边界：自起点逐码点前进，任一序列不得越过窗口终点
        let mut cursor: usize = self.span.offset
        while cursor < end {
            let width: usize = self.text.char_width_at(cursor)
            if cursor + width > end {
                return Fail { error: Truncated { position: cursor } }
            }

            cursor = cursor + width
        }

        return Utf8Text::from_bytes(self.to_bytes())
    }
}
