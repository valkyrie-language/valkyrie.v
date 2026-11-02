namespace std.data.binary.codec;

using std.data::{DataOutcome, data_outcome_of, data_outcome_partial, data_outcome_has_errors, data_outcome_diagnostics, data_outcome_value_or};
using std.diagnostic::{Diagnostic, Error, Span, new_diagnostic, new_span};

# std.data.binary.codec — 二进制字节编解码能力层。
#
# 只承载"字节如何被读取/写入"的能力：字节视图与偏移基址、端序、位级位置、
# 对齐与边界检查、越界结构化失败。任何具体容器格式（wasm/class/clr/jar/zip）
# 的节/段/表/项语义一律不进入本包；容器格式适配器调用本层，不许把解压/解码
# 实现内联进格式包。
#
# 越界与恢复语义（错误容许）：任何读取越界时**游标不推进**，返回带
# `std.data.codec.input_exhausted`（Error）诊断的结果；是否重同步、在何处
# 重同步由调用方（格式适配器）按自己的同步点决定——codec 不知道格式边界，
# 不得替调用方跳字节，也不得 panic 或返回吞掉越界的伪值。
#
# 常数纪律：magic number（`\0asm`、`0xCAFEBABE`、PK 头等）与字段宽度
# 一律用具名零参函数表达（语言暂无顶层常量声明），不散落裸数字。
#
# 数组访问纪律：本层一律用基数 `⁅ ⁆`（0 基、返回裸值）并自行做边界检查——
# 序数 `[ ]`/`get`（1 基、`Option`）不用于连续下标访问，`Option` 不参与算术。
# `⁅ ⁆` 越界 panic 路径当前各后端尚无 raise 目标合同，本层所有访问点前置
# 边界检查，动态上永不越界，不依赖 panic 行为兜底。

# 字节序：多字节整数读取时的字节排列。
# 纯标记（二选一、无 payload）必须是 `enums`；`unite` 是带 payload 的可区分
# 联合（引用语义），拿它当布尔/枚举是类型选择错误。裸 enums 的 match 在当前
# lowering 下无 extractor 身份可用，这是实现侧现状，不为它改类型设计。
enums DataEndian {
    Little
    Big
}

# 位序：位流读取/写入时先消费字节的哪一端（DEFLATE 为 LSB 先读）。
# 同为纯标记，`enums` 形态。
enums DataBitOrder {
    LeastSignificantBitFirst
    MostSignificantBitFirst
}

# 位级位置：字节偏移 + 位偏移（0..7）。
structure DataBitPosition {
    byte_offset: usize
    bit_offset: usize
}

# 字节视图：底层字节数组 + 偏移基址 + 长度。
# 容器格式里的"节/段/载荷"都是父源上的窗口，不复制字节；
# `base` 是视图相对父源的绝对偏移基址，`Span` 单位=字节。
structure DataByteView {
    bytes: [u8]
    base: usize
    length: usize
}

# 视图构造并校验窗口合法性：`base + length` 不得越出底层数组。
# 非法窗口不产生视图对象，返回带 `std.data.codec.invalid_view` 诊断的
# 零长视图占位（base/length 归零，读取必然越界报 input_exhausted）。
micro data_byte_view(bytes: [u8], base: usize, length: usize) -> DataOutcome<DataByteView> {
    let capacity: usize = bytes.length()
    if base > capacity {
        let span: Span = new_span(capacity, capacity)
        return data_outcome_partial(
            DataByteView { bytes: bytes, base: 0, length: 0 },
            [new_diagnostic("std.data.codec.invalid_view", Error, "视图基址越出底层数组", span)]
        )
    }
    if length > capacity - base {
        let span: Span = new_span(base, capacity)
        return data_outcome_partial(
            DataByteView { bytes: bytes, base: 0, length: 0 },
            [new_diagnostic("std.data.codec.invalid_view", Error, "视图长度越出底层数组", span)]
        )
    }
    return data_outcome_of(DataByteView { bytes: bytes, base: base, length: length })
}

# 整数组视图：全量窗口的便捷构造。
micro data_byte_view_of(bytes: [u8]) -> DataByteView {
    return DataByteView { bytes: bytes, base: 0, length: std::collection::array::length(bytes) }
}

# 字节级顺序读取器：游标语义，全部读取越界时结构化失败。
trait DataByteReader {
    # 当前位置（视图相对字节偏移）。
    micro position(self) -> usize

    # 剩余可读字节数。
    micro remaining(self) -> usize

    # 读单字节。
    micro read_u8(mut self) -> DataOutcome<u8>

    # 按端序读多字节整数。
    micro read_u16(mut self, endian: DataEndian) -> DataOutcome<u16>
    micro read_u32(mut self, endian: DataEndian) -> DataOutcome<u32>
    micro read_u64(mut self, endian: DataEndian) -> DataOutcome<u64>

    # 读 `length` 字节为子视图（不复制，基址随游标推进）。
    micro read_view(mut self, length: usize) -> DataOutcome<DataByteView>

    # 跳过 `length` 字节，返回新位置。
    micro skip(mut self, length: usize) -> DataOutcome<usize>

    # 对齐到 `alignment` 字节边界（相对视图基址），返回新位置。
    micro align(mut self, alignment: usize) -> DataOutcome<usize>
}

# 位级顺序读取器：按位消费字节流（如 DEFLATE 类位流格式的底层）。
trait DataBitReader {
    # 当前位级位置。
    micro bit_position(self) -> DataBitPosition

    # 读单比特（0/1）。
    micro read_bit(mut self) -> DataOutcome<u8>

    # 读 `width` 个连续比特（宽度不超过 64）。
    micro read_bits(mut self, width: usize) -> DataOutcome<u64>
}

# ── 实现 ─────────────────────────────────────────────────────────────

# 字节读取游标：`DataByteReader` 的具体实现。
structure DataByteCursor {
    view: DataByteView
    offset: usize
}

micro data_byte_cursor(view: DataByteView) -> DataByteCursor {
    return DataByteCursor { view: view, offset: 0 }
}

# 越界诊断的统一构造：游标不推进由调用点保证（失败分支不写 self.offset）。
micro codec_input_exhausted<T>(placeholder: T, at: usize) -> DataOutcome<T> {
    let span: Span = new_span(at, at)
    return data_outcome_partial(
        placeholder,
        [new_diagnostic("std.data.codec.input_exhausted", Error, "读取越界：输入耗尽，游标未推进", span)]
    )
}

imply DataByteCursor: DataByteReader {
    micro position(self) -> usize {
        return self.offset
    }

    micro remaining(self) -> usize {
        if self.offset < self.view.length {
            return self.view.length - self.offset
        }
        return 0
    }

    micro read_u8(mut self) -> DataOutcome<u8> {
        if self.remaining() == 0 {
            return codec_input_exhausted(0 as u8, self.view.base + self.offset)
        }
        let value: u8 = self.view.bytes⁅self.view.base + self.offset⁆
        self.offset = self.offset + 1
        return data_outcome_of(value)
    }

    micro read_u16(mut self, endian: DataEndian) -> DataOutcome<u16> {
        if self.remaining() < 2 {
            return codec_input_exhausted(0 as u16, self.view.base + self.offset)
        }
        let first: u16 = self.view.bytes⁅self.view.base + self.offset⁆ as u16
        let second: u16 = self.view.bytes⁅self.view.base + self.offset + 1⁆ as u16
        self.offset = self.offset + 2
        match endian {
            case Little:
                return data_outcome_of(first | (second << 8))
            case Big:
                return data_outcome_of((first << 8) | second)
        }
    }

    micro read_u32(mut self, endian: DataEndian) -> DataOutcome<u32> {
        if self.remaining() < 4 {
            return codec_input_exhausted(0 as u32, self.view.base + self.offset)
        }
        let b0: u32 = self.view.bytes⁅self.view.base + self.offset⁆ as u32
        let b1: u32 = self.view.bytes⁅self.view.base + self.offset + 1⁆ as u32
        let b2: u32 = self.view.bytes⁅self.view.base + self.offset + 2⁆ as u32
        let b3: u32 = self.view.bytes⁅self.view.base + self.offset + 3⁆ as u32
        self.offset = self.offset + 4
        match endian {
            case Little:
                return data_outcome_of(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
            case Big:
                return data_outcome_of((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
        }
    }

    micro read_u64(mut self, endian: DataEndian) -> DataOutcome<u64> {
        if self.remaining() < 8 {
            return codec_input_exhausted(0 as u64, self.view.base + self.offset)
        }
        let b0: u64 = self.view.bytes⁅self.view.base + self.offset⁆ as u64
        let b1: u64 = self.view.bytes⁅self.view.base + self.offset + 1⁆ as u64
        let b2: u64 = self.view.bytes⁅self.view.base + self.offset + 2⁆ as u64
        let b3: u64 = self.view.bytes⁅self.view.base + self.offset + 3⁆ as u64
        let b4: u64 = self.view.bytes⁅self.view.base + self.offset + 4⁆ as u64
        let b5: u64 = self.view.bytes⁅self.view.base + self.offset + 5⁆ as u64
        let b6: u64 = self.view.bytes⁅self.view.base + self.offset + 6⁆ as u64
        let b7: u64 = self.view.bytes⁅self.view.base + self.offset + 7⁆ as u64
        self.offset = self.offset + 8
        match endian {
            case Little:
                return data_outcome_of(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24) | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56))
            case Big:
                return data_outcome_of((b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7)
        }
    }

    micro read_view(mut self, length: usize) -> DataOutcome<DataByteView> {
        if self.remaining() < length {
            return codec_input_exhausted(DataByteView { bytes: self.view.bytes, base: self.view.base, length: 0 }, self.view.base + self.offset)
        }
        let sub: DataByteView = DataByteView { bytes: self.view.bytes, base: self.view.base + self.offset, length: length }
        self.offset = self.offset + length
        return data_outcome_of(sub)
    }

    micro skip(mut self, length: usize) -> DataOutcome<usize> {
        if self.remaining() < length {
            return codec_input_exhausted(self.offset, self.view.base + self.offset)
        }
        self.offset = self.offset + length
        return data_outcome_of(self.offset)
    }

    micro align(mut self, alignment: usize) -> DataOutcome<usize> {
        if alignment == 0 {
            let span: Span = new_span(self.view.base + self.offset, self.view.base + self.offset)
            return data_outcome_partial(
                self.offset,
                [new_diagnostic("std.data.codec.invalid_alignment", Error, "对齐宽度不能为 0", span)]
            )
        }
        let rem: usize = self.offset % alignment
        if rem == 0 {
            return data_outcome_of(self.offset)
        }
        let padding: usize = alignment - rem
        if self.remaining() < padding {
            return codec_input_exhausted(self.offset, self.view.base + self.offset)
        }
        self.offset = self.offset + padding
        return data_outcome_of(self.offset)
    }
}

# 位读取游标：`DataBitReader` 的具体实现。
# 无内部缓冲的直读模型：`byte_index` 是下一个未触碰字节，`bit_index` 是当前
# 字节内已消费位数（0..7）；位序决定从字节的哪一端先消费。
structure DataBitCursor {
    view: DataByteView
    byte_index: usize
    bit_index: usize
    order: DataBitOrder
}

micro data_bit_cursor(view: DataByteView, order: DataBitOrder) -> DataBitCursor {
    return DataBitCursor { view: view, byte_index: 0, bit_index: 0, order: order }
}

imply DataBitCursor: DataBitReader {
    micro bit_position(self) -> DataBitPosition {
        return DataBitPosition { byte_offset: self.byte_index, bit_offset: self.bit_index }
    }

    micro read_bit(mut self) -> DataOutcome<u8> {
        if self.byte_index >= self.view.length {
            return codec_input_exhausted(0 as u8, self.view.base + self.byte_index)
        }
        # u8 无目标 provider 的位移/比较，经 u64 载道取值后截回。
        let byte: u64 = self.view.bytes⁅self.view.base + self.byte_index⁆ as u64
        let bit: u64 = match self.order {
            case LeastSignificantBitFirst:
                (byte >> self.bit_index) & 1
            case MostSignificantBitFirst:
                (byte >> (7 - self.bit_index)) & 1
        }
        self.bit_index = self.bit_index + 1
        if self.bit_index == 8 {
            self.bit_index = 0
            self.byte_index = self.byte_index + 1
        }
        return data_outcome_of(bit as u8)
    }

    micro read_bits(mut self, width: usize) -> DataOutcome<u64> {
        if width > 64 {
            let span: Span = new_span(self.view.base + self.byte_index, self.view.base + self.byte_index)
            return data_outcome_partial(
                0 as u64,
                [new_diagnostic("std.data.codec.invalid_bit_width", Error, "单次读取位宽超过 64", span)]
            )
        }
        let mut value: u64 = 0
        let mut consumed: usize = 0
        let mut diagnostics: [Diagnostic] = []
        while consumed < width {
            let step: DataOutcome<u8> = self.read_bit()
            if data_outcome_has_errors(step) {
                # 越界发生在第 consumed 位：聚合诊断并带值返回部分结果。
                let inner: [Diagnostic] = data_outcome_diagnostics(step)
                let mut at: usize = 0
                while at < inner.length() {
                    diagnostics = diagnostics.push(inner⁅at⁆)
                    at = at + 1
                }
                return data_outcome_partial(value, diagnostics)
            }
            let bit: u64 = data_outcome_value_or(step, 0 as u8) as u64
            match self.order {
                case LeastSignificantBitFirst:
                    value = value | (bit << consumed)
                case MostSignificantBitFirst:
                    value = (value << 1) | bit
            }
            consumed = consumed + 1
        }
        return data_outcome_of(value)
    }
}

# ── 位写入 ───────────────────────────────────────────────────────────
# 位写出器：把位段打包进字节。`bytes` 是已完成字节（函数式追加），
# `current`/`used` 是累积中的部分字节；`align_to_byte` 与 `finish` 以 0 补齐。
structure DataBitWriter {
    bytes: [u8]
    current: u8
    used: usize
    order: DataBitOrder
}

micro data_bit_writer(order: DataBitOrder) -> DataBitWriter {
    return DataBitWriter { bytes: [], current: 0, used: 0, order: order }
}

imply DataBitWriter {
    # 写单比特。u8 无目标 provider 的位移，经 u64 载道组装后截回。
    micro write_bit(mut self, bit: u8) -> unit {
        let low: u64 = (bit as u64) & 1
        let placed: u64 = match self.order {
            case LeastSignificantBitFirst:
                (self.current as u64) | (low << self.used)
            case MostSignificantBitFirst:
                (self.current as u64) | (low << (7 - self.used))
        }
        self.current = placed as u8
        self.used = self.used + 1
        if self.used == 8 {
            self.bytes = self.bytes.push(self.current)
            self.current = 0
            self.used = 0
        }
    }

    # 写 `value` 的低 `width` 位（宽度不超过 64）。
    micro write_bits(mut self, value: u64, width: usize) -> DataOutcome<usize> {
        if width > 64 {
            let written: usize = self.bytes.length()
            let span: Span = new_span(written, written)
            return data_outcome_partial(
                written,
                [new_diagnostic("std.data.codec.invalid_bit_width", Error, "单次写入位宽超过 64", span)]
            )
        }
        let mut index: usize = 0
        while index < width {
            let bit: u8 = match self.order {
                case LeastSignificantBitFirst:
                    ((value >> index) & 1) as u8
                case MostSignificantBitFirst:
                    ((value >> (width - 1 - index)) & 1) as u8
            }
            self.write_bit(bit)
            index = index + 1
        }
        return data_outcome_of(self.bytes.length())
    }

    # 是否处在字节边界。
    micro is_aligned(self) -> bool {
        return self.used == 0
    }

    # 以 0 补齐当前字节，使下一写从字节边界开始。
    micro align_to_byte(mut self) -> unit {
        if self.used > 0 {
            self.bytes = self.bytes.push(self.current)
            self.current = 0
            self.used = 0
        }
    }

    # 以 0 补齐最后一个部分字节并返回全部字节。
    micro finish(mut self) -> [u8] {
        self.align_to_byte()
        return self.bytes
    }
}
