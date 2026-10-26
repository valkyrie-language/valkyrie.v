namespace std.collection;

# 零大小的类型标记，用于让泛型形参参与名义类型身份而不占用运行时布局。
# `class Array<T>` 的 `_typing` 字段只是把 `T` 绑定到类型上，宿主负责实际的
# `_address` / `_length` 布局。
structure Phantom<T> {
}
