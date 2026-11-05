namespace std.collection.test;

using std.collection::BitSet;

[test]
micro `test bitset clone independent`() {
    let mut bits: BitSet = BitSet::new()
    bits.set(1)

    let copy: BitSet = bits.clone()
    copy.set(3)

    if bits.get(3) {
        panic("BitSet.clone 副本写回原图测试失败")
    }

    if !copy.get(3) {
        panic("BitSet.clone 副本置位测试失败")
    }

    if bits.count() != 1 || copy.count() != 2 {
        panic("BitSet.clone 计数独立性测试失败")
    }
}

[test]
micro `test bitset length is alloc width`() {
    let empty_bits: BitSet = BitSet::new()
    if empty_bits.length() != 0 {
        panic("空 BitSet.length 应为 0")
    }

    let mut bits: BitSet = BitSet::with_capacity(100)
    if bits.length() != 128 {
        panic("BitSet.length 应按 64 位字向上取整")
    }

    bits.set(99)
    if bits.bit_length() != 100 {
        panic("BitSet.bit_length 与置位测试失败")
    }

    if bits.length() != 128 {
        panic("BitSet.length 不随置位变化测试失败")
    }
}

[test]
micro `test bitset iterator order`() {
    let mut bits: BitSet = BitSet::new()
    bits.set(1)
    bits.set(3)
    bits.set(5)
    bits.set(128)

    let mut iterator = bits.iter()

    if iterator.next().unwrap() != 1 {
        panic("BitSet 迭代第 1 个置位测试失败")
    }

    if iterator.next().unwrap() != 3 {
        panic("BitSet 迭代第 2 个置位测试失败")
    }

    if iterator.next().unwrap() != 5 {
        panic("BitSet 迭代第 3 个置位测试失败")
    }

    if iterator.next().unwrap() != 128 {
        panic("BitSet 迭代跨 word 置位测试失败")
    }

    if iterator.has_next() || iterator.next().is_some() {
        panic("BitSet 迭代耗尽后应为 None")
    }
}

[test]
micro `test bitset for in`() {
    let mut bits: BitSet = BitSet::new()
    bits.set(2)
    bits.set(4)

    let mut seen: ArrayList<usize> = ArrayList::new(0)
    loop bit in bits {
        seen.push(bit)
    }

    if seen.length() != 2 || seen⁅0⁆ != 2 || seen⁅1⁆ != 4 {
        panic("BitSet for-in 迭代测试失败")
    }
}

[test]
micro `test bitset iterator empty`() {
    let bits: BitSet = BitSet::new()
    let mut iterator = bits.iter()

    if iterator.has_next() {
        panic("空 BitSet 迭代器不应有下一个")
    }

    if iterator.next().is_some() {
        panic("空 BitSet 迭代器应返回 None")
    }
}
