namespace std.collection;

# std.collection: BinaryHeap - 堆，序方向由实例决定
#
# `new()` 是小顶堆（元素自然序的最小值先出堆），`max()` 是大顶堆（自然序的
# 最大值先出堆），`new_by(cmp)` 按调用方比较器建堆（`Less` 表示前者先出堆）。
# 三者共用同一套上浮/下沉实现；`_cmp` 是唯一序判定来源，方向翻转只发生在
# `comes_first` 这一处。`new()` / `max()` 需要 `T: Comparable`，`new_by` 不需要。

class BinaryHeap<T> {
    data: ArrayList<T>
    _cmp: micro(T, T) -> std::operator::Ordering
    _descending: bool
}

imply BinaryHeap<T> {
    micro new(): Self
        where T: std::operator::Comparable
    {
        return Self {
            data: ArrayList::new(0),
            _cmp: micro(a: T, b: T) -> std::operator::Ordering {
                return std::collection::natural_order(a, b)
            },
            _descending: false,
        }
    }

    # 大顶堆：与 `new()` 共用存储与上浮/下沉，只把比较方向翻转。
    micro max(): Self
        where T: std::operator::Comparable
    {
        return Self {
            data: ArrayList::new(0),
            _cmp: micro(a: T, b: T) -> std::operator::Ordering {
                return std::collection::natural_order(a, b)
            },
            _descending: true,
        }
    }

    # 比较器堆：比较器语义与 `sort` 一致（三态序）。
    # 不要求 `T: Comparable`，因此 `f64` 等非全序元素也能建堆。
    micro new_by(cmp: micro(T, T) -> std::operator::Ordering): Self {
        return Self {
            data: ArrayList::new(0),
            _cmp: cmp,
            _descending: false,
        }
    }

    micro push(mut self, value: T): unit {
        self.data.push(value)
        self.sift_up(self.data.length() - 1)
    }

    micro pop(mut self): Option<T> {
        if self.data.is_empty() {
            return None
        }

        let length: usize = self.data.length()
        if length == 1 {
            return self.data.remove(1)
        }

        let result: T = self.data.get(1).unwrap()
        let last: T = self.data.remove(length).unwrap()
        self.data.set(1, last)
        self.sift_down(0)
        return Some(result)
    }

    micro peek(self): Option<T> {
        return self.data.first()
    }

    micro length(self): usize {
        return self.data.length()
    }

    micro is_empty(self): bool {
        return self.data.is_empty()
    }

    micro clear(mut self): unit {
        self.data.clear()
    }

    # 堆内唯一的序判定入口：`_cmp` 给出三态序，大顶堆在此翻转；
    # `Unordered` 消费到即结构化失败，不做静默降级。
    private micro comes_first(self, left: T, right: T): bool {
        match self._cmp(left, right) {
            case Less:
                !self._descending
            case Equal:
                false
            case Greater:
                self._descending
            case Unordered:
                std::types::panic("BinaryHeap: 比较消费到 Unordered")
        }
    }

    micro sift_up(mut self, index: usize): unit {
        let mut cursor: usize = index
        while cursor > 0 {
            let parent: usize = (cursor - 1) / 2
            let current: T = self.data.get((cursor + 1) as isize).unwrap()
            let parent_value: T = self.data.get((parent + 1) as isize).unwrap()
            if !self.comes_first(current, parent_value) {
                break
            }

            self.data.set((cursor + 1) as isize, parent_value)
            self.data.set((parent + 1) as isize, current)
            cursor = parent
        }
    }

    micro sift_down(mut self, index: usize): unit {
        let length: usize = self.data.length()
        let mut cursor: usize = index
        while true {
            let left: usize = 2 * cursor + 1
            let right: usize = 2 * cursor + 2
            let mut best: usize = cursor

            if left < length {
                let left_value: T = self.data.get((left + 1) as isize).unwrap()
                let best_value: T = self.data.get((best + 1) as isize).unwrap()
                if self.comes_first(left_value, best_value) {
                    best = left
                }
            }

            if right < length {
                let right_value: T = self.data.get((right + 1) as isize).unwrap()
                let best_value: T = self.data.get((best + 1) as isize).unwrap()
                if self.comes_first(right_value, best_value) {
                    best = right
                }
            }

            if best == cursor {
                break
            }

            let current: T = self.data.get((cursor + 1) as isize).unwrap()
            self.data.set((cursor + 1) as isize, self.data.get((best + 1) as isize).unwrap())
            self.data.set((best + 1) as isize, current)
            cursor = best
        }
    }
}
