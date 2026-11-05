namespace std.collection.test;

using std.collection::BinaryHeap;

# `new_by(cmp)` 不要求 `T: Comparable`：用 `f64`（无全序实现）验证比较器路径。

[test]
micro `test heap new by comparator f64`() {
    let heap: BinaryHeap<f64> = BinaryHeap::new_by(micro(a: f64, b: f64) -> i32 {
        if a > b {
            return -1
        }

        if a < b {
            return 1
        }

        return 0
    })

    heap.push(1.5)
    heap.push(3.25)
    heap.push(2.0)

    if heap.length() != 3 {
        panic("new_by length test failed")
    }

    if heap.peek().unwrap() != 3.25 {
        panic("new_by peek test failed")
    }

    if heap.pop().unwrap() != 3.25 {
        panic("new_by first pop test failed")
    }

    if heap.pop().unwrap() != 2.0 {
        panic("new_by second pop test failed")
    }

    if heap.pop().unwrap() != 1.5 {
        panic("new_by third pop test failed")
    }
}

# 自然序入口仍保持原语义：`new()` 小顶堆、`max()` 大顶堆。
[test]
micro `test heap natural and max entries`() {
    let min_heap: BinaryHeap<i32> = BinaryHeap::new()
    min_heap.push(4)
    min_heap.push(1)
    min_heap.push(3)

    if min_heap.pop().unwrap() != 1 {
        panic("new min-heap pop test failed")
    }

    let max_heap: BinaryHeap<i32> = BinaryHeap::max()
    max_heap.push(4)
    max_heap.push(1)
    max_heap.push(3)

    if max_heap.pop().unwrap() != 4 {
        panic("max max-heap pop test failed")
    }
}

# 反例：空堆 `pop` / `peek` 返回 `None`，不伪造元素。
[test]
micro `test heap empty recoverable`() {
    let heap: BinaryHeap<i32> = BinaryHeap::new()

    if heap.pop().is_some() {
        panic("empty heap pop test failed")
    }

    if heap.peek().is_some() {
        panic("empty heap peek test failed")
    }
}
