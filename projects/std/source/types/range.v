namespace std.types;

⍝ 整数区间与区间迭代。
⍝
⍝ 类型形态按端点原语宽度落地，不用泛型实例化：每种宽度一组具体类型，
⍝ `Item` 与端点类型严格一致，不做隐式加宽。
⍝
⍝ - `Range` / `InclusiveRange`：`u64` 端点。64 位目标 `usize = u64`，即 `usize` 区间；
⍝ - `U32Range` / `U32InclusiveRange`：`u32` 端点。32 位目标 `usize = u32`；
⍝ - `I32Range` / `I32InclusiveRange`：`i32` 端点；
⍝ - `I64Range` / `I64InclusiveRange`：`i64` 端点。64 位目标 `isize = i64`，即 `isize` 区间。
⍝
⍝ 迭代语义：
⍝ - 半开区间判据是 `start < end`（`current < end` 的自避免形式），不假设端点顺序：
⍝   构造值不 panic，`start > end` 是零次迭代的空区间；
⍝ - 闭区间只在 `current < end` 时自增，`end` 本身额外产出一次，所以 `end = usize_max`
⍝   不溢出，也不用 `current <= end` 这类会死循环的判据；`start > end` 在构造时置
⍝   「不产出 end」，得到零次迭代的空区间；
⍝ - 闭区间是扁平字段，不内嵌半开区间结构体：跨模块 link 阶段会把内嵌字段的
⍝   布局实例算成不同身份，触发「布局合同冲突」。
⍝
⍝ `..=` 的表达式形态暂未开放（`2..=8` 仅 match 模式可用），声明侧已就位，
⍝ 右端闭区间当前经构造函数取得。

structure Range {
    start: u64,
    end: u64,
}

structure InclusiveRange {
    _start: u64,
    _end: u64,
    _has_last: bool,
}

structure U32Range {
    start: u32,
    end: u32,
}

structure U32InclusiveRange {
    _start: u32,
    _end: u32,
    _has_last: bool,
}

structure I32Range {
    start: i32,
    end: i32,
}

structure I32InclusiveRange {
    _start: i32,
    _end: i32,
    _has_last: bool,
}

structure I64Range {
    start: i64,
    end: i64,
}

structure I64InclusiveRange {
    _start: i64,
    _end: i64,
    _has_last: bool,
}

⍝ 构造入口：端点不排序、不取整，只做值搬运；闭区间的 `_has_last` 是 `start <= end`
⍝ 的自避免写法 `!(end < start)`。

micro range(start: u64, end: u64) -> Range {
    return Range { start: start, end: end }
}

micro inclusive_range(start: u64, end: u64) -> InclusiveRange {
    return InclusiveRange { _start: start, _end: end, _has_last: !(end < start) }
}

micro u32_range(start: u32, end: u32) -> U32Range {
    return U32Range { start: start, end: end }
}

micro u32_inclusive_range(start: u32, end: u32) -> U32InclusiveRange {
    return U32InclusiveRange { _start: start, _end: end, _has_last: !(end < start) }
}

micro i32_range(start: i32, end: i32) -> I32Range {
    return I32Range { start: start, end: end }
}

micro i32_inclusive_range(start: i32, end: i32) -> I32InclusiveRange {
    return I32InclusiveRange { _start: start, _end: end, _has_last: !(end < start) }
}

micro i64_range(start: i64, end: i64) -> I64Range {
    return I64Range { start: start, end: end }
}

micro i64_inclusive_range(start: i64, end: i64) -> I64InclusiveRange {
    return I64InclusiveRange { _start: start, _end: end, _has_last: !(end < start) }
}

imply Range: std::iterator::Iterator {
    type Item = u64;

    micro has_next(self): bool {
        return self.start < self.end
    }

    micro next(mut self): Option<u64> {
        if !self.has_next() {
            return None
        }

        let current: u64 = self.start
        self.start = current + 1
        return Some(current)
    }
}

imply Range: std::iterator::IntoIterator {
    type Item = u64;
    type Iter = Range;

    micro into_iterator(self): Range {
        return self
    }
}

imply InclusiveRange: std::iterator::Iterator {
    type Item = u64;

    micro has_next(self): bool {
        return self._start < self._end || self._has_last
    }

    micro next(mut self): Option<u64> {
        if self._start < self._end {
            let current: u64 = self._start
            self._start = current + 1
            return Some(current)
        }

        if !self._has_last {
            return None
        }

        self._has_last = false
        return Some(self._end)
    }
}

imply InclusiveRange: std::iterator::IntoIterator {
    type Item = u64;
    type Iter = InclusiveRange;

    micro into_iterator(self): InclusiveRange {
        return self
    }
}

imply U32Range: std::iterator::Iterator {
    type Item = u32;

    micro has_next(self): bool {
        return self.start < self.end
    }

    micro next(mut self): Option<u32> {
        if !self.has_next() {
            return None
        }

        let current: u32 = self.start
        self.start = current + (1 as u32)
        return Some(current)
    }
}

imply U32Range: std::iterator::IntoIterator {
    type Item = u32;
    type Iter = U32Range;

    micro into_iterator(self): U32Range {
        return self
    }
}

imply U32InclusiveRange: std::iterator::Iterator {
    type Item = u32;

    micro has_next(self): bool {
        return self._start < self._end || self._has_last
    }

    micro next(mut self): Option<u32> {
        if self._start < self._end {
            let current: u32 = self._start
            self._start = current + (1 as u32)
            return Some(current)
        }

        if !self._has_last {
            return None
        }

        self._has_last = false
        return Some(self._end)
    }
}

imply U32InclusiveRange: std::iterator::IntoIterator {
    type Item = u32;
    type Iter = U32InclusiveRange;

    micro into_iterator(self): U32InclusiveRange {
        return self
    }
}

imply I32Range: std::iterator::Iterator {
    type Item = i32;

    micro has_next(self): bool {
        return self.start < self.end
    }

    micro next(mut self): Option<i32> {
        if !self.has_next() {
            return None
        }

        let current: i32 = self.start
        self.start = current + (1 as i32)
        return Some(current)
    }
}

imply I32Range: std::iterator::IntoIterator {
    type Item = i32;
    type Iter = I32Range;

    micro into_iterator(self): I32Range {
        return self
    }
}

imply I32InclusiveRange: std::iterator::Iterator {
    type Item = i32;

    micro has_next(self): bool {
        return self._start < self._end || self._has_last
    }

    micro next(mut self): Option<i32> {
        if self._start < self._end {
            let current: i32 = self._start
            self._start = current + (1 as i32)
            return Some(current)
        }

        if !self._has_last {
            return None
        }

        self._has_last = false
        return Some(self._end)
    }
}

imply I32InclusiveRange: std::iterator::IntoIterator {
    type Item = i32;
    type Iter = I32InclusiveRange;

    micro into_iterator(self): I32InclusiveRange {
        return self
    }
}

imply I64Range: std::iterator::Iterator {
    type Item = i64;

    micro has_next(self): bool {
        return self.start < self.end
    }

    micro next(mut self): Option<i64> {
        if !self.has_next() {
            return None
        }

        let current: i64 = self.start
        self.start = current + (1 as i64)
        return Some(current)
    }
}

imply I64Range: std::iterator::IntoIterator {
    type Item = i64;
    type Iter = I64Range;

    micro into_iterator(self): I64Range {
        return self
    }
}

imply I64InclusiveRange: std::iterator::Iterator {
    type Item = i64;

    micro has_next(self): bool {
        return self._start < self._end || self._has_last
    }

    micro next(mut self): Option<i64> {
        if self._start < self._end {
            let current: i64 = self._start
            self._start = current + (1 as i64)
            return Some(current)
        }

        if !self._has_last {
            return None
        }

        self._has_last = false
        return Some(self._end)
    }
}

imply I64InclusiveRange: std::iterator::IntoIterator {
    type Item = i64;
    type Iter = I64InclusiveRange;

    micro into_iterator(self): I64InclusiveRange {
        return self
    }
}
