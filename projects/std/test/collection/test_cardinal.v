namespace std.collection.test;

structure CardinalProbe {
    value: i32
}

[test]
micro `test array cardinal read`() {
    let values: [i32] = [10, 20, 30]

    # `⁅ ⁆` 自动取值：返回裸元素，不需要 unwrap。
    if values⁅0⁆ != 10 {
        panic("array cardinal first element failed")
    }

    if values⁅1⁆ != 20 {
        panic("array cardinal middle element failed")
    }

    if values⁅2⁆ != 30 {
        panic("array cardinal last element failed")
    }
}

[test]
micro `test array cardinal write and readback`() {
    let mut values: [i32] = [1, 2, 3]

    # 左值形态：直接对 `⁅ ⁆` 位置赋值，无 unwrap、无中间变量。
    values⁅0⁆ = 100
    values⁅2⁆ = 300

    if values⁅0⁆ != 100 {
        panic("array cardinal write first readback failed")
    }

    if values⁅1⁆ != 2 {
        panic("array cardinal untouched element failed")
    }

    if values⁅2⁆ != 300 {
        panic("array cardinal write last readback failed")
    }

    if values.length() != 3 {
        panic("array length after cardinal writes failed")
    }
}

[test]
micro `test array cardinal named methods`() {
    let mut values: [i32] = [7, 8, 9]

    # `get_cardinal` / `set_cardinal` 与 `⁅ ⁆` / `⁅ ⁆=` 同源。
    if values.get_cardinal(0) != 7 {
        panic("array get_cardinal read failed")
    }

    values.set_cardinal(1, 80)
    if values⁅1⁆ != 80 {
        panic("array set_cardinal write readback failed")
    }

    values⁅2⁆ = 90
    if values.get_cardinal(2) != 90 {
        panic("array get_cardinal after subscript write failed")
    }
}

[test]
micro `test array cardinal compound lvalue`() {
    let mut probes: [CardinalProbe] = [CardinalProbe { value: 1 }, CardinalProbe { value: 2 }]

    # 复合左值：`a⁅i⁆.field = v`，不经过中间变量。
    probes⁅0⁆.value = 42

    if probes⁅0⁆.value != 42 {
        panic("array cardinal compound lvalue failed")
    }

    if probes⁅1⁆.value != 2 {
        panic("array cardinal compound lvalue untouched failed")
    }
}

[test]
micro `test array list cardinal read and write`() {
    let list: ArrayList<i32> = ArrayList::new(0)
    list.push(10)
    list.push(20)
    list.push(30)

    if list⁅0⁆ != 10 {
        panic("array list cardinal first failed")
    }

    if list⁅2⁆ != 30 {
        panic("array list cardinal last failed")
    }

    list⁅1⁆ = 99
    if list⁅1⁆ != 99 {
        panic("array list cardinal write readback failed")
    }

    if list.get_cardinal(1) != 99 {
        panic("array list get_cardinal readback failed")
    }

    list.set_cardinal(0, 11)
    if list⁅0⁆ != 11 {
        panic("array list set_cardinal write failed")
    }

    if list.length() != 3 {
        panic("array list length after cardinal writes failed")
    }
}
