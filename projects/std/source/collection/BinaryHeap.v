namespace std.collection;

# std.collection: BinaryHeap - 堆，序方向由实例决定
#
# `new()` 是小顶堆（元素自然序的最小值先出堆），`max()` 是大顶堆（自然序的
# 最大值先出堆）。两者共用同一套上浮/下沉实现，`Comparable → i32` 只在
# `natural_order` 转换一次；方向翻转也只发生在 `comes_first` 这一处。

class BinaryHeap<T> {
    data: ArrayList<T>
    _descending: bool
}

imply BinaryHeap<T> {
    micro new(): Self {
        return Self {
            data: ArrayList::new(0),
            _descending: false,
        }
    }

    # 大顶堆：与 `new()` 共用存储与上浮/下沉，只把比较方向翻转。
    micro max(): Self
        where T: std::operator::Comparable
    {
        return Self {
            data: ArrayList::new(0),
            _descending: true,
        }
    }

    micro push(mut self, value: T): unit
        where T: std::operator::Comparable
    {
        self.data.push(value)
        self.sift_up(self.data.length() - 1)
    }

    micro pop(mut self): Option<T>
        where T: std::operator::Comparable
    {
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

    # 堆内唯一的序判定入口：`natural_order` 给出自然序，大顶堆在此翻转。
    private micro comes_first(self, left: T, right: T): bool
        where T: std::operator::Comparable
    {
        let order: i32 = natural_order(left, right)
        if self._descending {
            return order > 0
        }
        return order < 0
    }

    micro sift_up(mut self, index: usize): unit
        where T: std::operator::Comparable
    {
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

    micro sift_down(mut self, index: usize): unit
        where T: std::operator::Comparable
    {
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
