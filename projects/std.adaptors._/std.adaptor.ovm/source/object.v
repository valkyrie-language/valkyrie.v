# std.adaptor.ovm: 对象与闭包操作 [ovm] 宿主绑定
# 将 valkyrie-core 的对象操作映射为 OVM opcode

#region 对象字段

[ovm("obj_len")]
micro object_length(obj: i32): i32

[ovm("obj_get_field")]
micro object_get_field(obj: i32, index: i32): i32

[ovm("obj_set_field")]
micro object_set_field(obj: i32, index: i32, value: i32): i32

#endregion

#region 对象索引

[ovm("obj_get_index")]
micro object_get_index(obj: i32, index: i32): i32

[ovm("obj_set_index")]
micro object_set_index(obj: i32, index: i32, value: i32): i32

#endregion

#region 闭包 upvalue

[ovm("closure_get_upvalue")]
micro closure_get_upvalue(closure: i32, index: i32): i32

[ovm("closure_set_upvalue")]
micro closure_set_upvalue(closure: i32, index: i32, value: i32): i32

#endregion