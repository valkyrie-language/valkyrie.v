namespace std.data.binary.wasm;

using std.data::{DataSpan};

# WASM 模块结构骨架（只声明，不实现）。
#
# 本节类型枚举与 section 头承载物挂在 `std.data.binary.wasm`（格式侧）：
# section id 的语义与 LEB128 都属于 wasm 格式知识，不进公共层，也不进 codec。
# LEB128 归格式侧的理由：它是 wasm 二进制格式的线格式编码（与 varuint/varint
# 语义绑定，含符号扩展规则），不是跨格式通用编解码；若后续出现第二种使用
# LEB128 的格式，再把公共部分上移到 codec。

# 模块 section 分类。id 0..12 为现行规范内。
#
# 未知 id 的恢复语义（错误容许）：不终止解析——按 section 头声明的载荷长度
# 跳过整个未知 section，继续解析后续 section；原 id 保留在 `Unknown` 承载物
# 中供诊断，跳过的字节区间在 CST 中挂 `Poison`（字节不丢），并登记
# `wasm.section.unknown_id`（Warning）诊断。不得静默跳过，也不得归入 Custom。
enums WasmSectionKind {
    Custom
    Type
    Import
    Function
    Table
    Memory
    Global
    Export
    Start
    Element
    Code
    Data
    DataCount
    Unknown
}

# section 头承载物：
# - `id`：原始 section id 字节（kind 由它映射；Unknown 保留原值供诊断）。
# - `span`：载荷字节区间（绝对偏移，单位=字节，`stop` 开区间）。
# - `header_span`：头部（id + size 字段）字节区间，CST 回写需要。
structure WasmSectionHeader {
    kind: WasmSectionKind
    id: u8
    span: DataSpan
    header_span: DataSpan
}
