namespace lang_shape_probe;

using std.collection::{ArrayList, ArrayView};

# ArrayList<u8> 原地 push 探针（wasm 真跑）：
# 空容量起步 → push 两字节 → 逻辑长度/元素正确；容量经倍增真实增长；
# view 窗口读出与 to_array 冻结一致；语句形态调用（返回 unit，无写回）。

[main]
micro main(): i32 {
    let mut list: ArrayList<u8> = ArrayList::new(0)
    if list.capacity() != 0 {
        return 11
    }
    list.push(104 as u8)
    list.push(105 as u8)
    # 原地追加：逻辑长度 +2，容量经倍增 ≥ 4（空载体 4 起步）。
    if list.length() != 2 {
        return 12
    }
    if list.capacity() < 4 {
        return 13
    }
    if (list⁅0⁆ as u64) != 104 || (list⁅1⁆ as u64) != 105 {
        return 14
    }
    # 继续压到触发第二轮扩容（>4）。
    list.push(33 as u8)
    list.push(32 as u8)
    list.push(115 as u8)
    if list.length() != 5 {
        return 15
    }
    if list.capacity() < 5 {
        return 16
    }
    if (list⁅4⁆ as u64) != 115 {
        return 17
    }
    # 零拷贝视图：长度即逻辑长度，元素同源。
    let window: ArrayView<u8> = list.view()
    if window.length != 5 {
        return 18
    }
    if (window⁅0⁆ as u64) != 104 || (window⁅4⁆ as u64) != 115 {
        return 19
    }
    # 冻结：定长数组与逻辑内容一致。
    let frozen: [u8] = list.to_array()
    if frozen.length != 5 {
        return 20
    }
    if (frozen⁅2⁆ as u64) != 33 {
        return 21
    }
    # clear 保留载体、重置逻辑长度；复用容量继续 push 不再扩容。
    list.clear()
    if list.length() != 0 {
        return 22
    }
    if list.capacity() < 5 {
        return 23
    }
    list.push(97 as u8)
    if list.length() != 1 || (list⁅0⁆ as u64) != 97 {
        return 24
    }
    return 0
}
