namespace std.data.binary.codec;

using std.data::{DataDiagnostic, DataOutcome, DataSeverity, DataSpan};

# std.data.binary.codec — 二进制字节编解码能力层。
#
# 只承载"字节如何被读取"的能力：字节视图与偏移基址、端序、位级位置、
# 对齐与边界检查、越界结构化失败。任何具体容器格式（wasm/class/clr/jar/zip）
# 的节/段/表/项语义一律不进入本包；容器格式适配器调用本层，不许把解压/解码
# 实现内联进格式包。
#
# 越界与恢复语义（错误容许）：任何读取越界时**游标不推进**，返回带
# `codec.input_exhausted`（Error）诊断的结果；是否重同步、在何处重同步由
# 调用方（格式适配器）按自己的同步点决定——codec 不知道格式边界，
# 不得替调用方跳字节，也不得 panic 或返回吞掉越界的伪值。
#
# 常量纪律：magic number（`\0asm`、`0xCAFEBABE`、PK 头等）与字段宽度
# 一律用具名常量声明，不散落十进制数字。
#
# 本轮只声明接口与类型，不实现；实现按块在编译器缺口修复后补齐。

# 字节序：多字节整数读取时的字节排列。
enums DataEndian {
    Little
    Big
}

# 位序：位流读取/写入时先消费字节的哪一端（DEFLATE 为 LSB 先读）。
# 纯标记（二选一、无 payload）用 `enums`；`unite` 是带 payload 的可区分
# 联合（引用语义），不作标记形态。
enums DataBitOrder {
    LeastSignificantBitFirst
    MostSignificantBitFirst
}

# 位级位置：字节偏移 + 位偏移（0..7）。
# 位序（MSB 先读还是 LSB 先读）由读取方按格式规定传入，本结构不预设。
structure DataBitPosition {
    byte_offset: usize
    bit_offset: usize
}

# 字节视图：底层字节数组 + 偏移基址 + 长度。
# 容器格式里的"节/段/载荷"都是父源上的窗口，不复制字节；
# `base` 是视图相对父源的绝对偏移基址，`DataSpan` 单位=字节。
structure DataByteView {
    bytes: [u8]
    base: usize
    length: usize
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
