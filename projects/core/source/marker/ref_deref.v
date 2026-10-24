namespace marker;

# Class / reference payload identity: MIR inserts `__ref_deref` before FieldGet on `class`.
# 结构操作保留 `[intrinsic]`，但路径必须是 frontend `IntrinsicId::resolve_from_segments` 接受的形式。
[intrinsic("builtin.ref.deref")]
private micro __ref_deref<T>(self: T): T { }
