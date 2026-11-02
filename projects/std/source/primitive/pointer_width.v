namespace std.primitive;

⍝ 指针宽度整数别名：`usize` / `isize` 不是 host 类型，也不是编译器内建；
⍝ 按目标架构的指针宽度在编译期展开为固定宽度别名。
⍝ - 32 位目标（x86 / arm / riscv32 / wasm32 / wasi）：`usize = u32`、`isize = i32`；
⍝ - 其余目标（x86_64 / aarch64 / riscv64 / wasm64 与托管 clr / jvm / ovm / native）：
⍝   `usize = u64`、`isize = i64`，与 canonical 层「本工具链 canonical 位宽为 64」一致。
⍝ 算术、比较、位运算、`as` 转换与 `Equal` / `Identical` / `Hash` 等 trait 覆盖
⍝ 全部继承目标别名类型的既有 impl 与 provider；本文件不引入任何 `__usize_*` / `__isize_*`
⍝ host 合同，编译器侧不需要 `std::primitive::usize` / `std::primitive::isize` 特判。
<% match arch %>
    <% case "x86" %>
type usize = u32;
type isize = i32;
    <% case "arm" %>
type usize = u32;
type isize = i32;
    <% case "riscv32" %>
type usize = u32;
type isize = i32;
    <% case "wasm32" %>
type usize = u32;
type isize = i32;
    <% case "wasi" %>
type usize = u32;
type isize = i32;
    <% else %>
type usize = u64;
type isize = i64;
<% end match %>
