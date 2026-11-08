namespace lang_shape_probe;

using std.collection::{ArrayList};

# 绑定面探针：只用面上声明的成员（new/push/length/capacity）。

[main]
micro main(): i32 {
    let mut list: ArrayList<u8> = ArrayList::new(0)
    list.push(104 as u8)
    list.push(105 as u8)
    if list.length() != 2 {
        return 12
    }
    if list.capacity() < 2 {
        return 13
    }
    return 0
}
