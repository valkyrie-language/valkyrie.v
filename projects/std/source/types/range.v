namespace std.types;

⍝ 整数区间与区间迭代：由端点组合而成的泛型区间模型。
⍝
⍝ 区间是「端点对 + 开闭语义」的领域概念，与端点的具体整数宽度无关：
⍝ - `Range<T>`：半开区间 [start, end)，产出 start 到 end 之前的每个端点值；
⍝ - `InclusiveRange<T>`：闭区间 [start, end]，组合 `Range<T>` 再加「末值额外
⍝   产出一次」的标记，开闭语义由类型表达，不由参数或字段猜测。
⍝ 步进单位是端点域的后继（`Step`），一步恰好一个端点值。
⍝
⍝ 迭代语义：
⍝ - 构造不排序、不钳制端点：`start > end` 是零次迭代的空区间，不是失败；
⍝ - 半开区间的判据是 `start < end`，不假设端点顺序；
⍝ - 闭区间只在半开部分耗尽后额外产出 `end` 一次，因此 `end` 取端点域最大值
⍝   也不溢出，不需要 `current <= end` 这类会死循环的判据。

⍝ 离散步进：端点域的后继函数，单位为一个端点值。
⍝ 区间迭代只要求端点「可后继、可三态比较」，不要求端点参与算术。
trait Step {
    micro successor(self): Self
}

imply u64: Step {
    micro successor(self): Self {
        return self + (1 as u64)
    }
}

imply u32: Step {
    micro successor(self): Self {
        return self + (1 as u32)
    }
}

imply i32: Step {
    micro successor(self): Self {
        return self + (1 as i32)
    }
}

imply i64: Step {
    micro successor(self): Self {
        return self + (1 as i64)
    }
}

structure Range<T> {
    start: T,
    end: T,
}

structure InclusiveRange<T> {
    _range: Range<T>,
    _has_last: bool,
}

⍝ 构造入口：端点不排序、不取整，只做值搬运；闭区间的 `_has_last` 是
⍝ `start <= end` 的自避免写法 `!(end < start)`。

micro range<T>(start: T, end: T) -> Range<T> {
    return Range { start: start, end: end }
}

micro inclusive_range<T>(start: T, end: T) -> InclusiveRange<T>
    where T: std::operator::Comparable
{
    return InclusiveRange {
        _range: Range { start: start, end: end },
        _has_last: !(end < start),
    }
}

imply Range<T>: std::iterator::Iterator {
    type Item = T;

    micro next(mut self): Option<T>
        where T: Step & std::operator::Comparable
    {
        if !(self.start < self.end) {
            return None
        }

        let current: T = self.start
        self.start = current.successor()
        return Some(current)
    }
}

imply Range<T>: std::iterator::IntoIterator {
    type Item = T;
    type Iter = Range<T>;

    micro into_iterator(self): Range<T> {
        return self
    }
}

imply InclusiveRange<T>: std::iterator::Iterator {
    type Item = T;

    # 半开部分逐项产出；耗尽后 `end` 额外产出一次，随后如实结束。
    micro next(mut self): Option<T>
        where T: Step & std::operator::Comparable
    {
        let inner: Option<T> = self._range.next()
        if inner.is_some() {
            return inner
        }

        if !self._has_last {
            return None
        }

        self._has_last = false
        return Some(self._range.end)
    }
}

imply InclusiveRange<T>: std::iterator::IntoIterator {
    type Item = T;
    type Iter = InclusiveRange<T>;

    micro into_iterator(self): InclusiveRange<T> {
        return self
    }
}
